import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import 'src/agent_consumption.dart';

const generatedRegistryPath = 'generated/agent-registry.v1.json';
const generatedIndexPath = 'generated/llms.txt';
const generatedFullIndexPath = 'generated/llms-full.txt';
const generatedDocsRoot = 'generated/agent-docs';
const figmaMappingPath = 'contracts/components/figma-agent-mapping.yaml';

Future<void> main(List<String> arguments) async {
  final check = arguments.contains('--check');
  final write = arguments.contains('--write');
  if (check == write) {
    stderr.writeln('Use exactly one of --check or --write.');
    exitCode = 2;
    return;
  }

  final root = Directory.current;
  final errors = validateAgentRegistry(root);
  if (errors.isNotEmpty) {
    stderr.writeln(
      'Cannot generate agent docs because the registry is invalid:',
    );
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  final outputs = buildOutputs(root);
  final mismatches = <String>[];
  for (final entry in outputs.entries) {
    final file = File('${root.path}/${entry.key}');
    if (write) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    } else if (!file.existsSync() || file.readAsStringSync() != entry.value) {
      mismatches.add(entry.key);
    }
  }

  if (mismatches.isNotEmpty) {
    stderr.writeln('Generated agent docs drift detected:');
    for (final path in mismatches) {
      stderr.writeln('- $path');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    write
        ? 'Generated agent-readable documentation.'
        : 'Generated agent-readable documentation is up to date.',
  );
}

Map<String, String> buildOutputs(Directory root) {
  final registry = loadAgentRegistry(root);
  final stateDocument = loadYamlMap(
    File('${root.path}/$agentStateContractPath'),
  );
  final tokenDocument = loadYamlMap(File('${root.path}/$agentTokenPath'));
  final stateById = <String, YamlMap>{};
  final rawStates = stateDocument['components'];
  if (rawStates is YamlList) {
    for (final raw in rawStates.whereType<YamlMap>()) {
      if (raw['id'] is String) stateById[raw['id'] as String] = raw;
    }
  }

  final sources = <String, String>{
    agentRegistryPath: _checksum(root, agentRegistryPath),
    agentStateContractPath: _checksum(root, agentStateContractPath),
    agentStateEvidencePath: _checksum(root, agentStateEvidencePath),
    agentTokenPath: _checksum(root, agentTokenPath),
    figmaMappingPath: _checksum(root, figmaMappingPath),
  };
  final componentJson = <Map<String, Object?>>[];
  final componentDocs = <String, String>{};
  for (final component in registry.components) {
    final state = stateById[component.id];
    if (state == null) {
      throw StateError('Missing state contract for ${component.id}.');
    }
    final stateSummary = _stateSummary(state);
    componentJson.add(<String, Object?>{
      'id': component.id,
      'public_type': component.publicType,
      'purpose': component.purpose,
      'usage_boundary': component.usageBoundary,
      'source': component.source,
      'example': component.example,
      'test': component.test,
      'documentation': component.documentation,
      'token_references': component.tokenReferences,
      'platform_constraints': component.platformConstraints,
      'state_contract_id': component.stateContractId,
      'states': stateSummary,
    });
    componentDocs['$generatedDocsRoot/components/${component.id}.md'] =
        _componentDoc(component, stateSummary, sources);
  }

  final registryJson = <String, Object?>{
    'schema': 'blab.agent-component-registry/v1',
    'version': registry.version,
    '_generated': <String, Object?>{
      'notice': 'GENERATED CODE - DO NOT EDIT.',
      'sources': sources,
      'source_of_truth': 'contracts/blab.design.yaml',
      'remote_mutation': false,
    },
    'components': componentJson,
  };
  final outputs = <String, String>{
    generatedRegistryPath: '${_prettyJson(registryJson)}\n',
    generatedIndexPath: _indexDoc(registry, sources),
    generatedFullIndexPath: _fullIndexDoc(registry, componentDocs, sources),
    '$generatedDocsRoot/foundation/tokens.md': _tokenDoc(
      tokenDocument,
      sources,
    ),
    '$generatedDocsRoot/accessibility/states.md': _statesDoc(
      registry,
      stateById,
      sources,
    ),
    ...componentDocs,
  };
  return outputs;
}

String _componentDoc(
  AgentComponent component,
  Map<String, Object?> state,
  Map<String, String> sources,
) {
  final required = _list(state['required']);
  final conditional = _list(state['conditional']);
  final notApplicable = _list(state['not_applicable']);
  final lines = <String>[
    '<!-- GENERATED CODE - DO NOT EDIT. -->',
    '<!-- Sources: ${sources.keys.join(', ')} -->',
    '# ${component.publicType}',
    '',
    component.purpose,
    '',
    '## Usage boundary',
    '',
    component.usageBoundary,
    '',
    '## Source and evidence',
    '',
    '- Source: `${component.source}`',
    '- Example: `${component.example}`',
    '- Test: `${component.test}`',
    '- Documentation: `${component.documentation}`',
    '',
    '## Token references',
    '',
    ...component.tokenReferences.map((token) => '- `$token`'),
    '',
    '## State contract',
    '',
    '### Required',
    '',
    ..._bulletsOrNone(required),
    '',
    '### Conditional',
    '',
    ..._bulletsOrNone(conditional),
    '',
    '### Not applicable',
    '',
    ..._bulletsOrNone(notApplicable),
    '',
    '## Platform constraints',
    '',
    ...component.platformConstraints.map((item) => '- $item'),
    '',
    'Generated from the BLDS registry and state contract. '
        'Not-claimed behavior must not be presented as implemented.',
    '',
  ];
  return lines.join('\n');
}

String _indexDoc(AgentRegistry registry, Map<String, String> sources) {
  final lines = <String>[
    '# BLDS agent-readable index',
    '',
    '> Generated from the repository-owned BLDS contracts. '
        'This index is a read-only discovery surface; it is not semantic authority.',
    '',
    '## Authority',
    '',
    '- Semantic SSOT: `contracts/blab.design.yaml`',
    '- Registry: `agent-registry.v1.json`',
    '- Query contract: repository-local and read-only',
    '- Remote mutation: forbidden',
    '',
    '## Sources',
    '',
    ...sources.entries.map((entry) => '- `${entry.key}` — `${entry.value}`'),
    '',
    '## Foundations',
    '',
    '- [Token foundation](agent-docs/foundation/tokens.md)',
    '- [State and accessibility contract](agent-docs/accessibility/states.md)',
    '- [Figma-to-BLDS mapping contract](../$figmaMappingPath)',
    '',
    '## Components',
    '',
    ...registry.components.map(
      (component) =>
          '- [${component.publicType}](agent-docs/components/${component.id}.md) — ${component.purpose}',
    ),
    '',
    '## Interpretation rules',
    '',
    '- `required` means the state is required by the design contract.',
    '- `conditional` means the state needs its documented runtime or API condition.',
    '- `not_applicable` means the component must not simulate that state.',
    '- Missing or unverified evidence must be reported as not claimed.',
    '',
  ];
  return lines.join('\n');
}

String _fullIndexDoc(
  AgentRegistry registry,
  Map<String, String> componentDocs,
  Map<String, String> sources,
) {
  final buffer = StringBuffer()
    ..writeln('# BLDS full agent-readable index')
    ..writeln()
    ..writeln('Generated from the repository-owned BLDS contracts.')
    ..writeln()
    ..writeln('## Generated sources')
    ..writeln();
  for (final entry in sources.entries) {
    buffer.writeln('- `${entry.key}` — `${entry.value}`');
  }
  buffer.writeln();
  for (final component in registry.components) {
    buffer.writeln(
      componentDocs['$generatedDocsRoot/components/${component.id}.md']!
          .trimRight(),
    );
  }
  return buffer.toString();
}

String _tokenDoc(YamlMap document, Map<String, String> sources) {
  final tokens = <YamlMap>[];
  final layers = document['tokens'];
  if (layers is YamlMap) {
    for (final layer in <String>['primitives', 'semantics', 'components']) {
      final values = layers[layer];
      if (values is YamlList) tokens.addAll(values.whereType<YamlMap>());
    }
  }
  final legacy = document['legacy_mappings'];
  final cssEntries = legacy is YamlMap && legacy['css'] is YamlMap
      ? (legacy['css'] as YamlMap)['entries']
      : null;
  final dartSources = legacy is YamlMap && legacy['dart'] is YamlMap
      ? (legacy['dart'] as YamlMap)['sources']
      : null;
  final cssCount = cssEntries is YamlList ? cssEntries.length : 0;
  final cssMapped = cssEntries is YamlList
      ? cssEntries
            .whereType<YamlMap>()
            .where((entry) => entry['token'] != null)
            .length
      : 0;
  final dartSymbols = dartSources is YamlList
      ? dartSources
            .whereType<YamlMap>()
            .expand<Object?>(
              (source) => source['symbols'] is YamlList
                  ? source['symbols'] as YamlList
                  : const <Object?>[],
            )
            .whereType<YamlMap>()
            .toList(growable: false)
      : <YamlMap>[];
  final dartMapped = dartSymbols
      .where((entry) => entry['token'] != null)
      .length;
  final lines = <String>[
    '<!-- GENERATED CODE - DO NOT EDIT. -->',
    '# BLDS token foundation',
    '',
    'Authoritative token source: `contracts/tokens/blab.tokens.yaml`.',
    '',
    '## Sources',
    '',
    ...sources.entries.map((entry) => '- `${entry.key}` — `${entry.value}`'),
    '',
    '## Tokens',
    '',
    '| Layer | ID | Type |',
    '|---|---|---|',
    ...tokens.map((token) {
      final id = token['id'] as String;
      final layer = id.startsWith('primitive.')
          ? 'primitive'
          : id.startsWith('semantic.')
          ? 'semantic'
          : 'component';
      return '| `$layer` | `$id` | `${token['type']}` |';
    }),
    '',
    '## Compatibility boundary',
    '',
    'The typed graph above is the normalized query surface. Existing standard '
        'light/dark sources remain compatibility-locked until a separate '
        'Design-approved normalization decision.',
    '',
    '| Legacy surface | Entries | Mapped to typed graph | Preserved-only |',
    '|---|---:|---:|---:|',
    '| CSS custom properties | $cssCount | $cssMapped | ${cssCount - cssMapped} |',
    '| Dart theme symbols | ${dartSymbols.length} | $dartMapped | ${dartSymbols.length - dartMapped} |',
    '',
    'Legacy mappings are queryable by their exact CSS name or Dart symbol. '
        'A preserved-only result is compatibility evidence, not a new semantic '
        'token claim.',
    '',
  ];
  return lines.join('\n');
}

String _statesDoc(
  AgentRegistry registry,
  Map<String, YamlMap> stateById,
  Map<String, String> sources,
) {
  final lines = <String>[
    '<!-- GENERATED CODE - DO NOT EDIT. -->',
    '# BLDS state and accessibility contract',
    '',
    'State truth is sourced from `contracts/components/state-applicability.yaml` '
        'and its generated evidence mirror.',
    '',
    '## Sources',
    '',
    ...sources.entries.map((entry) => '- `${entry.key}` — `${entry.value}`'),
    '',
  ];
  for (final component in registry.components) {
    final state = stateById[component.id]!;
    lines
      ..add('## ${component.publicType}')
      ..add('')
      ..add('- Required: ${_inlineList(state['required'])}')
      ..add('- Conditional: ${_inlineList(state['conditional'])}')
      ..add('- Not applicable: ${_inlineList(state['not_applicable'])}')
      ..add('');
  }
  return lines.join('\n');
}

Map<String, Object?> _stateSummary(YamlMap state) => <String, Object?>{
  'required': _list(state['required']),
  'conditional': _list(state['conditional']),
  'not_applicable': _list(state['not_applicable']),
  'required_when': _jsonValue(state['required_when'] ?? <String, Object?>{}),
  'implementation_evidence': _jsonValue(
    state['implementation_evidence'] ?? <String, Object?>{},
  ),
  'absence_evidence': _jsonValue(
    state['absence_evidence'] ?? <String, Object?>{},
  ),
};

List<String> _list(Object? value) {
  if (value is! YamlList) return <String>[];
  return value.whereType<String>().toList(growable: false);
}

List<String> _bulletsOrNone(List<String> values) => values.isEmpty
    ? <String>['- None recorded.']
    : values.map((value) => '- `$value`').toList(growable: false);

String _inlineList(Object? value) {
  final values = _list(value);
  return values.isEmpty ? 'none' : values.map((item) => '`$item`').join(', ');
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

String _prettyJson(Object value) =>
    const JsonEncoder.withIndent('  ').convert(value);

String _checksum(Directory root, String relativePath) {
  final bytes = File('${root.path}/$relativePath').readAsBytesSync();
  return sha256.convert(bytes).toString();
}
