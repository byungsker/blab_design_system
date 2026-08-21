import 'dart:io';

import 'package:yaml/yaml.dart';

import 'src/agent_consumption.dart';

const mappingPath = 'contracts/components/figma-agent-mapping.yaml';

void main() {
  final root = Directory.current;
  final errors = <String>[];
  final file = File('${root.path}/$mappingPath');
  if (!file.existsSync()) {
    _finish(<String>['Missing $mappingPath.']);
    return;
  }
  final document = loadYamlMap(file);
  if (document['schema'] != 'blab.figma-agent-mapping/v1') {
    errors.add('Invalid mapping schema.');
  }
  final metadata = document['metadata'];
  if (metadata is! YamlMap || metadata['remote_mutation'] != false) {
    errors.add('Mapping must explicitly disable remote mutation.');
  }
  final reviewedSet = metadata is YamlMap ? metadata['reviewed_set'] : null;
  if (reviewedSet is! YamlList || !reviewedSet.contains('BLab/BottomBar')) {
    errors.add('Reviewed set must include BLab/BottomBar.');
  }

  final registryErrors = validateAgentRegistry(root);
  errors.addAll(registryErrors.map((error) => 'Registry: $error'));
  final registry = loadAgentRegistry(root);
  final publicTypes = <String, String>{
    for (final component in registry.components)
      component.id: component.publicType,
  };
  final tokenDocument = loadYamlMap(File('${root.path}/$agentTokenPath'));
  final tokenIds = <String>{};
  final layers = tokenDocument['tokens'];
  if (layers is YamlMap) {
    for (final layer in <String>['primitives', 'semantics', 'components']) {
      final values = layers[layer];
      if (values is YamlList) {
        for (final raw in values.whereType<YamlMap>()) {
          if (raw['id'] is String) tokenIds.add(raw['id'] as String);
        }
      }
    }
  }

  final mappings = document['mappings'];
  if (mappings is! YamlList || mappings.isEmpty) {
    errors.add('Mappings must be a non-empty list.');
  } else {
    final ids = <String>{};
    var bottomBarEntries = 0;
    for (var index = 0; index < mappings.length; index++) {
      final raw = mappings[index];
      if (raw is! YamlMap) {
        errors.add('mappings[$index] must be a mapping.');
        continue;
      }
      final id = raw['id'];
      final componentId = raw['registry_component_id'];
      final publicType = raw['public_type'];
      final status = raw['mapping_status'];
      final evidenceStatus = raw['evidence_status'];
      if (id is! String || !ids.add(id)) {
        errors.add('Duplicate or missing mapping id at $index.');
      }
      if (componentId is! String || !publicTypes.containsKey(componentId)) {
        errors.add('$id references an unknown registry component.');
      } else if (publicTypes[componentId] != publicType) {
        errors.add('$id public type does not match registry.');
      }
      if (raw['figma_component'] != 'BLab/BottomBar') {
        errors.add('$id must belong to the reviewed BottomBar set.');
      } else {
        bottomBarEntries++;
      }
      if (status is! String ||
          !<String>{
            'verified',
            'absent',
            'not-yet-reviewed',
          }.contains(status)) {
        errors.add('$id has invalid mapping_status.');
      }
      if (evidenceStatus is! String || evidenceStatus.trim().isEmpty) {
        errors.add('$id must have evidence_status.');
      }
      final evidence = raw['evidence'];
      if (evidence is! YamlList || evidence.isEmpty) {
        errors.add('$id needs evidence.');
      }
      if (status == 'absent' || status == 'not-yet-reviewed') {
        if (raw['reason'] is! String ||
            (raw['reason'] as String).trim().isEmpty) {
          errors.add('$id needs a reason for $status.');
        }
      }
      final tokenReferences = raw['token_references'];
      if (tokenReferences is YamlList) {
        for (final token in tokenReferences.whereType<String>()) {
          if (!tokenIds.contains(token)) {
            errors.add('$id references missing token $token.');
          }
        }
      }
      if (evidence is YamlList) {
        for (final path in evidence.whereType<String>()) {
          if (!File('${root.path}/$path').existsSync()) {
            errors.add('$id references missing evidence $path.');
          }
        }
      }
    }
    if (bottomBarEntries == 0) {
      errors.add('Reviewed BottomBar mapping set is empty.');
    }
  }

  _finish(errors);
}

void _finish(List<String> errors) {
  if (errors.isEmpty) {
    stdout.writeln('Figma agent mapping validation passed.');
    return;
  }
  stderr.writeln('Figma agent mapping validation failed:');
  for (final error in errors) {
    stderr.writeln('- $error');
  }
  exitCode = 1;
}
