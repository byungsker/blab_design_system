import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

const phase5CompatibilityPolicyPath = 'contracts/compatibility/policy.yaml';
const phase5CompatibilityBaselinePath =
    'contracts/compatibility/baseline-provenance.yaml';
const phase5MigrationRegistryPath = 'contracts/migrations/registry.yaml';

enum CompatibilitySurface { api, token }

enum CompatibilityClassification { additive, deprecated, breaking }

enum CompatibilityChangeKind {
  addition,
  deprecation,
  removal,
  signature,
  value,
  semantic,
}

class CompatibilityChange {
  const CompatibilityChange({
    required this.surface,
    required this.id,
    required this.kind,
    required this.classification,
    required this.stability,
    required this.before,
    required this.after,
  });

  final CompatibilitySurface surface;
  final String id;
  final CompatibilityChangeKind kind;
  final CompatibilityClassification classification;
  final String stability;
  final String? before;
  final String? after;

  Map<String, Object?> toJson() => <String, Object?>{
    'surface': _enumName(surface),
    'id': id,
    'kind': _enumName(kind),
    'classification': _enumName(classification),
    'stability': stability,
    'before': before,
    'after': after,
  };
}

class CompatibilityReport {
  CompatibilityReport({
    required List<CompatibilityChange> changes,
    required List<String> violations,
  }) : changes = List.unmodifiable(
         [...changes]..sort((left, right) {
           final surface = _enumName(
             left.surface,
           ).compareTo(_enumName(right.surface));
           return surface == 0 ? left.id.compareTo(right.id) : surface;
         }),
       ),
       violations = List.unmodifiable([...violations]..sort());

  final List<CompatibilityChange> changes;
  final List<String> violations;

  bool get passes => violations.isEmpty;

  Map<String, int?> get classifications => <String, int?>{
    'additive': changes
        .where(
          (change) =>
              change.classification == CompatibilityClassification.additive,
        )
        .length,
    'deprecated': null,
    'breaking': changes
        .where(
          (change) =>
              change.classification == CompatibilityClassification.breaking,
        )
        .length,
  };

  Map<String, String> get classificationSupport => const <String, String>{
    'additive': 'implemented',
    'deprecated': 'not-supported-in-phase5-classifier',
    'breaking': 'implemented',
  };

  Map<String, int> get kinds => <String, int>{
    for (final value in CompatibilityChangeKind.values)
      _enumName(value): changes.where((change) => change.kind == value).length,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': 'blab.compatibility-report/v1',
    'status': passes ? 'pass' : 'failure',
    'classifications': classifications,
    'classification_support': classificationSupport,
    'kinds': kinds,
    'changes': changes.map((change) => change.toJson()).toList(),
    'violations': violations,
  };
}

CompatibilityReport classifyRepositoryCompatibility(Directory root) {
  final provenance = _loadYamlMap(
    File('${root.path}/$phase5CompatibilityBaselinePath'),
  );
  final api = _map(provenance['api']);
  final tokens = _map(provenance['tokens']);
  final baselineApi = File('${root.path}/${api['path']}');
  final baselineTokens = File('${root.path}/${tokens['path']}');
  final currentApi = File('${root.path}/api/blab_design_system.api.txt');
  final currentTokens = File('${root.path}/contracts/tokens/blab.tokens.yaml');
  if (!baselineApi.existsSync() ||
      !baselineTokens.existsSync() ||
      !currentApi.existsSync() ||
      !currentTokens.existsSync()) {
    return CompatibilityReport(
      changes: const [],
      violations: const ['Compatibility input is missing.'],
    );
  }

  final violations = <String>[];
  _checkSha256(baselineApi, api['sha256'], violations);
  _checkSha256(baselineTokens, tokens['sha256'], violations);
  final changes = <CompatibilityChange>[
    ...classifyApiCompatibility(
      baselineApi.readAsStringSync(),
      currentApi.readAsStringSync(),
    ),
    ...classifyTokenCompatibility(
      baselineTokens.readAsStringSync(),
      currentTokens.readAsStringSync(),
    ),
  ];
  _applyDeclaredTokenCompatibilityCorrections(
    currentTokens.readAsStringSync(),
    changes,
    violations,
  );

  final migrations = _loadYamlMap(
    File('${root.path}/$phase5MigrationRegistryPath'),
  );
  final approvedIds = <String>{};
  final rawMigrations = migrations['migrations'];
  if (rawMigrations is YamlList) {
    for (final raw in rawMigrations.whereType<YamlMap>()) {
      if (raw['id'] is String &&
          raw['status'] == 'approved' &&
          raw['authority_status'] == 'approved') {
        approvedIds.add(raw['id'] as String);
      }
    }
  }
  for (final change in changes.where(
    (change) => change.classification == CompatibilityClassification.breaking,
  )) {
    if (!approvedIds.contains(change.id)) {
      violations.add(
        'Breaking ${_enumName(change.surface)} change ${change.id} has no '
        'approved migration and authority.',
      );
    }
  }
  return CompatibilityReport(changes: changes, violations: violations);
}

