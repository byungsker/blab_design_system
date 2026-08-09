import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'src/agent_docs_mcp.dart';
import 'src/agent_query.dart';

void main() {
  final server = AgentDocsMcpServer(AgentQueryEngine(Directory.current));
  final initialize = server.handle(<String, Object?>{
    'jsonrpc': '2.0',
    'id': 1,
    'method': 'initialize',
  });
  _check(initialize?['result'] is Map, 'initialize returns a result');

  final tools = server.handle(<String, Object?>{
    'jsonrpc': '2.0',
    'id': 2,
    'method': 'tools/list',
  });
  final toolList = (tools?['result'] as Map?)?['tools'];
  _check(toolList is List && toolList.length == 2, 'tools/list is bounded');

  final query = server.handle(<String, Object?>{
    'jsonrpc': '2.0',
    'id': 3,
    'method': 'tools/call',
    'params': <String, Object?>{
      'name': 'query_design_system',
      'arguments': <String, Object?>{'kind': 'component', 'id': 'bottom-bar'},
    },
  });
  final queryResult = (query?['result'] as Map?)?['structuredContent'];
  _check(
    queryResult is Map && queryResult['component'] is Map,
    'query tool mirrors local contract',
  );

  final fixtureDocument =
      loadYaml(
            File('contracts/agent/evaluation-fixtures.yaml').readAsStringSync(),
          )
          as YamlMap;
  final fixtures = fixtureDocument['fixtures'] as YamlList;
  for (final fixture in fixtures.whereType<YamlMap>()) {
    final fixtureQuery = fixture['query'] as YamlMap;
    final kind = fixtureQuery['kind'] as String;
    final id = fixtureQuery['id'] as String;
    final local = server.engine.query(kind: kind, id: id);
    final adapted = server.handle(<String, Object?>{
      'jsonrpc': '2.0',
      'id': fixture['id'],
      'method': 'tools/call',
      'params': <String, Object?>{
        'name': 'query_design_system',
        'arguments': <String, Object?>{'kind': kind, 'id': id},
      },
    });
    final adaptedResult = ((adapted?['result'] as Map?)?['structuredContent']);
    _check(
      jsonEncode(adaptedResult) == jsonEncode(local),
      'MCP/local parity for ${fixture['id']}',
    );
  }

  final missing = server.handle(<String, Object?>{
    'jsonrpc': '2.0',
    'id': 4,
    'method': 'tools/call',
    'params': <String, Object?>{
      'name': 'query_design_system',
      'arguments': <String, Object?>{'kind': 'component', 'id': 'missing'},
    },
  });
  final missingResult = (missing?['result'] as Map?)?['structuredContent'];
  _check(
    missingResult is Map &&
        missingResult['code'] == 'not-found' &&
        (missing?['result'] as Map?)?['isError'] == true,
    'query tool returns bounded not-found errors',
  );

  _check(
    const JsonEncoder().convert(
          server.handle(<String, Object?>{
            'jsonrpc': '2.0',
            'id': 5,
            'method': 'notifications/initialized',
          }),
        ) ==
        'null',
    'notifications do not produce a response',
  );
  stdout.writeln('Agent Docs MCP tests passed.');
}

void _check(bool condition, String description) {
  if (!condition) {
    stderr.writeln('FAIL: $description');
    exitCode = 1;
    throw StateError(description);
  }
}
