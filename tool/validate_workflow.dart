import 'dart:io';

import 'package:yaml/yaml.dart';

const workflowPath = '.github/workflows/verify.yml';

void main() {
  final errors = <String>[];
  final file = File(workflowPath);
  if (!file.existsSync()) {
    errors.add('$workflowPath is missing.');
  } else {
    try {
      final source = file.readAsStringSync();
      final document = loadYaml(source);
      if (document is! YamlMap) {
        errors.add('$workflowPath must contain a YAML mapping.');
      } else {
        if (document['name'] != 'verify') {
          errors.add('$workflowPath must use the stable verify name.');
        }
        final permissions = document['permissions'];
        if (permissions is! YamlMap ||
            permissions['contents'] != 'read' ||
            permissions.length != 1) {
          errors.add('$workflowPath permissions must be contents: read only.');
        }
        final jobs = document['jobs'];
        final verify = jobs is YamlMap ? jobs['verify'] : null;
        final steps = verify is YamlMap ? verify['steps'] : null;
        final strategy = verify is YamlMap ? verify['strategy'] : null;
        final matrix = strategy is YamlMap ? strategy['matrix'] : null;
        final runners = matrix is YamlMap ? matrix['os'] : null;
        const expectedRunners = <String>{
          'ubuntu-latest',
          'macos-latest',
          'windows-latest',
        };
        if (runners is! YamlList ||
            runners
                .whereType<String>()
                .toSet()
                .difference(expectedRunners)
                .isNotEmpty ||
            expectedRunners
                .difference(runners.whereType<String>().toSet())
                .isNotEmpty) {
          errors.add(
            '$workflowPath must configure the safe three-host package matrix.',
          );
        }
        if (strategy is! YamlMap || strategy['fail-fast'] != false) {
          errors.add('$workflowPath matrix must use fail-fast: false.');
        }
        if (steps is! YamlList || steps.isEmpty) {
          errors.add('$workflowPath must define verify steps.');
        } else {
          final checkoutSteps = steps
              .whereType<YamlMap>()
              .where((step) => step['uses'] == 'actions/checkout@v4')
              .toList();
          final checkoutWith = checkoutSteps.length == 1
              ? checkoutSteps.single['with']
              : null;
          if (checkoutWith is! YamlMap || checkoutWith['fetch-depth'] != 0) {
            errors.add(
              '$workflowPath must fetch full history for immutable baseline '
              'Git-object verification.',
            );
          }
          final runCommands = steps
              .whereType<YamlMap>()
              .map((step) => step['run'])
              .whereType<String>()
              .toList();
          if (!runCommands.contains('dart run tool/verify.dart')) {
            errors.add('$workflowPath must invoke the aggregate local gate.');
          }
        }
      }
      final forbidden = <String>[
        r'${{ secrets.',
        'id-token: write',
        'packages: write',
        'contents: write',
        'deploy',
        'release',
      ];
      for (final value in forbidden) {
        if (source.toLowerCase().contains(value.toLowerCase())) {
          errors.add('$workflowPath contains forbidden authority: $value');
        }
      }
    } on YamlException catch (error) {
      errors.add('$workflowPath is invalid YAML: ${error.message}');
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('BLDS workflow validation failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln('BLDS workflow validation passed.');
}