void _applyDeclaredTokenCompatibilityCorrections(
  String currentTokenYaml,
  List<CompatibilityChange> changes,
  List<String> violations,
) {
  final document = loadYaml(currentTokenYaml);
  if (document is! YamlMap) {
    violations.add('Token contract must be a mapping.');
    return;
  }
  final metadata = _map(document['metadata']);
  final rawCorrections =
      metadata['approved_standard_mode_compatibility_exceptions'];
  if (rawCorrections is! YamlList) return;

  for (final correction in rawCorrections.whereType<YamlMap>()) {
    final decisionRef = correction['decision_ref'];
    final tokenIds = correction['token_ids'];
    final affectedModes = correction['affected_modes'];
    final previous = correction['previous'];
    final replacement = correction['replacement'];
    final classification = correction['classification'];
    if (decisionRef is! String ||
        tokenIds is! YamlList ||
        affectedModes is! YamlList ||
        previous is! String ||
        replacement is! String ||
        classification != 'breaking-compatibility-correction') {
      violations.add(
        'Approved standard-mode token compatibility correction metadata is '
        'incomplete.',
      );
      continue;
    }
    final modes = affectedModes.whereType<String>().toSet();
    if (modes.isEmpty || previous == replacement) {
      violations.add(
        'Approved token compatibility correction $decisionRef does not '
        'declare a value-changing mode set.',
      );
      continue;
    }
    for (final tokenId in tokenIds.whereType<String>()) {
      final changeId = 'typed:$tokenId';
      final index = changes.indexWhere((change) => change.id == changeId);
      if (index < 0) {
        violations.add(
          'Approved token compatibility correction $decisionRef does not '
          'match classifier change $changeId.',
        );
        continue;
      }
      final change = changes[index];
      if (change.surface != CompatibilitySurface.token ||
          change.after == null) {
        violations.add(
          'Approved token compatibility correction $decisionRef has an '
          'invalid classifier surface for $changeId.',
        );
        continue;
      }
      final afterParts = change.after!.split('|');
      final beforeParts = <String>[afterParts.first];
      var matchedAffectedMode = false;
      var invalidReplacement = false;
      for (final part in afterParts.skip(1)) {
        final separator = part.indexOf('=');
        if (separator < 1) {
          beforeParts.add(part);
          continue;
        }
        final mode = part.substring(0, separator);
        final value = part.substring(separator + 1);
        if (!modes.contains(mode)) {
          beforeParts.add(part);
          continue;
        }
        matchedAffectedMode = true;
        if (value != replacement) invalidReplacement = true;
        beforeParts.add('$mode=$previous');
      }
      if (!matchedAffectedMode || invalidReplacement) {
        violations.add(
          'Approved token compatibility correction $decisionRef does not '
          'match the current replacement for $changeId.',
        );
        continue;
      }
      changes[index] = CompatibilityChange(
        surface: CompatibilitySurface.token,
        id: change.id,
        kind: CompatibilityChangeKind.value,
        classification: CompatibilityClassification.breaking,
        stability: change.stability,
        before: beforeParts.join('|'),
        after: change.after,
      );
    }
  }
}

