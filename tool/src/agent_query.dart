import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'agent_consumption.dart';
import 'contract_validation.dart';

const _queryModes = <String>[
  'light',
  'dark',
  'high-contrast-light',
  'high-contrast-dark',
];

class AgentQueryError implements Exception {
  const AgentQueryError(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

class AgentQueryEngine {
  AgentQueryEngine(this.root)
    : registry = _loadJson(
        File('${root.path}/generated/agent-registry.v1.json'),
      ),
      tokenDocument = loadYamlMap(File('${root.path}/$agentTokenPath')),
      designDocument = loadYamlMap(
        File('${root.path}/contracts/blab.design.yaml'),
      ),
      platformDocument = loadYamlMap(
        File('${root.path}/contracts/platform-support.yaml'),
      ),
      tokenModel = _loadTokenModel(root);

  final Directory root;
  final Map<String, Object?> registry;
  final YamlMap tokenDocument;
  final YamlMap designDocument;
  final YamlMap platformDocument;
  final BlabTokenModel tokenModel;

  List<Map<String, Object?>> listTokens() {
    final summaries = <Map<String, Object?>>[];
    final layers = tokenDocument['tokens'];
    if (layers is YamlMap) {
      for (final layer in <String>['primitives', 'semantics', 'components']) {
        final values = layers[layer];
        if (values is YamlList) {
          for (final raw in values.whereType<YamlMap>()) {
            summaries.add(_typedTokenSummary(raw, layer));
          }
        }
      }
    }

    final mappings = tokenDocument['legacy_mappings'];
    if (mappings is YamlMap) {
      final css = mappings['css'];
      if (css is YamlMap && css['entries'] is YamlList) {
        for (final raw in (css['entries'] as YamlList).whereType<YamlMap>()) {
          summaries.add(
            _compatibilityTokenSummary(
              raw,
              layer: 'legacy-css',
              compatibilitySource: css['source'] as String?,
              id: raw['name'] as String,
            ),
          );
        }
      }

      final dart = mappings['dart'];
      if (dart is YamlMap && dart['sources'] is YamlList) {
        for (final source
            in (dart['sources'] as YamlList).whereType<YamlMap>()) {
          final symbols = source['symbols'];
          if (symbols is! YamlList) continue;
          for (final raw in symbols.whereType<YamlMap>()) {
            summaries.add(
              _compatibilityTokenSummary(
                raw,
                layer: 'legacy-dart',
                compatibilitySource: source['path'] as String?,
                id: raw['symbol'] as String,
              ),
            );
          }
        }
      }
    }

    summaries.sort((left, right) {
      final layer = (left['layer'] as String).compareTo(
        right['layer'] as String,
      );
      return layer == 0
          ? (left['id'] as String).compareTo(right['id'] as String)
          : layer;
    });
    return summaries;
  }

  Map<String, Object?> query({required String kind, required String id}) {
    switch (kind) {
      case 'component':
        return _component(id);
      case 'token':
        return _token(id);
      case 'state':
        return _state(id);
      case 'accessibility':
        return _accessibility();
      case 'example':
        return _example(id);
      case 'platform':
        return _platform(id);
      default:
        throw AgentQueryError(
          'invalid-kind',
          'Supported kinds: component, token, state, accessibility, example, platform.',
        );
    }
  }

  Map<String, Object?> _component(String id) {
    final component = _findComponent(id);
    return <String, Object?>{
      'kind': 'component',
      'component': component,
      'evidence': _componentEvidence(component),
    };
  }

  Map<String, Object?> _state(String id) {
    final component = _findComponent(id);
    return <String, Object?>{
      'kind': 'state',
      'component_id': component['id'],
      'public_type': component['public_type'],
      'states': component['states'],
      'evidence': _componentEvidence(component),
    };
  }

  Map<String, Object?> _token(String id) {
    final layers = tokenDocument['tokens'];
    if (layers is YamlMap) {
      for (final layer in <String>['primitives', 'semantics', 'components']) {
        final values = layers[layer];
        if (values is YamlList) {
          for (final raw in values.whereType<YamlMap>()) {
            if (raw['id'] == id) {
              return _typedTokenResult(raw, layer);
            }
          }
        }
      }
    }

    final legacy = _legacyTokenResult(id);
    if (legacy != null) return legacy;
    throw AgentQueryError('not-found', 'Token not found: $id.');
  }

  Map<String, Object?> _typedTokenResult(YamlMap raw, String layer) {
    final tokenId = raw['id'] as String;
    return <String, Object?>{
      'kind': 'token',
      'token': _jsonValue(raw),
      'layer': layer,
      'status': 'normalized',
      'resolved_modes': <String, String>{
        for (final mode in _queryModes) mode: tokenModel.resolve(tokenId, mode),
      },
      'source': agentTokenPath,
      'evidence': <String>[
        agentTokenPath,
        'contracts/blab.design.yaml',
        'generated/token-traceability.md',
      ],
    };
  }

  Map<String, Object?> _typedTokenSummary(YamlMap raw, String layer) =>
      <String, Object?>{
        'id': raw['id'],
        'layer': layer,
        'type': raw['type'],
        'status': 'normalized',
        'source': agentTokenPath,
      };

  Map<String, Object?>? _legacyTokenResult(String id) {
    final mappings = tokenDocument['legacy_mappings'];
    if (mappings is! YamlMap) return null;

    final css = mappings['css'];
    if (css is YamlMap && css['entries'] is YamlList) {
      for (final raw in (css['entries'] as YamlList).whereType<YamlMap>()) {
        if (raw['name'] == id) {
          return _compatibilityTokenResult(
            raw,
            layer: 'legacy-css',
            compatibilitySource: css['source'] as String?,
          );
        }
      }
    }

    final dart = mappings['dart'];
    if (dart is YamlMap && dart['sources'] is YamlList) {
      for (final source in (dart['sources'] as YamlList).whereType<YamlMap>()) {
        final symbols = source['symbols'];
        if (symbols is! YamlList) continue;
        for (final raw in symbols.whereType<YamlMap>()) {
          if (raw['symbol'] == id) {
            return _compatibilityTokenResult(
              raw,
              layer: 'legacy-dart',
              compatibilitySource: source['path'] as String?,
            );
          }
        }
      }
    }
    return null;
  }

  Map<String, Object?> _compatibilityTokenResult(
    YamlMap raw, {
    required String layer,
    required String? compatibilitySource,
  }) {
    final mappedToken = raw['token'];
    final mappedTokenId =
        mappedToken is String &&
            mappedToken.isNotEmpty &&
            tokenModel.nodes.containsKey(mappedToken)
        ? mappedToken
        : null;
    final result = <String, Object?>{
      'kind': 'token',
      'token': _jsonValue(raw),
      'layer': layer,
      'status': mappedTokenId != null
          ? 'compatibility-mapped'
          : 'compatibility-preserved',
      'claim_boundary': mappedTokenId != null
          ? 'Legacy value is mapped to the typed graph; the legacy source remains compatibility-locked.'
          : 'Legacy value is preserved for compatibility and is not a normalized semantic token.',
      'source': agentTokenPath,
      'compatibility_source': compatibilitySource,
      'evidence': <String>[agentTokenPath, ?compatibilitySource],
    };
    if (mappedTokenId != null) {
      result['resolved_modes'] = <String, String>{
        for (final mode in _queryModes)
          mode: tokenModel.resolve(mappedTokenId, mode),
      };
    }
    return result;
  }

  Map<String, Object?> _compatibilityTokenSummary(
    YamlMap raw, {
    required String layer,
    required String? compatibilitySource,
    required String id,
  }) {
    final mappedToken = raw['token'];
    final mapped =
        mappedToken is String &&
        mappedToken.isNotEmpty &&
        tokenModel.nodes.containsKey(mappedToken);
    return <String, Object?>{
      'id': id,
      'layer': layer,
      'type': raw['type'],
      'status': mapped ? 'compatibility-mapped' : 'compatibility-preserved',
      'classification': raw['classification'],
      'deprecation': raw['deprecation'],
      if (mapped) 'mapped_token': mappedToken,
      'source': agentTokenPath,
      'compatibility_source': compatibilitySource,
    };
  }

  Map<String, Object?> _accessibility() => <String, Object?>{
    'kind': 'accessibility',
    'source': 'contracts/blab.design.yaml',
    'rules': _jsonValue(designDocument['accessibility']),
  };

  Map<String, Object?> _example(String id) {
    final component = _findComponent(id);
    final path = component['example'] as String;
    final file = File('${root.path}/$path');
    if (!file.existsSync()) {
      throw AgentQueryError(
        'missing-evidence',
        'Example path is missing: $path.',
      );
    }
    final content = file.readAsStringSync();
    const limit = 4000;
    return <String, Object?>{
      'kind': 'example',
      'component_id': component['id'],
      'path': path,
      'content': content.length <= limit
          ? content
          : content.substring(0, limit),
      'truncated': content.length > limit,
    };
  }

  Map<String, Object?> _platform(String id) {
    final component = _findComponent(id);
    return <String, Object?>{
      'kind': 'platform',
      'component_id': component['id'],
      'constraints': component['platform_constraints'],
      'declared_platform_support': _jsonValue(platformDocument['platforms']),
      'source': 'contracts/platform-support.yaml',
    };
  }

  Map<String, Object?> _findComponent(String id) {
    final components = registry['components'];
    if (components is List) {
      for (final raw in components.whereType<Map>()) {
        if (raw['id'] == id || raw['public_type'] == id) {
          return raw.map((key, value) => MapEntry(key.toString(), value));
        }
      }
    }
    throw AgentQueryError('not-found', 'Component not found: $id.');
  }

  List<String> _componentEvidence(Map<String, Object?> component) => <String>[
    component['source'] as String,
    component['example'] as String,
    component['test'] as String,
    component['documentation'] as String,
    agentStateContractPath,
    agentStateEvidencePath,
  ];
}

Map<String, Object?> _loadJson(File file) {
  if (!file.existsSync()) {
    throw AgentQueryError(
      'missing-generated-output',
      '${file.path} is missing.',
    );
  }
  final value = jsonDecode(file.readAsStringSync());
  if (value is! Map) {
    throw const AgentQueryError(
      'invalid-generated-output',
      'Generated registry must be a JSON object.',
    );
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

Object? _jsonValue(Object? value) {
  if (value is YamlMap) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): _jsonValue(entry.value),
    };
  }
  if (value is YamlList) return value.map(_jsonValue).toList(growable: false);
  return value;
}

BlabTokenModel _loadTokenModel(Directory root) {
  final inspection = inspectBlabContract(root);
  if (inspection.errors.isNotEmpty || inspection.tokenModel == null) {
    throw AgentQueryError(
      'invalid-token-source',
      'The canonical token contract failed validation.',
    );
  }
  return inspection.tokenModel!;
}
