import 'dart:convert';

import 'agent_query.dart';

class AgentDocsMcpServer {
  AgentDocsMcpServer(this.engine);

  final AgentQueryEngine engine;

  Map<String, Object?>? handle(Map<String, Object?> request) {
    final method = request['method'];
    if (method is! String) {
      return _error(request['id'], -32600, 'Request method is required.');
    }
    if (method.startsWith('notifications/')) return null;

    switch (method) {
      case 'initialize':
        return _result(request['id'], <String, Object?>{
          'protocolVersion': '2024-11-05',
          'capabilities': <String, Object?>{'tools': <String, Object?>{}},
          'serverInfo': <String, Object?>{
            'name': 'blab-design-system-agent-docs',
            'version': '0.1.0',
          },
          'instructions':
              'Read-only adapter over the repository-owned BLDS query contract.',
        });
      case 'tools/list':
        return _result(request['id'], <String, Object?>{
          'tools': <Object?>[
            <String, Object?>{
              'name': 'list_components',
              'description':
                  'List BLDS components from the generated registry. Read-only.',
              'inputSchema': <String, Object?>{
                'type': 'object',
                'properties': <String, Object?>{},
                'additionalProperties': false,
              },
            },
            <String, Object?>{
              'name': 'list_tokens',
              'description':
                  'List normalized tokens and compatibility-preserved CSS/Dart token mappings. Read-only.',
              'inputSchema': <String, Object?>{
                'type': 'object',
                'properties': <String, Object?>{},
                'additionalProperties': false,
              },
            },
            <String, Object?>{
              'name': 'query_design_system',
              'description':
                  'Query a BLDS component, normalized token, compatibility-preserved token mapping, state, accessibility rule, example, or platform contract. Read-only.',
              'inputSchema': <String, Object?>{
                'type': 'object',
                'properties': <String, Object?>{
                  'kind': <String, Object?>{
                    'type': 'string',
                    'enum': <String>[
                      'component',
                      'token',
                      'state',
                      'accessibility',
                      'example',
                      'platform',
                    ],
                  },
                  'id': <String, Object?>{'type': 'string'},
                },
                'required': <String>['kind', 'id'],
                'additionalProperties': false,
              },
            },
          ],
        });
      case 'tools/call':
        return _call(request);
      default:
        return _error(request['id'], -32601, 'Method not found: $method.');
    }
  }

  Map<String, Object?> _call(Map<String, Object?> request) {
    final params = request['params'];
    final name = params is Map ? params['name'] : null;
    final arguments = params is Map && params['arguments'] is Map
        ? _stringMap(params['arguments'] as Map)
        : <String, Object?>{};
    try {
      late final Map<String, Object?> result;
      switch (name) {
        case 'list_components':
          result = <String, Object?>{
            'kind': 'components',
            'components': engine.registry['components'],
            'source': 'generated/agent-registry.v1.json',
          };
        case 'list_tokens':
          result = <String, Object?>{
            'kind': 'tokens',
            'tokens': engine.listTokens(),
            'source': 'contracts/tokens/blab.tokens.yaml',
            'read_only': true,
          };
        case 'query_design_system':
          final kind = arguments['kind'];
          final id = arguments['id'];
          if (kind is! String || id is! String) {
            throw const AgentQueryError(
              'invalid-arguments',
              'query_design_system requires string arguments: kind and id.',
            );
          }
          result = engine.query(kind: kind, id: id);
        default:
          throw AgentQueryError(
            'unknown-tool',
            'Tool not found: ${name ?? '<missing>'}.',
          );
      }
      return _result(request['id'], <String, Object?>{
        'content': <Object?>[
          <String, Object?>{
            'type': 'text',
            'text': const JsonEncoder.withIndent('  ').convert(result),
          },
        ],
        'structuredContent': result,
        'isError': false,
      });
    } on AgentQueryError catch (error) {
      return _toolError(request['id'], error.code, error.message);
    } on Object catch (error) {
      return _toolError(request['id'], 'internal-error', error.toString());
    }
  }

  Map<String, Object?> _toolError(Object? id, String code, String message) {
    final error = <String, Object?>{
      'schema': 'blab.agent-query-error/v1',
      'code': code,
      'message': message,
      'read_only': true,
    };
    return _result(id, <String, Object?>{
      'content': <Object?>[
        <String, Object?>{
          'type': 'text',
          'text': const JsonEncoder.withIndent('  ').convert(error),
        },
      ],
      'structuredContent': error,
      'isError': true,
    });
  }

  Map<String, Object?> _result(Object? id, Map<String, Object?> result) =>
      <String, Object?>{'jsonrpc': '2.0', 'id': id, 'result': result};

  Map<String, Object?> _error(Object? id, int code, String message) =>
      <String, Object?>{
        'jsonrpc': '2.0',
        'id': id,
        'error': <String, Object?>{'code': code, 'message': message},
      };
}

Map<String, Object?> _stringMap(Map value) => <String, Object?>{
  for (final entry in value.entries) entry.key.toString(): entry.value,
};
