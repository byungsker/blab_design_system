import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import 'evaluate_agent_fixtures.dart';

const pilotPath = 'contracts/agent/pilot.yaml';
const generatedPilotPath = 'generated/agent-pilot-result.v1.json';

void main(List<String> arguments) {
  final check = arguments.contains('--check');
  final write = arguments.contains('--write');
  if (check == write) {
    stderr.writeln('Use exactly one of --check or --write.');
    exitCode = 2;
    return;
  }
  final root = Directory.current;
  final pilotFile = File('${root.path}/$pilotPath');
  if (!pilotFile.existsSync()) {
    stderr.writeln('Missing $pilotPath.');
    exitCode = 1;
    return;
  }
  final pilot = loadYaml(pilotFile.readAsStringSync());
  final errors = _validatePilot(pilot);
  if (errors.isNotEmpty) {
    stderr.writeln('Pilot contract validation failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  final pilotMap = pilot as YamlMap;

  final decision = buildPilotReport(root, pilotMap);
  final output = '${const JsonEncoder.withIndent('  ').convert(decision)}\n';
  final generated = File('${root.path}/$generatedPilotPath');
  if (write) {
    generated.parent.createSync(recursive: true);
    generated.writeAsStringSync(output);
  } else if (!generated.existsSync() ||
      generated.readAsStringSync() != output) {
    stderr.writeln(
      'Generated pilot report drift detected: $generatedPilotPath',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln(
    write
        ? 'Generated agent pilot report.'
        : 'Agent pilot report is up to date.',
  );
  if (decision['decision'] != 'GO') exitCode = 1;
}

Map<String, Object?> buildPilotReport(Directory root, YamlMap pilotMap) {
  final evaluation = evaluateAgentFixtures(root);
  return <String, Object?>{
    'schema': 'blab.agent-pilot-result/v1',
    'pilot_source': pilotPath,
    'workflow': _jsonValue(pilotMap['workflow']),
    'decision_contract': <String, Object?>{
      'fixture_source': (pilotMap['decision'] as YamlMap)['fixture_source'],
      'denominator': (pilotMap['decision'] as YamlMap)['denominator'],
      'minimum_pass': (pilotMap['decision'] as YamlMap)['minimum_pass'],
      'maximum_critical_failures':
          (pilotMap['decision'] as YamlMap)['maximum_critical_failures'],
    },
    'evaluation': evaluation,
    'maintenance': _jsonValue(pilotMap['maintenance']),
    'source_checksums': <String, String>{
      pilotPath: _checksum(File('${root.path}/$pilotPath')),
      'contracts/agent/evaluation-fixtures.yaml': _checksum(
        File('${root.path}/contracts/agent/evaluation-fixtures.yaml'),
      ),
    },
    'decision': evaluation['go'] == true ? 'GO' : 'HOLD',
  };
}

List<String> _validatePilot(Object? pilot) {
  final errors = <String>[];
  if (pilot is! YamlMap || pilot['schema'] != 'blab.agent-pilot/v1') {
    return <String>['Invalid pilot schema.'];
  }
  final workflow = pilot['workflow'];
  if (workflow is! YamlMap || workflow['issue'] != 'BLA-7 / BAR-86') {
    errors.add('Pilot must identify BLA-7 / BAR-86.');
  }
  final decision = pilot['decision'];
  if (decision is! YamlMap ||
      decision['denominator'] != 10 ||
      decision['minimum_pass'] != 9 ||
      decision['maximum_critical_failures'] != 0) {
    errors.add('Pilot must use the fixed 10-fixture GO/HOLD rule.');
  }
  final maintenance = pilot['maintenance'];
  if (maintenance is! YamlMap ||
      maintenance['owner'] is! String ||
      maintenance['verification_command'] is! String) {
    errors.add('Pilot maintenance must declare an owner and verifier.');
  }
  return errors;
}

String _checksum(File file) =>
    sha256.convert(file.readAsBytesSync()).toString();

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