List<CompatibilityChange> classifyApiCompatibility(
  String baseline,
  String current,
) {
  final before = parseApiEntries(baseline);
  final after = parseApiEntries(current);
  final changes = <CompatibilityChange>[];
  for (final id in {...before.keys, ...after.keys}) {
    final oldValue = before[id];
    final newValue = after[id];
    final stability = _stability(id);
    if (oldValue == null) {
      changes.add(
        CompatibilityChange(
          surface: CompatibilitySurface.api,
          id: id,
          kind: CompatibilityChangeKind.addition,
          classification: CompatibilityClassification.additive,
          stability: stability,
          before: null,
          after: newValue,
        ),
      );
    } else if (newValue == null) {
      changes.add(
        CompatibilityChange(
          surface: CompatibilitySurface.api,
          id: id,
          kind: CompatibilityChangeKind.removal,
          classification: CompatibilityClassification.breaking,
          stability: stability,
          before: oldValue,
          after: null,
        ),
      );
    } else if (oldValue != newValue) {
      final additive = _isDefaultSafeOptionalAddition(oldValue, newValue);
      final valueChange =
          oldValue.startsWith('field ') && newValue.startsWith('field ');
      changes.add(
        CompatibilityChange(
          surface: CompatibilitySurface.api,
          id: id,
          kind: valueChange
              ? CompatibilityChangeKind.value
              : CompatibilityChangeKind.signature,
          classification: additive
              ? CompatibilityClassification.additive
              : CompatibilityClassification.breaking,
          stability: stability,
          before: oldValue,
          after: newValue,
        ),
      );
    }
  }
  return changes;
}

Map<String, String> parseApiEntries(String snapshot) {
  final entries = <String, String>{};
  String? owner;
  for (final rawLine in const LineSplitter().convert(snapshot)) {
    if (rawLine.isEmpty || rawLine.startsWith('#')) {
      continue;
    }
    final line = rawLine.trim();
    if (!rawLine.startsWith(' ')) {
      owner = _topLevelApiId(line);
      entries[owner] = line;
      continue;
    }
    if (owner == null) {
      continue;
    }
    final member = _memberApiId(line);
    entries['$owner::$member'] = line;
  }
  return entries;
}

List<CompatibilityChange> classifyTokenCompatibility(
  String baselineCss,
  String currentTokenYaml,
) {
  return classifyTokenEntryMaps(
    parseCssTokenEntries(baselineCss),
    parseCurrentTokenEntries(currentTokenYaml),
  );
}

List<CompatibilityChange> classifyTokenEntryMaps(
  Map<String, String> before,
  Map<String, String> after,
) {
  final changes = <CompatibilityChange>[];
  for (final id in {...before.keys, ...after.keys}) {
    final oldValue = before[id];
    final newValue = after[id];
    final stability = _stability(id);
    if (oldValue == null) {
      changes.add(
        CompatibilityChange(
          surface: CompatibilitySurface.token,
          id: id,
          kind: CompatibilityChangeKind.addition,
          classification: CompatibilityClassification.additive,
          stability: stability,
          before: null,
          after: newValue,
        ),
      );
    } else if (newValue == null) {
      changes.add(
        CompatibilityChange(
          surface: CompatibilitySurface.token,
          id: id,
          kind: CompatibilityChangeKind.removal,
          classification: CompatibilityClassification.breaking,
          stability: stability,
          before: oldValue,
          after: null,
        ),
      );
    } else if (oldValue != newValue) {
      final oldType = oldValue.split('|').first;
      final newType = newValue.split('|').first;
      final oldSemantic = oldValue.contains('{');
      final newSemantic = newValue.contains('{');
      changes.add(
        CompatibilityChange(
          surface: CompatibilitySurface.token,
          id: id,
          kind: oldType != newType || oldSemantic != newSemantic
              ? CompatibilityChangeKind.semantic
              : CompatibilityChangeKind.value,
          classification: CompatibilityClassification.breaking,
          stability: stability,
          before: oldValue,
          after: newValue,
        ),
      );
    }
  }
  return changes;
}

