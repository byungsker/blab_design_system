import 'dart:io';

import 'package:yaml/yaml.dart';

const agentRegistryPath = 'contracts/components/agent-registry.yaml';
const agentStateContractPath = 'contracts/components/state-applicability.yaml';
const agentStateEvidencePath = 'generated/component-state-coverage.yaml';
const agentTokenPath = 'contracts/tokens/blab.tokens.yaml';

class AgentComponent {
  const AgentComponent({
    required this.id,
    required this.publicType,
    required this.purpose,
    required this.usageBoundary,
    required this.source,
    required this.example,
    required this.test,
    required this.documentation,
    required this.tokenReferences,
    required this.platformConstraints,
    required this.stateContractId,
  });

  final String id;
  final String publicType;
  final String purpose;
  final String usageBoundary;
  final String source;
  final String example;
  final String test;
  final String documentation;
  final List<String> tokenReferences;
  final List<String> platformConstraints;
  final String stateContractId;
}

class AgentRegistry {
  const AgentRegistry({required this.version, required this.components});

  final String version;
  final List<AgentComponent> components;
}

YamlMap loadYamlMap(File file) {
  final value = loadYaml(file.readAsStringSync());
  if (value is! YamlMap) {
    throw FormatException('${file.path} must contain a YAML mapping.');
  }
  return value;
}

AgentRegistry loadAgentRegistry(Directory repositoryRoot) {
  final document = loadYamlMap(
    File('${repositoryRoot.path}/$agentRegistryPath'),
  );
  if (document['schema'] != 'blab.agent-component-registry/v1') {
    throw const FormatException(
      'Agent registry schema must be blab.agent-component-registry/v1.',
    );
  }
  final metadata = _map(document['metadata'], 'metadata');
  final version = _string(metadata['version'], 'metadata.version');
  final rawComponents = document['components'];
  if (rawComponents is! YamlList || rawComponents.isEmpty) {
    throw const FormatException('Agent registry components must be non-empty.');
  }
  final components = <AgentComponent>[];
  for (var index = 0; index < rawComponents.length; index++) {
    final raw = _map(rawComponents[index], 'components[$index]');
    components.add(
      AgentComponent(
        id: _string(raw['id'], 'components[$index].id'),
        publicType: _string(
          raw['public_type'],
          'components[$index].public_type',
        ),
        purpose: _string(raw['purpose'], 'components[$index].purpose'),
        usageBoundary: _string(
          raw['usage_boundary'],
          'components[$index].usage_boundary',
        ),
        source: _string(raw['source'], 'components[$index].source'),
        example: _string(raw['example'], 'components[$index].example'),
        test: _string(raw['test'], 'components[$index].test'),
        documentation: _string(
          raw['documentation'],
          'components[$index].documentation',
        ),
        tokenReferences: _strings(
          raw['token_references'],
          'components[$index].token_references',
        ),
        platformConstraints: _strings(
          raw['platform_constraints'],
          'components[$index].platform_constraints',
        ),
        stateContractId: _string(
          raw['state_contract_id'],
          'components[$index].state_contract_id',
        ),
      ),
    );
  }
  return AgentRegistry(version: version, components: components);
}

List<String> validateAgentRegistry(Directory repositoryRoot) {
  final errors = <String>[];
  final root = repositoryRoot.path;
  final registryFile = File('$root/$agentRegistryPath');
  if (!registryFile.existsSync()) {
    return <String>['Missing $agentRegistryPath.'];
  }
  final stateContract = File('$root/$agentStateContractPath');
  final stateEvidence = File('$root/$agentStateEvidencePath');
  final tokenFile = File('$root/$agentTokenPath');
  for (final file in <File>[stateContract, stateEvidence, tokenFile]) {
    if (!file.existsSync()) {
      errors.add('Missing ${file.path.substring(root.length + 1)}.');
    }
  }

  AgentRegistry registry;
  try {
    registry = loadAgentRegistry(repositoryRoot);
  } on Object catch (error) {
    return <String>['Invalid $agentRegistryPath: $error'];
  }

  final ids = <String>{};
  for (final component in registry.components) {
    if (!ids.add(component.id)) {
      errors.add('Duplicate registry component id: ${component.id}.');
    }
    for (final relativePath in <String>[
      component.source,
      component.example,
      component.test,
      component.documentation,
    ]) {
      if (!File('$root/$relativePath').existsSync()) {
        errors.add('${component.id} references missing path: $relativePath.');
      }
    }
  }

  if (stateContract.existsSync()) {
    final state = loadYamlMap(stateContract);
    final rawComponents = state['components'];
    if (rawComponents is! YamlList) {
      errors.add('$agentStateContractPath components must be a list.');
    } else {
      final stateIds = <String>{};
      final stateTypes = <String, String>{};
      for (final raw in rawComponents.whereType<YamlMap>()) {
        final id = raw['id'];
        final publicType = raw['public_type'];
        if (id is String) stateIds.add(id);
        if (id is String && publicType is String) stateTypes[id] = publicType;
      }
      for (final id in stateIds.difference(ids)) {
        errors.add('State contract component is missing from registry: $id.');
      }
      for (final id in ids.difference(stateIds)) {
        errors.add('Registry component is missing from state contract: $id.');
      }
      for (final component in registry.components) {
        if (stateTypes[component.id] != component.publicType) {
          errors.add(
            '${component.id} public_type does not match state contract: '
            '${component.publicType} vs ${stateTypes[component.id]}.',
          );
        }
        if (component.stateContractId != component.id) {
          errors.add(
            '${component.id} state_contract_id must equal its registry id.',
          );
        }
      }
    }
  }

  if (tokenFile.existsSync()) {
    final tokenDocument = loadYamlMap(tokenFile);
    final tokenIds = <String>{};
    final layers = _map(tokenDocument['tokens'], 'tokens');
    for (final layer in <String>['primitives', 'semantics', 'components']) {
      final values = layers[layer];
      if (values is YamlList) {
        for (final raw in values.whereType<YamlMap>()) {
          if (raw['id'] is String) tokenIds.add(raw['id'] as String);
        }
      }
    }
    for (final component in registry.components) {
      for (final token in component.tokenReferences) {
        if (!tokenIds.contains(token)) {
          errors.add('${component.id} references missing token: $token.');
        }
      }
    }
  }

  return errors;
}

YamlMap _map(Object? value, String path) {
  if (value is YamlMap) return value;
  throw FormatException('$path must be a YAML mapping.');
}

String _string(Object? value, String path) {
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('$path must be a non-empty string.');
}

List<String> _strings(Object? value, String path) {
  if (value is! YamlList || value.isEmpty) {
    throw FormatException('$path must be a non-empty list.');
  }
  final result = <String>[];
  for (var index = 0; index < value.length; index++) {
    result.add(_string(value[index], '$path[$index]'));
  }
  return result;
}
