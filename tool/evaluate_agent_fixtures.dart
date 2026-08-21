import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'src/agent_query.dart';

const fixturePath = 'contracts/agent/evaluation-fixtures.yaml';

void main() {
  final root = Directory.current;
  final report = evaluateAgentFixtures(root);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  if (report['go'] != true) exitCode = 1;
}

Map<String, Object?> evaluateAgentFixtures(Directory root) {
  final file = File('${root.path}/$fixturePath');
  if (!file.existsSync()) {
    throw StateError('Missing $fixturePath.');
  }
  final document = loadYaml(file.readAsStringSync());
  if (document is! YamlMap ||
      document['schema'] != 'blab.agent-evaluation/v1') {
    throw StateError('Invalid evaluation fixture schema.');
  }
  final fixtures = document['fixtures'];
  if (fixtures is! YamlList || fixtures.length != 10) {
    throw StateError('Evaluation fixture denominator must be exactly 10.');
  }

  final engine = AgentQueryEngine(root);
  var passed = 0;
  var criticalFailures = 0;
  final evidenceChecked = <String>{};
  final unresolvedEvidence = <String>[];
  final failures = <Map<String, Object?>>[];
  for (final raw in fixtures.whereType<YamlMap>()) {
    final id = raw['id'] as String? ?? 'unknown';
    final severity = raw['severity'] as String? ?? 'normal';
    final query = raw['query'];
    if (query is! YamlMap ||
        query['kind'] is! String ||
        query['id'] is! String) {
      failures.add(<String, Object?>{'id': id, 'error': 'invalid-query'});
      if (severity == 'critical') criticalFailures++;
      continue;
    }
    Map<String, Object?> result;
    try {
      result = <String, Object?>{
        'result': engine.query(
          kind: query['kind'] as String,
          id: query['id'] as String,
        ),
      };
    } on Object catch (error) {
      failures.add(<String, Object?>{'id': id, 'error': error.toString()});
      if (severity == 'critical') criticalFailures++;
      continue;
    }
    for (final path in _evidencePaths(result)) {
      evidenceChecked.add(path);
      if (!File('${root.path}/$path').existsSync()) {
        unresolvedEvidence.add(path);
      }
    }
    final assertionFailures = <String>[];
    final assertions = raw['assertions'];
    if (assertions is! YamlList) {
      assertionFailures.add('missing assertions');
    } else {
      for (final assertion in assertions.whereType<YamlMap>()) {
        final path = assertion['path'] as String?;
        if (path == null) {
          assertionFailures.add('assertion path missing');
          continue;
        }
        final value = _atPath(result, path);
        if (assertion['equals'] != null && value != assertion['equals']) {
          assertionFailures.add(
            '$path expected ${assertion['equals']} got $value',
          );
        }
        if (assertion['contains'] != null &&
            (value is! List || !value.contains(assertion['contains']))) {
          assertionFailures.add(
            '$path does not contain ${assertion['contains']}',
          );
        }
        if (assertion['not_empty'] == true &&
            (value == null || (value is String && value.isEmpty))) {
          assertionFailures.add('$path is empty');
        }
      }
    }
    if (assertionFailures.isEmpty) {
      passed++;
    } else {
      failures.add(<String, Object?>{
        'id': id,
        'assertions': assertionFailures,
      });
      if (severity == 'critical') criticalFailures++;
    }
  }

  final report = <String, Object?>{
    'schema': 'blab.agent-evaluation-result/v1',
    'fixture_source': fixturePath,
    'denominator': fixtures.length,
    'passed': passed,
    'failed': fixtures.length - passed,
    'critical_failures': criticalFailures,
    'evidence_checked': evidenceChecked.length,
    'unresolved_evidence': unresolvedEvidence,
    'go': passed >= 9 && criticalFailures == 0 && unresolvedEvidence.isEmpty,
    'failures': failures,
  };
  return report;
}

Iterable<String> _evidencePaths(Object? value, [String? key]) sync* {
  if (value is Map) {
    for (final entry in value.entries) {
      yield* _evidencePaths(entry.value, entry.key.toString());
    }
  } else if (value is List) {
    for (final item in value) {
      yield* _evidencePaths(item, key);
    }
  } else if (value is String &&
      (key == 'evidence' || key == 'source' || key == 'path') &&
      !value.contains('://')) {
    yield value;
  }
}

Object? _atPath(Object? root, String path) {
  Object? current = root;
  for (final part in path.split('.')) {
    if (current is Map) {
      current = current[part];
    } else {
      return null;
    }
  }
  return current;
}