Map<String, String> parseCssTokenEntries(String css) {
  final entries = <String, String>{};
  var mode = 'light';
  for (final rawLine in const LineSplitter().convert(css)) {
    final line = rawLine.trim();
    if (line.startsWith('[data-theme="dark"]')) {
      mode = 'dark';
    } else if (line == ':root {') {
      mode = 'light';
    } else if (line == '}') {
      mode = 'light';
    }
    for (final match in RegExp(
      r'(--[a-z0-9-]+)\s*:\s*([^;]+);',
    ).allMatches(line)) {
      entries['css:${match.group(1)}:$mode'] =
          'legacy-css|${match.group(2)!.trim()}';
    }
  }
  return entries;
}

Map<String, String> parseCurrentTokenEntries(String yamlSource) {
  final document = loadYaml(yamlSource);
  if (document is! YamlMap) {
    throw const FormatException('Token contract must be a mapping.');
  }
  final entries = <String, String>{};
  final legacy = _map(_map(document['legacy_mappings'])['css']);
  final cssEntries = legacy['entries'];
  if (cssEntries is YamlList) {
    for (final raw in cssEntries.whereType<YamlMap>()) {
      final name = raw['name'];
      final type = raw['type'];
      if (name is! String || type is! String) continue;
      for (final mode in const ['light', 'dark']) {
        final value = raw[mode];
        if (value is String) {
          entries['css:$name:$mode'] = 'legacy-css|$value';
        }
      }
    }
  }
  final tokens = _map(document['tokens']);
  for (final layer in const ['primitives', 'semantics', 'components']) {
    final rawEntries = tokens[layer];
    if (rawEntries is! YamlList) continue;
    for (final raw in rawEntries.whereType<YamlMap>()) {
      final id = raw['id'];
      final type = raw['type'];
      if (id is! String || type is! String) continue;
      final value = raw['value'];
      if (value is String) {
        entries['typed:$id'] = '$type|value=$value';
      }
      final modes = raw['modes'];
      if (modes is YamlMap) {
        final parts = <String>[];
        for (final mode in modes.keys.whereType<String>().toList()..sort()) {
          parts.add('$mode=${modes[mode]}');
        }
        entries['typed:$id'] = '$type|${parts.join('|')}';
      }
    }
  }
  return entries;
}

String sha256File(File file) =>
    sha256.convert(file.readAsBytesSync()).toString();

String _topLevelApiId(String line) {
  final match = RegExp(
    r'^(?:(?:abstract|base|final|interface|sealed)\s+)*(?:class|enum|mixin|extension type|extension|typedef|function|field|getter|setter)\s+([A-Za-z0-9_]+)',
  ).firstMatch(line);
  return 'api:${match?.group(1) ?? line.split(RegExp(r'\s+')).last}';
}

String _memberApiId(String line) {
  if (line.startsWith('values:')) return 'values';
  final constructor = RegExp(
    r'^constructor\s+(?:(?:const|factory)\s+)?([A-Za-z0-9_.]+)',
  ).firstMatch(line);
  if (constructor != null) return 'constructor:${constructor.group(1)}';
  final method = RegExp(
    r'^(?:method|setter)\s+(?:static\s+)?(?:[^\s]+\s+)?([A-Za-z0-9_]+)\(',
  ).firstMatch(line);
  if (method != null) return 'callable:${method.group(1)}';
  final getter = RegExp(
    r'^getter\s+(?:static\s+)?[^\s]+\s+([A-Za-z0-9_]+)$',
  ).firstMatch(line);
  if (getter != null) return 'getter:${getter.group(1)}';
  final field = RegExp(
    r'^field\s+.*\s([A-Za-z0-9_]+)(?:\s*=.*)?$',
  ).firstMatch(line);
  if (field != null) return 'field:${field.group(1)}';
  return line;
}

