import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'agent_consumption.dart';

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
      );

  final Directory root;
  final Map<String, Object?> registry;
  final YamlMap tokenDocument;
  final YamlMap designDocument;
  final YamlMap platformDocument;

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
              return <String, Object?>{
                'kind': 'token',
                'token': _jsonValue(raw),
                'source': agentTokenPath,
              };
            }
          }
        }
      }
    }
    throw AgentQueryError('not-found', 'Token not found: $id.');
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