bool _isDefaultSafeOptionalAddition(String before, String after) {
  if (!before.contains('(') || !after.contains('(')) {
    return false;
  }
  final beforeParameters = _parametersByName(before);
  final afterParameters = _parametersByName(after);
  final beforeNames = beforeParameters.keys.toSet();
  final afterNames = afterParameters.keys.toSet();
  if (!afterNames.containsAll(beforeNames)) {
    return false;
  }
  final changedExisting = beforeNames.where(
    (name) =>
        beforeParameters[name] != afterParameters[name] &&
        !_isNullableInputWidening(
          name,
          beforeParameters[name]!,
          afterParameters[name]!,
        ),
  );
  if (changedExisting.isNotEmpty) {
    return false;
  }
  final additions = afterNames.difference(beforeNames);
  if (additions.isEmpty) {
    return beforeNames.any(
      (name) => _isNullableInputWidening(
        name,
        beforeParameters[name]!,
        afterParameters[name]!,
      ),
    );
  }
  return additions.every((name) {
    final parameter = afterParameters[name]!;
    return !parameter.startsWith('required ') &&
        (parameter.contains('=') || parameter.contains('?'));
  });
}

Map<String, String> _parametersByName(String signature) {
  final content = signature.substring(
    signature.indexOf('(') + 1,
    signature.lastIndexOf(')'),
  );
  final result = <String, String>{};
  for (final raw in _splitTopLevelParameters(content)) {
    final parameter = raw
        .replaceAll(RegExp(r'^[\s{\[]+'), '')
        .replaceAll(RegExp(r'[\s}\]]+$'), '')
        .trim();
    final name = RegExp(
      r'([A-Za-z_][A-Za-z0-9_]*)\s*(?:=|$)',
    ).firstMatch(parameter)?.group(1);
    if (name != null) {
      result[name] = parameter;
    }
  }
  return result;
}

bool _isNullableInputWidening(String name, String before, String after) {
  final nullableBeforeName = RegExp(r'\?\s+' + RegExp.escape(name) + r'\b');
  if (!nullableBeforeName.hasMatch(after)) {
    return false;
  }
  return after.replaceFirst(nullableBeforeName, ' $name') == before;
}

List<String> _splitTopLevelParameters(String content) {
  final parts = <String>[];
  var start = 0;
  var parenthesisDepth = 0;
  for (var index = 0; index < content.length; index += 1) {
    final character = content[index];
    if (character == '(') {
      parenthesisDepth += 1;
    } else if (character == ')') {
      parenthesisDepth -= 1;
    } else if (character == ',' && parenthesisDepth == 0) {
      parts.add(content.substring(start, index));
      start = index + 1;
    }
  }
  parts.add(content.substring(start));
  return parts;
}

String _stability(String id) =>
    id.contains('BLabExperimental') || id.contains('.experimental.')
    ? 'experimental'
    : 'stable';

void _checkSha256(File file, Object? expected, List<String> errors) {
  if (expected is! String || sha256File(file) != expected) {
    errors.add('Immutable baseline checksum mismatch: ${file.path}.');
  }
}

YamlMap _loadYamlMap(File file) {
  final value = loadYaml(file.readAsStringSync());
  if (value is! YamlMap) {
    throw FormatException('${file.path} must contain a mapping.');
  }
  return value;
}

YamlMap _map(Object? value) =>
    value is YamlMap ? value : throw const FormatException('Expected mapping.');

String _enumName(Object value) => value.toString().split('.').last;
