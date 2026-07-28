import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

const contractPath = 'contracts/blab.design.yaml';
const contractSchemaPath = 'contracts/schema/blab.design.schema.yaml';

const _supportedTokenTypes = {
  'color',
  'color-or-none',
  'dimension',
  'percentage',
  'shadow-or-none',
};

const _requiredModes = {
  'light',
  'dark',
  'high-contrast-light',
  'high-contrast-dark',
};

final RegExp _tokenReference = RegExp(r'^\{([^{}]+)\}$');
final RegExp _colorLiteral = RegExp(r'^#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?$');
final RegExp _dimensionLiteral = RegExp(r'^-?(?:\d+(?:\.\d+)?|\.\d+)px$');
final RegExp _percentageLiteral = RegExp(r'^-?(?:\d+(?:\.\d+)?|\.\d+)%$');
final RegExp _shadowLiteral = RegExp(
  r'^(-?(?:\d+(?:\.\d+)?|\.\d+))(px)?\s+'
  r'(-?(?:\d+(?:\.\d+)?|\.\d+))px\s+'
  r'(-?(?:\d+(?:\.\d+)?|\.\d+))px\s+'
  r'rgba\((\d{1,3}),(\d{1,3}),(\d{1,3}),'
  r'((?:0|1)(?:\.0+)?|0?\.\d+)\)$',
);

const _legacyMappingClassifications = {
  'mapped',
  'legacy-compatible',
  'legacy-retained',
  'compatibility-correction',
};

const _legacyDeprecations = {'none', 'legacy-retained', 'deprecated'};
const _phaseZeroHistoricalDigests = <String, String>{
  'lib/src/widgets/blab_segmented_control.dart':
      'd3fa831d6cf4764130cd4f1430f134f7db840b0dbd1816a067ca7a776cf97628',
  'lib/src/widgets/blab_snackbar.dart':
      'ec4ab071ef6163debf9a9aacefe31efc4ce5fd9670e4704ff47bfd4c4354300f',
  'lib/src/widgets/keyboard_accessory_bar.dart':
      '1c567a5430b52d41ee40afa927179712bb8fea0fe58aa833bbdfe0f4bbc6dd29',
  'lib/src/widgets/liquid_glass_button.dart':
      '27400bff8776551ca6803dd799bf12d83020320b33979d30649fc61fad88bf4f',
  'lib/src/widgets/liquid_glass_text_field.dart':
      '6f7775e19887d9e227d21a01278d2fae3feea662cc8cbb94c2a822b8dcc6948f',
  'lib/src/widgets/liquid_glass_tab_bar.dart':
      '6120a861479ca1db44eb1fd14680a48ab046652e4f63bfc262c157a0176d8bc3',
};

class BlabTokenNode {
  const BlabTokenNode({
    required this.id,
    required this.layer,
    required this.type,
    required this.value,
    required this.modes,
  });

  final String id;
  final String layer;
  final String type;
  final Object? value;
  final Map<String, Object?> modes;
}

class BlabCssMapping {
  const BlabCssMapping({
    required this.name,
    required this.type,
    required this.light,
    required this.dark,
    required this.token,
    required this.classification,
    required this.deprecation,
  });

  final String name;
  final String type;
  final String light;
  final String? dark;
  final String? token;
  final String classification;
  final String deprecation;
}

class BlabTokenModel {
  const BlabTokenModel({
    required this.version,
    required this.sourcePath,
    required this.nodes,
    required this.cssMappings,
    required this.dartMappingCount,
    required this.componentRawValueCount,
  });

  final String version;
  final String sourcePath;
  final Map<String, BlabTokenNode> nodes;
  final List<BlabCssMapping> cssMappings;
  final int dartMappingCount;
  final int componentRawValueCount;

  String resolve(String id, String mode) {
    return _resolve(id, mode, <String>[]);
  }

  String _resolve(String id, String mode, List<String> stack) {
    final cycleIndex = stack.indexOf(id);
    if (cycleIndex != -1) {
      final cycle = [...stack.sublist(cycleIndex), id].join(' -> ');
      throw StateError('Token reference cycle: $cycle');
    }
    final node = nodes[id];
    if (node == null) {
      throw StateError('Missing token reference: $id');
    }

    final raw = node.modes.isEmpty ? node.value : node.modes[mode];
    if (raw == null) {
      throw StateError('Token $id has no value for mode $mode');
    }
    final text = raw.toString();
    final match = _tokenReference.firstMatch(text);
    if (match == null) {
      return text;
    }
    return _resolve(match.group(1)!, mode, [...stack, id]);
  }
}

class BlabContractInspection {
  BlabContractInspection({
    required List<String> errors,
    required this.tokenModel,
  }) : errors = List<String>.unmodifiable(errors);

  final List<String> errors;
  final BlabTokenModel? tokenModel;
}

List<String> validateBlabContract(Directory repositoryRoot) {
  return inspectBlabContract(repositoryRoot).errors;
}

BlabContractInspection inspectBlabContract(Directory repositoryRoot) {
  final errors = <String>[];
  final contractFile = File('${repositoryRoot.path}/$contractPath');
  final schemaFile = File('${repositoryRoot.path}/$contractSchemaPath');

  final contract = _loadYamlMap(contractFile, errors);
  final schema = _loadYamlMap(schemaFile, errors);
  if (contract == null || schema == null) {
    return BlabContractInspection(errors: errors, tokenModel: null);
  }

  _validateSchemaRules(contract, schema, errors);
  _validateReferenceManifest(repositoryRoot, contract, errors);
  _validateLocalization(repositoryRoot, contract, errors);
  _validateCapabilities(repositoryRoot, contract, errors);
  _validateOutputs(repositoryRoot, contract, errors);
  _validateReferencedContractFiles(repositoryRoot, contract, errors);
  final tokenModel = loadBlabTokenModel(
    repositoryRoot,
    contract: contract,
    errors: errors,
  );
  if (tokenModel != null) {
    _validateSegmentedControlDecision(
      repositoryRoot,
      contract,
      tokenModel,
      errors,
    );
    _validateTabBarDecision(repositoryRoot, contract, tokenModel, errors);
    _validateBottomBarDecision(repositoryRoot, contract, tokenModel, errors);
    _validateSnackbarDecision(repositoryRoot, contract, tokenModel, errors);
    _validateKeyboardAccessoryDecision(
      repositoryRoot,
      contract,
      tokenModel,
      errors,
    );
    _validatePressableCardDecision(
      repositoryRoot,
      contract,
      tokenModel,
      errors,
    );
  }

  return BlabContractInspection(errors: errors, tokenModel: tokenModel);
}

BlabTokenModel? loadBlabTokenModel(
  Directory repositoryRoot, {
  YamlMap? contract,
  List<String>? errors,
}) {
  final validationErrors = errors ?? <String>[];
  final loadedContract =
      contract ??
      _loadYamlMap(
        File('${repositoryRoot.path}/$contractPath'),
        validationErrors,
      );
  if (loadedContract == null) {
    return null;
  }

  YamlMap tokenSource = loadedContract;
  var sourcePath = contractPath;
  if (loadedContract['tokens'] == null) {
    final modelRef = _valueAtPath(
      loadedContract,
      'values.typed_token_model_ref',
    );
    if (modelRef is! String || modelRef.isEmpty) {
      validationErrors.add(
        'values.typed_token_model_ref must be a non-empty string.',
      );
      return null;
    }
    final modelFile = _containedFile(
      repositoryRoot,
      modelRef,
      validationErrors,
      label: 'Typed token model',
    );
    if (modelFile == null) {
      return null;
    }
    final loadedModel = _loadYamlMap(modelFile, validationErrors);
    if (loadedModel == null) {
      return null;
    }
    tokenSource = loadedModel;
    sourcePath = modelRef;
    if (tokenSource['schema'] != 'blab.tokens/v1') {
      validationErrors.add(
        'Unsupported typed token schema: ${tokenSource['schema']}',
      );
    }
  }

  final nodes = _parseTokenNodes(tokenSource, validationErrors);
  _validateTokenLiteralsAndReferenceTypes(nodes, validationErrors);
  _validateTokenReferencesAndCycles(nodes, validationErrors);
  final cssMappings = _parseCssMappings(tokenSource, nodes, validationErrors);
  final dartCount = _validateDartMappings(
    repositoryRoot,
    tokenSource,
    nodes,
    validationErrors,
  );
  final rawCount = _validateComponentRawMappings(
    repositoryRoot,
    loadedContract,
    tokenSource,
    validationErrors,
  );
  if (cssMappings.isNotEmpty) {
    _validateCssCompatibility(
      repositoryRoot,
      tokenSource,
      cssMappings,
      validationErrors,
    );
  }

  final version =
      _valueAtPath(tokenSource, 'metadata.contract_version')?.toString() ??
      _valueAtPath(loadedContract, 'metadata.contract_version')?.toString() ??
      'unknown';
  if (nodes.isEmpty) {
    return null;
  }
  return BlabTokenModel(
    version: version,
    sourcePath: sourcePath,
    nodes: nodes,
    cssMappings: cssMappings,
    dartMappingCount: dartCount,
    componentRawValueCount: rawCount,
  );
}

Map<String, BlabTokenNode> _parseTokenNodes(
  YamlMap source,
  List<String> errors,
) {
  final tokens = source['tokens'];
  if (tokens is! Map) {
    errors.add('tokens must be a mapping.');
    return {};
  }

  final nodes = <String, BlabTokenNode>{};
  for (final layer in ['primitives', 'semantics', 'components']) {
    final rawNodes = tokens[layer];
    if (rawNodes is! List) {
      errors.add('tokens.$layer must be a list.');
      continue;
    }
    for (final rawNode in rawNodes) {
      if (rawNode is! Map) {
        errors.add('Every tokens.$layer entry must be a mapping.');
        continue;
      }
      final id = rawNode['id'];
      final type = rawNode['type'];
      if (id is! String || id.isEmpty || type is! String || type.isEmpty) {
        errors.add('Every tokens.$layer entry needs non-empty id and type.');
        continue;
      }
      if (!id.startsWith(_layerPrefix(layer))) {
        errors.add('Token $id must use the ${_layerPrefix(layer)} prefix.');
      }
      if (!_supportedTokenTypes.contains(type)) {
        errors.add('Unsupported token type for $id: $type');
      }
      if (nodes.containsKey(id)) {
        errors.add('Duplicate token id: $id');
        continue;
      }

      final value = rawNode['value'];
      final rawModes = rawNode['modes'];
      final modes = <String, Object?>{};
      if (rawModes is Map) {
        for (final entry in rawModes.entries) {
          if (entry.key is! String) {
            errors.add('Token $id has a non-string mode.');
            continue;
          }
          modes[entry.key as String] = entry.value;
        }
        final missingModes = _requiredModes.difference(modes.keys.toSet());
        if (missingModes.isNotEmpty) {
          errors.add(
            'Token $id is missing modes: ${missingModes.toList()..sort()}',
          );
        }
        final unknownModes = modes.keys.toSet().difference(_requiredModes);
        if (unknownModes.isNotEmpty) {
          errors.add(
            'Token $id has unsupported modes: ${unknownModes.toList()..sort()}',
          );
        }
      }
      if (value == null && modes.isEmpty) {
        errors.add('Token $id needs value or modes.');
      }
      if (value != null && modes.isNotEmpty) {
        errors.add('Token $id cannot define both value and modes.');
      }
      nodes[id] = BlabTokenNode(
        id: id,
        layer: layer,
        type: type,
        value: value,
        modes: modes,
      );
    }
  }
  return nodes;
}

String _layerPrefix(String layer) {
  return switch (layer) {
    'primitives' => 'primitive.',
    'semantics' => 'semantic.',
    'components' => 'component.',
    _ => '',
  };
}

void _validateTokenLiteralsAndReferenceTypes(
  Map<String, BlabTokenNode> nodes,
  List<String> errors,
) {
  final reportedTypeMismatches = <String>{};
  for (final node in nodes.values) {
    for (final value in [node.value, ...node.modes.values]) {
      if (value == null) {
        continue;
      }
      final text = value.toString();
      final referenceMatch = _tokenReference.firstMatch(text);
      if (referenceMatch != null) {
        final reference = referenceMatch.group(1)!;
        final target = nodes[reference];
        if (target != null &&
            !_tokenReferenceTypesAreCompatible(node.type, target.type)) {
          final error =
              'Token reference type mismatch from ${node.id} (${node.type}) '
              'to $reference (${target.type})';
          if (reportedTypeMismatches.add(error)) {
            errors.add(error);
          }
        }
        continue;
      }

      final valid = switch (node.type) {
        'color' => _colorLiteral.hasMatch(text),
        'color-or-none' => text == 'none' || _colorLiteral.hasMatch(text),
        'dimension' => _dimensionLiteral.hasMatch(text),
        'percentage' => _percentageLiteral.hasMatch(text),
        'shadow-or-none' => text == 'none' || _isValidShadowLiteral(text),
        _ => true,
      };
      if (!valid) {
        errors.add('Invalid ${node.type} literal for ${node.id}: $text');
      }
    }
  }
}

bool _isValidShadowLiteral(String value) {
  final match = _shadowLiteral.firstMatch(value);
  if (match == null) {
    return false;
  }
  final horizontal = double.parse(match.group(1)!);
  if (horizontal != 0 && match.group(2) == null) {
    return false;
  }
  for (final group in [5, 6, 7]) {
    if (int.parse(match.group(group)!) > 255) {
      return false;
    }
  }
  return double.parse(match.group(8)!) <= 1;
}

bool _tokenReferenceTypesAreCompatible(String sourceType, String targetType) {
  return sourceType == targetType ||
      (sourceType == 'color-or-none' && targetType == 'color');
}

void _validateTokenReferencesAndCycles(
  Map<String, BlabTokenNode> nodes,
  List<String> errors,
) {
  for (final node in nodes.values) {
    for (final value in [node.value, ...node.modes.values]) {
      if (value == null) {
        continue;
      }
      final match = _tokenReference.firstMatch(value.toString());
      if (match == null) {
        continue;
      }
      final reference = match.group(1)!;
      if (!nodes.containsKey(reference)) {
        errors.add('Missing token reference from ${node.id}: $reference');
      }
    }
  }

  final reportedCycles = <String>{};
  void visit(String id, String mode, List<String> stack) {
    final cycleIndex = stack.indexOf(id);
    if (cycleIndex != -1) {
      final cycleNodes = [...stack.sublist(cycleIndex), id];
      final cycle = cycleNodes.join(' -> ');
      final canonical = _canonicalCycle(cycleNodes);
      if (reportedCycles.add(canonical)) {
        errors.add('Token reference cycle: $cycle');
      }
      return;
    }
    final node = nodes[id];
    if (node == null) {
      return;
    }
    final raw = node.modes.isEmpty ? node.value : node.modes[mode];
    final match = raw == null
        ? null
        : _tokenReference.firstMatch(raw.toString());
    if (match != null) {
      visit(match.group(1)!, mode, [...stack, id]);
    }
  }

  final sortedIds = nodes.keys.toList()..sort();
  for (final mode in _requiredModes.toList()..sort()) {
    for (final id in sortedIds) {
      visit(id, mode, const []);
    }
  }
}

String _canonicalCycle(List<String> cycle) {
  final withoutRepeat = cycle.sublist(0, cycle.length - 1);
  final rotations = <String>[];
  for (var index = 0; index < withoutRepeat.length; index += 1) {
    final rotation = [
      ...withoutRepeat.sublist(index),
      ...withoutRepeat.sublist(0, index),
    ];
    rotations.add(rotation.join('|'));
  }
  rotations.sort();
  return rotations.first;
}

List<BlabCssMapping> _parseCssMappings(
  YamlMap source,
  Map<String, BlabTokenNode> nodes,
  List<String> errors,
) {
  final entries = _valueAtPath(source, 'legacy_mappings.css.entries');
  if (entries == null) {
    return const [];
  }
  if (entries is! List || entries.isEmpty) {
    errors.add('legacy_mappings.css.entries must be a non-empty list.');
    return const [];
  }

  final mappings = <BlabCssMapping>[];
  final seenNames = <String>{};
  for (final entry in entries) {
    if (entry is! Map) {
      errors.add('Every legacy CSS mapping must be a mapping.');
      continue;
    }
    final name = entry['name'];
    final type = entry['type'];
    final light = entry['light'];
    final classification = entry['classification'];
    final deprecation = entry['deprecation'];
    if (name is! String ||
        !name.startsWith('--blab-') ||
        type is! String ||
        light is! String ||
        classification is! String ||
        deprecation is! String) {
      errors.add(
        'Every legacy CSS mapping needs name, type, light, classification, '
        'and deprecation strings.',
      );
      continue;
    }
    if (!seenNames.add(name)) {
      errors.add('Duplicate legacy CSS name: $name');
    }
    final token = entry['token'];
    _validateLegacyClassification(
      kind: 'CSS',
      identifier: name,
      classification: classification,
      deprecation: deprecation,
      token: token,
      errors: errors,
    );
    if (token != null && (token is! String || !nodes.containsKey(token))) {
      errors.add('Legacy CSS mapping $name has missing token: $token');
    }
    mappings.add(
      BlabCssMapping(
        name: name,
        type: type,
        light: light,
        dark: entry['dark'] as String?,
        token: token as String?,
        classification: classification,
        deprecation: deprecation,
      ),
    );
  }
  mappings.sort((left, right) => left.name.compareTo(right.name));
  return mappings;
}

void _validateCssCompatibility(
  Directory repositoryRoot,
  YamlMap source,
  List<BlabCssMapping> mappings,
  List<String> errors,
) {
  final sourcePath = _valueAtPath(source, 'legacy_mappings.css.source');
  if (sourcePath is! String) {
    errors.add('legacy_mappings.css.source must be a string.');
    return;
  }
  final sourceFile = _containedFile(
    repositoryRoot,
    sourcePath,
    errors,
    label: 'Legacy CSS source',
  );
  if (sourceFile == null) {
    return;
  }

  final observed = <String, List<String>>{};
  final pattern = RegExp(r'(--blab-[a-z0-9-]+)\s*:\s*([^;]+);');
  for (final match in pattern.allMatches(sourceFile.readAsStringSync())) {
    observed
        .putIfAbsent(match.group(1)!, () => <String>[])
        .add(match.group(2)!.trim());
  }
  final declared = {for (final mapping in mappings) mapping.name: mapping};
  for (final name in observed.keys.toSet().difference(declared.keys.toSet())) {
    errors.add('Unclassified legacy CSS token: $name');
  }
  for (final name in declared.keys.toSet().difference(observed.keys.toSet())) {
    errors.add('Legacy CSS mapping is not present in $sourcePath: $name');
  }
  for (final entry in observed.entries) {
    final mapping = declared[entry.key];
    if (mapping == null) {
      continue;
    }
    final expected = [mapping.light, if (mapping.dark != null) mapping.dark!];
    if (!_sameOrderedValues(entry.value, expected)) {
      errors.add(
        'Legacy CSS value drift for ${entry.key}: expected $expected, '
        'found ${entry.value}.',
      );
    }
  }
}

bool _sameOrderedValues(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

int _validateDartMappings(
  Directory repositoryRoot,
  YamlMap source,
  Map<String, BlabTokenNode> nodes,
  List<String> errors,
) {
  final sources = _valueAtPath(source, 'legacy_mappings.dart.sources');
  if (sources == null) {
    return 0;
  }
  if (sources is! List || sources.isEmpty) {
    errors.add('legacy_mappings.dart.sources must be a non-empty list.');
    return 0;
  }
  var count = 0;
  final seenSymbols = <String>{};
  for (final rawSource in sources) {
    if (rawSource is! Map ||
        rawSource['path'] is! String ||
        rawSource['symbols'] is! List) {
      errors.add('Every legacy Dart source needs path and symbols.');
      continue;
    }
    final path = rawSource['path'] as String;
    final file = _containedFile(
      repositoryRoot,
      path,
      errors,
      label: 'Legacy Dart source',
    );
    if (file == null) {
      continue;
    }
    final sourceText = file.readAsStringSync();
    final declaredNames = <String>{};
    for (final rawSymbol in rawSource['symbols'] as List) {
      if (rawSymbol is! Map ||
          rawSymbol['symbol'] is! String ||
          rawSymbol['classification'] is! String ||
          rawSymbol['deprecation'] is! String) {
        errors.add(
          'Every legacy Dart symbol needs symbol, classification, and '
          'deprecation.',
        );
        continue;
      }
      final symbol = rawSymbol['symbol'] as String;
      final classification = rawSymbol['classification'] as String;
      final deprecation = rawSymbol['deprecation'] as String;
      count += 1;
      if (!seenSymbols.add(symbol)) {
        errors.add('Duplicate legacy Dart symbol: $symbol');
      }
      declaredNames.add(symbol.split('.').last);
      final token = rawSymbol['token'];
      _validateLegacyClassification(
        kind: 'Dart',
        identifier: symbol,
        classification: classification,
        deprecation: deprecation,
        token: token,
        errors: errors,
      );
      if (token != null && (token is! String || !nodes.containsKey(token))) {
        errors.add('Legacy Dart symbol $symbol has missing token: $token');
      }
      if (classification == 'mapped' &&
          token is String &&
          nodes.containsKey(token)) {
        _validateMappedDartValue(
          path: path,
          source: sourceText,
          symbol: symbol,
          token: token,
          nodes: nodes,
          errors: errors,
        );
      }
    }

    final observedNames = _publicStaticNames(sourceText);
    for (final name in observedNames.difference(declaredNames)) {
      errors.add('Unclassified legacy Dart symbol in $path: $name');
    }
    for (final name in declaredNames.difference(observedNames)) {
      errors.add('Legacy Dart symbol mapping is not present in $path: $name');
    }
  }
  return count;
}

void _validateMappedDartValue({
  required String path,
  required String source,
  required String symbol,
  required String token,
  required Map<String, BlabTokenNode> nodes,
  required List<String> errors,
}) {
  final observed = _extractMappedDartValues(path, source, symbol);
  if (observed == null || observed.isEmpty) {
    errors.add('Could not extract mapped legacy Dart value for $symbol.');
    return;
  }
  for (final entry in observed.entries) {
    final expected = _resolveNodeValue(nodes, token, entry.key);
    if (expected != entry.value) {
      errors.add(
        'Legacy Dart mapped value drift for $symbol (${entry.key}): '
        'expected $expected, found ${entry.value}',
      );
    }
  }
}

Map<String, String>? _extractMappedDartValues(
  String path,
  String source,
  String symbol,
) {
  final name = symbol.split('.').last;
  if (path.endsWith('/app_colors.dart')) {
    final colors = _extractColorConstants(source);
    final conditional = _extractConditionalMembers(source, name);
    if (conditional != null) {
      final dark = colors[conditional.$1];
      final light = colors[conditional.$2];
      if (light == null || dark == null) {
        return null;
      }
      return {'light': light, 'dark': dark};
    }
    final value = colors[name];
    if (value == null) {
      return null;
    }
    if (name.endsWith('Light')) {
      return {'light': value};
    }
    if (name.endsWith('Dark')) {
      return {'dark': value};
    }
    return {'light': value, 'dark': value};
  }

  if (path.endsWith('/app_glass.dart')) {
    if (name == 'blur') {
      final value = _extractStaticNumber(source, name);
      if (value == null) {
        return null;
      }
      final normalized = '${_compactNumber(value)}px';
      return {'light': normalized, 'dark': normalized};
    }
    if (name == 'saturation') {
      final value = _extractStaticNumber(source, name);
      if (value == null) {
        return null;
      }
      final normalized = '${_compactNumber(value * 100)}%';
      return {'light': normalized, 'dark': normalized};
    }
    final colors = _extractColorConstants(source);
    final conditional = _extractConditionalMembers(source, name);
    if (conditional == null) {
      return null;
    }
    final dark = colors[conditional.$1];
    final light = colors[conditional.$2];
    if (light == null || dark == null) {
      return null;
    }
    return {'light': light, 'dark': dark};
  }

  if (path.endsWith('/app_shadow.dart') && name == 'float') {
    final light = _extractBoxShadow(source, '_lightFloat');
    final dark = _extractBoxShadow(source, '_darkFloat');
    if (light == null || dark == null) {
      return null;
    }
    return {'light': light, 'dark': dark};
  }
  return null;
}

Map<String, String> _extractColorConstants(String source) {
  final expressions = <String, String>{};
  final pattern = RegExp(
    r'static\s+const\s+Color\s+(_?[A-Za-z][A-Za-z0-9_]*)\s*=\s*([^;]+);',
  );
  for (final match in pattern.allMatches(source)) {
    expressions[match.group(1)!] = match.group(2)!.trim();
  }

  final resolved = <String, String>{};
  String? resolve(String name, Set<String> stack) {
    if (resolved[name] case final value?) {
      return value;
    }
    if (!stack.add(name)) {
      return null;
    }
    final expression = expressions[name];
    if (expression == null) {
      return null;
    }
    final literal = _normalizeDartColor(expression);
    final value = literal ?? resolve(expression, stack);
    if (value != null) {
      resolved[name] = value;
    }
    stack.remove(name);
    return value;
  }

  for (final name in expressions.keys) {
    resolve(name, <String>{});
  }
  return resolved;
}

String? _normalizeDartColor(String expression) {
  final normalized = expression.replaceAll(RegExp(r'\s+'), '');
  if (normalized == 'Colors.white') {
    return '#FFFFFF';
  }
  if (normalized == 'Colors.black') {
    return '#000000';
  }
  final match = RegExp(
    r'^(?:const)?Color\(0x([0-9A-Fa-f]{8})\)$',
  ).firstMatch(normalized);
  if (match == null) {
    return null;
  }
  final argb = match.group(1)!.toUpperCase();
  return argb.startsWith('FF') ? '#${argb.substring(2)}' : '#$argb';
}

(String, String)? _extractConditionalMembers(String source, String name) {
  final match = RegExp(
    'static\\s+[^\\n{]+\\s+$name\\s*\\([^)]*\\)\\s*\\{.*?'
    r'\?\s*(_?[A-Za-z][A-Za-z0-9_]*)\s*'
    r':\s*(_?[A-Za-z][A-Za-z0-9_]*)\s*;',
    dotAll: true,
  ).firstMatch(source);
  return match == null ? null : (match.group(1)!, match.group(2)!);
}

double? _extractStaticNumber(String source, String name) {
  final match = RegExp(
    'static\\s+const\\s+(?:double|num|int)\\s+$name\\s*=\\s*'
    r'(-?(?:\d+(?:\.\d+)?|\.\d+))\s*;',
  ).firstMatch(source);
  return match == null ? null : double.parse(match.group(1)!);
}

String _compactNumber(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

String? _extractBoxShadow(String source, String privateName) {
  final match = RegExp(
    'static\\s+const\\s+List<BoxShadow>\\s+$privateName\\s*=\\s*\\['
    r'.*?offset:\s*Offset\(\s*(-?(?:\d+(?:\.\d+)?|\.\d+))\s*,\s*'
    r'(-?(?:\d+(?:\.\d+)?|\.\d+))\s*\).*?'
    r'blurRadius:\s*(-?(?:\d+(?:\.\d+)?|\.\d+)).*?'
    r'color:\s*(?:const\s+)?Color\(0x([0-9A-Fa-f]{8})\)',
    dotAll: true,
  ).firstMatch(source);
  if (match == null) {
    return null;
  }
  final x = _compactNumber(double.parse(match.group(1)!));
  final y = _compactNumber(double.parse(match.group(2)!));
  final blur = _compactNumber(double.parse(match.group(3)!));
  final argb = match.group(4)!;
  final alpha = int.parse(argb.substring(0, 2), radix: 16) / 255;
  final red = int.parse(argb.substring(2, 4), radix: 16);
  final green = int.parse(argb.substring(4, 6), radix: 16);
  final blue = int.parse(argb.substring(6, 8), radix: 16);
  final alphaText = (alpha * 100).round() / 100;
  return '$x ${y}px ${blur}px '
      'rgba($red,$green,$blue,${_compactNumber(alphaText)})';
}

String _resolveNodeValue(
  Map<String, BlabTokenNode> nodes,
  String id,
  String mode, [
  Set<String>? stack,
]) {
  final visited = stack ?? <String>{};
  if (!visited.add(id)) {
    return '';
  }
  final node = nodes[id];
  if (node == null) {
    return '';
  }
  final raw = node.modes.isEmpty ? node.value : node.modes[mode];
  final text = raw?.toString() ?? '';
  final reference = _tokenReference.firstMatch(text);
  return reference == null
      ? text
      : _resolveNodeValue(nodes, reference.group(1)!, mode, visited);
}

Set<String> _publicStaticNames(String source) {
  final names = <String>{};
  final patterns = [
    RegExp(
      r'^\s*static\s+(?:const\s+)?[^\n=]+?\s+([A-Za-z][A-Za-z0-9_]*)\s*=',
      multiLine: true,
    ),
    RegExp(
      r'^\s*static\s+[^\n]+?\s+get\s+([A-Za-z][A-Za-z0-9_]*)\s*=>',
      multiLine: true,
    ),
    RegExp(
      r'^\s*static\s+[^\n(=]+?\s+([A-Za-z][A-Za-z0-9_]*)\s*\(',
      multiLine: true,
    ),
  ];
  for (final pattern in patterns) {
    for (final match in pattern.allMatches(source)) {
      names.add(match.group(1)!);
    }
  }
  return names;
}

int _validateComponentRawMappings(
  Directory repositoryRoot,
  YamlMap contract,
  YamlMap source,
  List<String> errors,
) {
  final mappings = _valueAtPath(source, 'legacy_mappings.component_raw_values');
  if (mappings == null) {
    return 0;
  }
  if (mappings is! List || mappings.isEmpty) {
    errors.add(
      'legacy_mappings.component_raw_values must be a non-empty list.',
    );
    return 0;
  }
  var count = 0;
  final seenPaths = <String>{};
  for (final mapping in mappings) {
    if (mapping is! Map ||
        mapping['path'] is! String ||
        mapping['classification'] is! String ||
        mapping['deprecation'] is! String ||
        mapping['extraction'] is! String ||
        mapping['raw_values'] is! List) {
      errors.add(
        'Every raw component mapping needs path, classification, '
        'deprecation, extraction, and raw_values.',
      );
      continue;
    }
    final path = mapping['path'] as String;
    if (mapping['extraction'] != 'dart-numeric-and-color-literals/v1') {
      errors.add(
        'Unsupported component raw-value extraction for $path: '
        '${mapping['extraction']}',
      );
    }
    _validateLegacyClassification(
      kind: 'component raw-value',
      identifier: path,
      classification: mapping['classification'] as String,
      deprecation: mapping['deprecation'] as String,
      token: null,
      errors: errors,
    );
    if (!seenPaths.add(path)) {
      errors.add('Duplicate raw component mapping path: $path');
    }
    final file = _containedFile(
      repositoryRoot,
      path,
      errors,
      label: 'Raw component source',
    );
    final rawValues = mapping['raw_values'] as List;
    if (rawValues.isEmpty || rawValues.any((value) => value is! String)) {
      errors.add('Raw component values for $path must be non-empty strings.');
    } else if (file != null) {
      final declared = rawValues.cast<String>();
      final observed = extractComponentRawValues(file.readAsStringSync());
      if (!_sameOrderedValues(declared, observed)) {
        errors.add(
          'Component raw-value drift for $path: expected source extraction '
          '$observed, found declaration $declared.',
        );
      }
    }
    count += rawValues.length;
  }

  final expectedPaths =
      (_valueAtPath(
                contract,
                'values.token_layers.component.current_value_refs',
              )
              as List?)
          ?.whereType<String>()
          .toSet();
  if (expectedPaths != null) {
    for (final path in expectedPaths.difference(seenPaths)) {
      errors.add('Unclassified component raw-value source: $path');
    }
    for (final path in seenPaths.difference(expectedPaths)) {
      errors.add('Unexpected component raw-value source: $path');
    }
  }
  return count;
}

List<String> extractComponentRawValues(String source) {
  final result = parseString(content: source, throwIfDiagnostics: false);
  final visitor = _ComponentRawValueVisitor(result.lineInfo);
  result.unit.accept(visitor);
  return visitor.values;
}

class _ComponentRawValueVisitor extends GeneralizingAstVisitor<void> {
  _ComponentRawValueVisitor(this.lineInfo);

  final LineInfo lineInfo;
  final List<String> values = [];

  void _record(AstNode node) {
    final location = lineInfo.getLocation(node.offset);
    values.add(
      '${location.lineNumber}:${location.columnNumber}:${node.toSource()}',
    );
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.toSource() == 'Color') {
      _record(node);
      return;
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.toSource().startsWith('Colors.')) {
      _record(node);
      return;
    }
    super.visitIndexExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.toSource().startsWith('Colors.')) {
      _record(node);
      return;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'Colors') {
      _record(node);
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme == '-' &&
        (node.operand is IntegerLiteral || node.operand is DoubleLiteral)) {
      _record(node);
      return;
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _record(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _record(node);
  }
}

void _validateLegacyClassification({
  required String kind,
  required String identifier,
  required String classification,
  required String deprecation,
  required Object? token,
  required List<String> errors,
}) {
  final allowedClassifications = kind == 'component raw-value'
      ? const {'component-local-raw', 'compatibility-correction'}
      : _legacyMappingClassifications;
  if (!allowedClassifications.contains(classification)) {
    errors.add(
      'Unsupported legacy $kind classification for $identifier: '
      '$classification',
    );
    return;
  }
  if (!_legacyDeprecations.contains(deprecation)) {
    errors.add(
      'Unsupported legacy $kind deprecation for $identifier: $deprecation',
    );
  }

  final allowedDeprecations = switch (classification) {
    'legacy-retained' => const {'legacy-retained', 'deprecated'},
    'component-local-raw' => const {'legacy-retained'},
    _ => const {'none'},
  };
  if (!allowedDeprecations.contains(deprecation)) {
    errors.add(
      'Legacy $kind $identifier classification $classification requires '
      'deprecation ${allowedDeprecations.join(' or ')}, found $deprecation',
    );
  }
  if (classification == 'mapped' && token == null) {
    errors.add('Mapped legacy $kind $identifier must declare a token.');
  }
  if (classification != 'mapped' && token != null) {
    errors.add('Non-mapped legacy $kind $identifier must not declare a token.');
  }
}

void _validateLocalization(
  Directory repositoryRoot,
  YamlMap contract,
  List<String> errors,
) {
  final glossaryRef = _valueAtPath(contract, 'localization.glossary_ref');
  if (glossaryRef is! String) {
    return;
  }
  final glossaryFile = _containedFile(
    repositoryRoot,
    glossaryRef,
    errors,
    label: 'Glossary source',
  );
  if (glossaryFile == null) {
    return;
  }
  final glossary = _loadYamlMap(glossaryFile, errors);
  if (glossary == null) {
    return;
  }
  if (glossary['schema'] != 'blab.glossary/v1') {
    errors.add('Unsupported Blab glossary schema: ${glossary['schema']}');
  }
  _validateGlossaryManifest(glossary, glossaryRef, errors);
}

void _validateGlossaryManifest(
  YamlMap glossary,
  String glossaryRef,
  List<String> errors,
) {
  final metadata = glossary['metadata'];
  if (metadata is! Map ||
      metadata['version'] is! String ||
      metadata['owner'] != 'byungskerlab-design-team') {
    errors.add(
      '$glossaryRef metadata must declare a version and Design owner.',
    );
  }
  final terms = glossary['terms'];
  _validateUniqueIds(terms, '$glossaryRef terms', errors);
  if (terms is! List || terms.isEmpty) {
    errors.add('$glossaryRef terms must be a non-empty list.');
    return;
  }
  for (final term in terms) {
    if (term is! Map ||
        term['id'] is! String ||
        term['canonical'] is! String ||
        term['usage'] is! String) {
      errors.add(
        'Every $glossaryRef term needs string id, canonical, and usage.',
      );
    }
  }
}

void _validateCapabilities(
  Directory repositoryRoot,
  YamlMap contract,
  List<String> errors,
) {
  final capabilities = contract['capabilities'];
  if (capabilities is! Map) {
    return;
  }
  final phaseStatus = capabilities['phase_status'];
  final phaseTwoStatus = phaseStatus is Map ? phaseStatus['phase-2'] : null;
  final implementationEvidence = _valueAtPath(
    contract,
    'accessibility.implementation_evidence',
  );
  if (phaseTwoStatus is String && implementationEvidence != phaseTwoStatus) {
    errors.add(
      'accessibility.implementation_evidence must match '
      'capabilities.phase_status.phase-2 ($phaseTwoStatus), but was '
      '$implementationEvidence.',
    );
  }
  final entries = capabilities['entries'];
  _validateUniqueIds(entries, '$contractPath capabilities', errors);
  if (entries is! List || entries.isEmpty) {
    errors.add('$contractPath capabilities must be a non-empty list.');
    return;
  }
  const allowedStatuses = <String>{
    'implemented-contract-only',
    'implemented-local',
    'implemented-local-family-partial',
    'implemented-local-no-remote-mutation',
    'local-preparation-implemented-exit-blocked',
    'not-started',
  };
  const canonicalPhases = <String, int>{
    'button-component-state-implementation': 3,
    'keyboard-accessory-component-state-implementation': 3,
    'migration-and-release': 5,
    'segmented-control-component-state-implementation': 3,
    'snackbar-component-state-implementation': 3,
    'tab-bar-component-state-implementation': 3,
    'text-field-component-state-implementation': 3,
    'visual-baseline-images': 4,
  };
  final observedIds = <String>[];
  for (final entry in entries) {
    if (entry is! Map) {
      continue;
    }
    final id = entry['id'];
    final phase = entry['phase'];
    final status = entry['status'];
    final evidence = entry['evidence'];
    if (id is! String ||
        id.isEmpty ||
        phase is! int ||
        phase < 1 ||
        phase > 5 ||
        status is! String ||
        evidence is! List) {
      errors.add(
        'Every capability needs non-empty id, phase 1-5, status, and '
        'evidence list.',
      );
      continue;
    }
    observedIds.add(id);
    if (!allowedStatuses.contains(status)) {
      errors.add('Unsupported capability status for $id: $status');
    }
    final canonicalPhase = canonicalPhases[id];
    if (canonicalPhase != null && phase != canonicalPhase) {
      errors.add(
        'Capability $id must be routed to Phase $canonicalPhase, but was '
        'Phase $phase.',
      );
    }
    if (status == 'not-started' && evidence.isNotEmpty) {
      errors.add('Not-started capability $id must not claim evidence.');
    }
    if (status != 'not-started' && evidence.isEmpty) {
      errors.add('Implemented capability $id must declare evidence.');
    }
    if (id == 'button-component-state-implementation') {
      final scope = entry['scope'];
      if (status != 'implemented-local-family-partial' ||
          scope is! Map ||
          scope['component_family'] != 'button' ||
          scope['public_type'] != 'BLabButton' ||
          scope['global_capability_complete'] != false ||
          scope['loading_busy_claimed'] != false) {
        errors.add(
          'Capability $id must remain an explicit partial Button-family '
          'claim with global and loading/busy completion false.',
        );
      }
    }
    if (id == 'migration-and-release') {
      final scope = entry['scope'];
      const requiredEvidence = <String>{
        'docs/BLDS_PHASE_5_STATUS.md',
        'contracts/release/phase5-readiness.yaml',
        'tool/classify_compatibility.dart',
        'tool/rehearse_phase5_migration.dart',
        'contracts/legal/rights-provenance.yaml',
      };
      final evidencePaths = evidence.whereType<String>().toSet();
      if (status != 'local-preparation-implemented-exit-blocked' ||
          scope is! Map ||
          scope['compatibility_classifier_implemented'] != true ||
          scope['migration_rehearsal_implemented'] != true ||
          scope['rights_preparation_implemented'] != true ||
          scope['phase5_exit_complete'] != false ||
          scope['conformance_claimed'] != false ||
          scope['release_authorized'] != false ||
          scope['publication_authorized'] != false ||
          !evidencePaths.containsAll(requiredEvidence)) {
        errors.add(
          'Capability $id must remain bounded to implemented local '
          'preparation with Phase 5 exit, conformance, release, and '
          'publication claims false and complete evidence references.',
        );
      }
    }
    if (id == 'text-field-component-state-implementation') {
      final scope = entry['scope'];
      if (status != 'implemented-local-family-partial' ||
          scope is! Map ||
          scope['component_family'] != 'text-field' ||
          scope['public_type'] != 'BLabTextField' ||
          scope['global_capability_complete'] != false ||
          scope['required_claimed'] != true ||
          scope['loading_claimed'] != false) {
        errors.add(
          'Capability $id must remain an explicit partial TextField-family '
          'claim with required evidence true and global/loading completion '
          'false.',
        );
      }
    }
    if (id == 'segmented-control-component-state-implementation') {
      final scope = entry['scope'];
      if (status != 'implemented-local-family-partial' ||
          scope is! Map ||
          scope['component_family'] != 'segmented-control' ||
          scope['public_type'] != 'BLabSegmentedControl' ||
          scope['global_capability_complete'] != false ||
          scope['required_claimed'] != true ||
          scope['unsupported_claimed'] != false) {
        errors.add(
          'Capability $id must remain an explicit partial '
          'SegmentedControl-family claim with required evidence true and '
          'global/unsupported completion false.',
        );
      }
    }
    if (id == 'snackbar-component-state-implementation') {
      final scope = entry['scope'];
      if (status != 'implemented-local-family-partial' ||
          scope is! Map ||
          scope['component_family'] != 'snackbar' ||
          scope['public_type'] != 'BLabSnackbar' ||
          scope['global_capability_complete'] != false ||
          scope['required_claimed'] != true ||
          scope['unsupported_claimed'] != false) {
        errors.add(
          'Capability $id must remain an explicit partial Snackbar-family '
          'claim with required evidence true and global/unsupported '
          'completion false.',
        );
      }
    }
    if (id == 'keyboard-accessory-component-state-implementation') {
      final scope = entry['scope'];
      if (status != 'implemented-local-family-partial' ||
          scope is! Map ||
          scope['component_family'] != 'keyboard-accessory-bar' ||
          scope['public_type'] != 'BLabKeyboardAccessoryBar' ||
          scope['global_capability_complete'] != false ||
          scope['required_claimed'] != true ||
          scope['unsupported_claimed'] != false) {
        errors.add(
          'Capability $id must remain an explicit partial '
          'KeyboardAccessoryBar-family claim with required evidence true and '
          'global/unsupported completion false.',
        );
      }
    }
    if (id == 'tab-bar-component-state-implementation') {
      final scope = entry['scope'];
      if (status != 'implemented-local-family-partial' ||
          scope is! Map ||
          scope['component_family'] != 'tab-bar' ||
          scope['public_type'] != 'BLabTabBar' ||
          scope['global_capability_complete'] != false ||
          scope['required_claimed'] != true ||
          scope['disabled_claimed'] != false ||
          scope['unsupported_claimed'] != false) {
        errors.add(
          'Capability $id must remain an explicit partial TabBar-family '
          'claim with required evidence true and global/disabled/unsupported '
          'completion false.',
        );
      }
    }
    for (final rawPath in evidence) {
      if (rawPath is! String || rawPath.isEmpty) {
        errors.add('Capability $id evidence must contain non-empty paths.');
        continue;
      }
      if (!_validateSafePath(
        repositoryRoot,
        rawPath,
        errors,
        label: 'Capability $id evidence',
      )) {
        continue;
      }
      if (!rawPath.startsWith('generated/') &&
          !File('${repositoryRoot.path}/$rawPath').existsSync()) {
        errors.add('Capability $id evidence does not exist: $rawPath');
      }
    }
  }
  final sortedIds = [...observedIds]..sort();
  if (!_sameOrderedValues(observedIds, sortedIds)) {
    errors.add('Capability entries must be ordered lexicographically by id.');
  }
}

void _validateTabBarDecision(
  Directory repositoryRoot,
  YamlMap contract,
  BlabTokenModel model,
  List<String> errors,
) {
  final decision = _valueAtPath(contract, 'component_decisions.tab-bar');
  if (decision is! Map) return;

  const expectedPrecedence = <String>[
    'keyboard-visible-focus',
    'pressed',
    'hover',
    'selected-current',
    'unselected',
    'default',
  ];
  final precedence = decision['precedence'];
  if (precedence is! List ||
      !_sameOrderedValues(
        precedence.whereType<String>().toList(),
        expectedPrecedence,
      )) {
    errors.add(
      'TabBar precedence must remain '
      '${expectedPrecedence.join(' > ')}.',
    );
  }

  const expectedUnsupported = <String>[
    'disabled',
    'loading',
    'busy',
    'invalid',
    'error',
    'expanded',
    'disclosure',
    'drag-selection',
    'haptic',
    'bottom-bar',
  ];
  final unsupported = decision['unsupported_not_simulated'];
  if (unsupported is! List ||
      !_sameOrderedValues(
        unsupported.whereType<String>().toList(),
        expectedUnsupported,
      )) {
    errors.add('TabBar unsupported states must remain explicit and unclaimed.');
  }

  final decisionDocument = decision['decision_document'];
  if (decision['decision_ref'] !=
          'BLDS-PHASE3-NAVIGATION-TABBAR-DESIGN-DECISION-2026-07-26' ||
      decisionDocument != 'docs/BLDS_PHASE_3_TAB_BAR_DESIGN_DECISION.md') {
    errors.add(
      'TabBar decision must cite the exact approved packet and durable '
      'document.',
    );
  } else {
    _containedFile(
      repositoryRoot,
      decisionDocument as String,
      errors,
      label: 'TabBar Design decision',
    );
  }

  const expectedTokenModes = <String, List<String>>{
    'component.tab.container-surface': [
      '#00000000',
      '#00000000',
      '#00000000',
      '#00000000',
    ],
    'component.tab.selected-indicator': [
      '#000000',
      '#FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.tab.selected-foreground': [
      '#000000',
      '#FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.tab.unselected-foreground': [
      '#DD000000',
      '#DDFFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.tab.hover-overlay': [
      '#14000000',
      '#14FFFFFF',
      '#1F000000',
      '#1FFFFFFF',
    ],
    'component.tab.pressed-overlay': [
      '#1F000000',
      '#1FFFFFFF',
      '#33000000',
      '#33FFFFFF',
    ],
    'component.tab.focus-outline': ['#000000', '#FFFFFF', '#000000', '#FFFFFF'],
    'component.tab.focus-outer-ring': [
      '#5B7FFF',
      '#5B7FFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.tab.divider': [
      '#00000000',
      '#00000000',
      '#00000000',
      '#00000000',
    ],
  };
  const modes = <String>[
    'light',
    'dark',
    'high-contrast-light',
    'high-contrast-dark',
  ];
  for (final entry in expectedTokenModes.entries) {
    for (var index = 0; index < modes.length; index += 1) {
      final actual = model.resolve(entry.key, modes[index]);
      final expected = entry.value[index];
      if (actual != expected) {
        errors.add(
          'TabBar token drift for ${entry.key} ${modes[index]}: '
          'expected $expected, found $actual.',
        );
      }
    }
  }

  const exactValues = <String, Object>{
    'public_api.inheritance': 'StatelessWidget',
    'public_api.constructor_unchanged': true,
    'public_api.caller_owned_controller': true,
    'public_api.additive_api_allowed': false,
    'public_api.retained_defaults.indicator_weight_constraint':
        'greater-than-zero',
    'disabled.applicability': 'conditional-unmet',
    'disabled.simulated': false,
    'pointer.down': 'modality-and-pending-pressed-only',
    'pointer.confirmed_tap': 'roving-focus-pointer-focus-one-activation',
    'selection.authority': 'TabController.index',
    'selection.parent_semantics_role': 'SemanticsRole.tabBar',
    'selection.child_semantics_role': 'SemanticsRole.tab',
    'selection.generic_button_semantics': false,
    'selection.localized_label':
        'caller-label-merged-with-MaterialLocalizations.tabLabel',
    'selection.reactivation_callback_count': 1,
    'selection.external_controller_callback': false,
    'geometry.minimum_bar_height': 56,
    'geometry.minimum_interactive_target': '44x44',
    'geometry.indicator_default_height': 3,
    'geometry.divider_height_when_overridden': 1,
    'geometry.label_measurement': 'wrap-aware-at-actual-item-width',
    'geometry.app_bar_bottom':
        'preferred-height-unclipped-for-valid-two-times-labels',
    'focus.outline_width': 'semantic.focus.outline-width',
    'focus.outer_ring_width': 'semantic.focus.ring-width',
    'keyboard.focus_model': 'one-roving-tab-stop',
    'keyboard.vertical': 'up-down-not-consumed',
    'keyboard.navigation_callback': false,
    'overflow.condition': 'isScrollable-true-only',
    'overflow.controller': 'owned-non-primary-horizontal',
    'overflow.minimum_tab_width': 44,
    'overflow.rtl_reveal': 'arrow-home-end-and-external-physical-direction',
    'overflow.layout_change_tracking':
        'viewport-width-content-width-directionality-isScrollable',
    'overflow.layout_change_content_width':
        'every-change-including-selection-induced',
    'overflow.layout_change_selection': 'every-selected-index-change',
    'overflow.layout_change_target': 'internally-focused-else-current',
    'overflow.layout_change_reveal': 'immediate-post-layout',
    'overflow.layout_change_side_effects': 'no-focus-theft-callback-selection',
    'overflow.focus_ring_allowance': 0,
    'motion.selection_duration': 'BLabMotion.durSurface',
    'motion.label_style_inheritance': 'AnimatedDefaultTextStyle-child-inherits',
    'motion.midpoint_evidence_ms': 150,
    'motion.interaction_duration': 'BLabMotion.durPress',
    'motion.reveal_duration': 'BLabMotion.durPress',
    'contrast.normal_text_minimum': 4.5,
    'contrast.non_text_and_focus_minimum': 3.0,
    'contrast.transparent_arbitrary_background_claim': false,
    'contrast.custom_override_claim': false,
  };
  for (final entry in exactValues.entries) {
    final actual = _valueAtPath(decision, entry.key);
    if (actual != entry.value) {
      errors.add(
        'TabBar decision drift for ${entry.key}: '
        'expected ${entry.value}, found $actual.',
      );
    }
  }
}

void _validateBottomBarDecision(
  Directory repositoryRoot,
  YamlMap contract,
  BlabTokenModel model,
  List<String> errors,
) {
  final decision = _valueAtPath(contract, 'component_decisions.bottom-bar');
  if (decision is! Map) return;

  final decisionDocument = decision['decision_document'];
  if (decision['decision_ref'] !=
          'BLDS-PHASE3-NAVIGATION-BOTTOMBAR-DESIGN-DECISION-2026-07-26' ||
      decisionDocument != 'docs/BLDS_PHASE_3_BOTTOM_BAR_DESIGN_DECISION.md') {
    errors.add(
      'BottomBar decision must cite the exact approved packet and durable '
      'document.',
    );
  } else {
    _containedFile(
      repositoryRoot,
      decisionDocument as String,
      errors,
      label: 'BottomBar Design decision',
    );
  }

  const expectedTokenModes = <String, List<String>>{
    'component.bottom-bar.container-surface': [
      '#14000000',
      '#1FFFFFFF',
      '#FFFFFF',
      '#121212',
    ],
    'component.bottom-bar.container-border': [
      '#14000000',
      '#26FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.bottom-bar.selected-surface': [
      '#1F000000',
      '#38FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.bottom-bar.selected-highlight': [
      '#66FFFFFF',
      '#26FFFFFF',
      '#00000000',
      '#00000000',
    ],
    'component.bottom-bar.selected-foreground': [
      '#000000',
      '#FFFFFF',
      '#FFFFFF',
      '#000000',
    ],
    'component.bottom-bar.unselected-foreground': [
      '#DD000000',
      '#DDFFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.bottom-bar.hover-overlay': [
      '#14000000',
      '#14FFFFFF',
      '#1F000000',
      '#1FFFFFFF',
    ],
    'component.bottom-bar.pressed-overlay': [
      '#1F000000',
      '#1FFFFFFF',
      '#33000000',
      '#33FFFFFF',
    ],
    'component.bottom-bar.drag-overlay': [
      '#26000000',
      '#26FFFFFF',
      '#33000000',
      '#33FFFFFF',
    ],
    'component.bottom-bar.focus-outline': [
      '#000000',
      '#FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.bottom-bar.focus-outer-ring': [
      '#5B7FFF',
      '#5B7FFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.bottom-bar.action-surface': [
      '#14000000',
      '#1FFFFFFF',
      '#FFFFFF',
      '#121212',
    ],
    'component.bottom-bar.action-foreground': [
      '#000000',
      '#FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.bottom-bar.selected-shadow': [
      '#14000000',
      '#14000000',
      '#00000000',
      '#00000000',
    ],
  };
  const modes = <String>[
    'light',
    'dark',
    'high-contrast-light',
    'high-contrast-dark',
  ];
  for (final entry in expectedTokenModes.entries) {
    for (var index = 0; index < modes.length; index += 1) {
      final actual = model.resolve(entry.key, modes[index]);
      final expected = entry.value[index];
      if (actual != expected) {
        errors.add(
          'BottomBar token drift for ${entry.key} ${modes[index]}: '
          'expected $expected, found $actual.',
        );
      }
    }
  }

  const exactValues = <String, Object>{
    'public_api.inheritance': 'StatefulWidget',
    'public_api.legacy_constructor_source_compatible': true,
    'public_api.controlled_selected_index': true,
    'precedence.environment_modifiers': 'first',
    'precedence.selection': 'persistent',
    'precedence.focus': 'additive-does-not-erase-selection',
    'selection.authority': 'selectedIndex',
    'selection.reactivation_callback_count': 1,
    'selection.external_update_callback': false,
    'selection.parent_semantics_role': 'SemanticsRole.tabBar',
    'selection.child_semantics_role': 'SemanticsRole.tab',
    'selection.labels': 'caller-product-labels-only',
    'geometry.baseline_height': 62,
    'geometry.allocation': 'equal',
    'geometry.minimum_interactive_target': '44x44',
    'keyboard.focus_model': 'one-roving-tab-stop',
    'keyboard.selection_follows_focus': false,
    'keyboard.vertical': 'up-down-not-consumed',
    'drag.trigger': 'touch-long-press-only',
    'drag.rtl': 'logical-index-correct',
    'optional_action.conformant_condition':
        'onSearchTap-and-localized-actionSemanticLabel',
    'first_tab_chevron.conformant_condition':
        'callback-and-localized-label-and-expanded-state',
    'motion.selection_duration': 'BLabMotion.durSurface',
    'motion.interaction_duration': 'BLabMotion.durPress',
    'motion.reduced_motion': 'immediate',
    'haptic.policy': 'BLabHapticPolicy-default-deny',
    'haptic.unconditional_platform_calls': false,
    'high_contrast.surface': 'opaque',
    'high_contrast.blur': false,
    'high_contrast.gradient': false,
    'high_contrast.shadow': false,
    'conformance.family_partial': true,
    'conformance.repository_wide_claim': false,
    'conformance.device_conformance_claim': false,
  };
  for (final entry in exactValues.entries) {
    final actual = _valueAtPath(decision, entry.key);
    if (actual != entry.value) {
      errors.add(
        'BottomBar decision drift for ${entry.key}: '
        'expected ${entry.value}, found $actual.',
      );
    }
  }
}

void _validatePressableCardDecision(
  Directory repositoryRoot,
  YamlMap contract,
  BlabTokenModel model,
  List<String> errors,
) {
  final decision = _valueAtPath(contract, 'component_decisions.pressable-card');
  if (decision is! Map) return;

  final decisionDocument = decision['decision_document'];
  if (decision['decision_ref'] !=
          'BLDS-PHASE3-PRESSABLE-CARD-DESIGN-DECISION-2026-07-26' ||
      decisionDocument !=
          'docs/BLDS_PHASE_3_PRESSABLE_CARD_DESIGN_DECISION.md') {
    errors.add(
      'Pressable/Card decision must cite the exact approved packet and '
      'durable document.',
    );
  } else {
    _containedFile(
      repositoryRoot,
      decisionDocument as String,
      errors,
      label: 'Pressable/Card Design decision',
    );
  }

  const expectedTokenModes = <String, List<String>>{
    'component.card.surface': ['#14000000', '#1FFFFFFF', '#FFFFFF', '#121212'],
    'component.card.border': ['#14000000', '#26FFFFFF', '#000000', '#FFFFFF'],
    'component.pressable.hover-overlay': [
      '#14000000',
      '#14FFFFFF',
      '#1F000000',
      '#1FFFFFFF',
    ],
    'component.pressable.pressed-overlay': [
      '#1F000000',
      '#1FFFFFFF',
      '#33000000',
      '#33FFFFFF',
    ],
    'component.pressable.focus-outline': [
      '#000000',
      '#FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.pressable.focus-outer-ring': [
      '#5B7FFF',
      '#5B7FFF',
      '#000000',
      '#FFFFFF',
    ],
  };
  const modes = <String>[
    'light',
    'dark',
    'high-contrast-light',
    'high-contrast-dark',
  ];
  for (final entry in expectedTokenModes.entries) {
    for (var index = 0; index < modes.length; index += 1) {
      final actual = model.resolve(entry.key, modes[index]);
      final expected = entry.value[index];
      if (actual != expected) {
        errors.add(
          'Pressable/Card token drift for ${entry.key} ${modes[index]}: '
          'expected $expected, found $actual.',
        );
      }
    }
  }

  const exactValues = <String, Object>{
    'scope': 'pressable-wrapper-and-card-family-only',
    'public_api.pressable_inheritance': 'StatefulWidget',
    'public_api.card_inheritance': 'StatelessWidget',
    'public_api.legacy_constructor_source_compatible': true,
    'public_api.required_nullable_on_tap': true,
    'public_api.arbitrary_role_input': false,
    'actions.callbacks': 'immediate-on-confirmed-activation',
    'semantics.static_card_action_role': 'none',
    'semantics.tap_action_role': 'button',
    'semantics.long_press_only_button_role': false,
    'semantics.role_derived_from_actual_action': true,
    'semantics.unlabeled_legacy_conformance_claim': false,
    'geometry.minimum_interactive_target': '44x44',
    'geometry.custom_radius_and_padding_retained': true,
    'interaction.pressed_replaces_hover': true,
    'motion.curve': 'BLabMotion.ease',
    'motion.reduced_motion': 'immediate',
    'haptic.policy': 'BLabHapticPolicy-default-deny',
    'haptic.default_configuration': 'BLabHapticConfiguration.disabled',
    'haptic.maximum_pulses_per_committed_touch_action': 1,
    'haptic.non_touch_haptics': false,
    'high_contrast.surface': 'opaque',
    'high_contrast.backdrop_filter': false,
    'high_contrast.blur': false,
    'high_contrast.highlight': false,
    'high_contrast.shadow': false,
    'conformance.family_partial': true,
    'conformance.repository_wide_claim': false,
    'conformance.device_conformance_claim': false,
  };
  for (final entry in exactValues.entries) {
    final actual = _valueAtPath(decision, entry.key);
    if (actual != entry.value) {
      errors.add(
        'Pressable/Card decision drift for ${entry.key}: '
        'expected ${entry.value}, found $actual.',
      );
    }
  }
}

void _validateSnackbarDecision(
  Directory repositoryRoot,
  YamlMap contract,
  BlabTokenModel model,
  List<String> errors,
) {
  final decision = _valueAtPath(contract, 'component_decisions.snackbar');
  if (decision is! Map) return;

  final decisionDocument = decision['decision_document'];
  if (decision['decision_ref'] !=
          'BLDS-PHASE3-SNACKBAR-DESIGN-DECISION-2026-07-28' ||
      decisionDocument != 'docs/BLDS_PHASE_3_SNACKBAR_DESIGN_DECISION.md') {
    errors.add(
      'Snackbar decision must cite the exact approved packet and durable '
      'document.',
    );
  } else {
    _containedFile(
      repositoryRoot,
      decisionDocument as String,
      errors,
      label: 'Snackbar Design decision',
    );
  }

  const expectedTokenModes = <String, List<String>>{
    'component.snackbar.surface': ['#FFFFFF', '#1E1E1E', '#FFFFFF', '#121212'],
    'component.snackbar.foreground': [
      '#000000',
      '#FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.snackbar.border': [
      '#14000000',
      '#26FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.snackbar.badge-success': [
      '#10B981',
      '#10B981',
      '#10B981',
      '#10B981',
    ],
    'component.snackbar.badge-error': [
      '#FF3B30',
      '#FF3B30',
      '#FF3B30',
      '#FF3B30',
    ],
    'component.snackbar.badge-warning': [
      '#FF9500',
      '#FF9500',
      '#FF9500',
      '#FF9500',
    ],
    'component.snackbar.badge-info': [
      '#4ECDC4',
      '#4ECDC4',
      '#4ECDC4',
      '#4ECDC4',
    ],
    'component.snackbar.badge-glyph': [
      '#000000',
      '#000000',
      '#000000',
      '#000000',
    ],
    'component.snackbar.badge-outline': [
      '#00000000',
      '#00000000',
      '#000000',
      '#FFFFFF',
    ],
  };
  const modes = <String>[
    'light',
    'dark',
    'high-contrast-light',
    'high-contrast-dark',
  ];
  for (final entry in expectedTokenModes.entries) {
    for (var index = 0; index < modes.length; index += 1) {
      final actual = model.resolve(entry.key, modes[index]);
      final expected = entry.value[index];
      if (actual != expected) {
        errors.add(
          'Snackbar token drift for ${entry.key} ${modes[index]}: '
          'expected $expected, found $actual.',
        );
      }
    }
  }

  const exactValues = <String, Object>{
    'scope': 'snackbar-family-only',
    'public_api.legacy_show_signature_unchanged': true,
    'public_api.legacy_show_defaults_unchanged': true,
    'queue.visible_per_overlay': 1,
    'queue.enqueue': 'fifo',
    'queue.replace_current': 'current-exits-before-replacement',
    'queue.drop_duplicate_key': 'type-message-action-label',
    'lifecycle.closed_future': 'exactly-once',
    'lifecycle.dismiss': 'idempotent-programmatic',
    'lifecycle.persist_disables_timeout': true,
    'lifecycle.accessible_navigation_with_controls_disables_timeout': true,
    'lifecycle.interactive_minimum_timeout_seconds': 4,
    'semantics.live_region': 'message-only-created-when-visible',
    'semantics.announcement_count': 1,
    'semantics.default_priority': 'polite',
    'semantics.assertive': 'caller-opt-in-only',
    'semantics.modal': false,
    'semantics.focus_theft': false,
    'semantics.controls_separate': true,
    'keyboard.action_and_dismiss_activation': 'enter-space-exactly-once',
    'keyboard.escape': 'only-while-snackbar-owns-focus',
    'keyboard.restoration': 'conditional-to-live-requestable-prior-focus',
    'keyboard.focus_trap': false,
    'geometry.horizontal_outer_padding': 20,
    'geometry.vertical_padding': 16,
    'geometry.content_gap': 12,
    'geometry.radius': 'BLabRadius.lg',
    'geometry.badge_size': 32,
    'geometry.icon_size': 20,
    'geometry.dismiss_minimum_target': '44x44',
    'geometry.text_scaling': 'ambient-linear-and-nonlinear-unclamped',
    'motion.duration': 'BLabMotion.durSurface',
    'motion.curve': 'BLabMotion.ease',
    'motion.reduced_translation': false,
    'motion.reduced_opacity_maximum': 'BLabMotion.durPress',
    'visuals.surface': 'opaque-semantic-surface-overlay',
    'visuals.blur': false,
    'visuals.gradient': false,
    'visuals.highlight': false,
    'haptic.enabled': false,
    'conformance.family_partial': true,
    'conformance.repository_wide_claim': false,
    'conformance.device_conformance_claim': false,
  };
  for (final entry in exactValues.entries) {
    final actual = _valueAtPath(decision, entry.key);
    if (actual != entry.value) {
      errors.add(
        'Snackbar decision drift for ${entry.key}: '
        'expected ${entry.value}, found $actual.',
      );
    }
  }
}

void _validateKeyboardAccessoryDecision(
  Directory repositoryRoot,
  YamlMap contract,
  BlabTokenModel model,
  List<String> errors,
) {
  final decision = _valueAtPath(
    contract,
    'component_decisions.keyboard-accessory',
  );
  if (decision is! Map) return;

  final decisionDocument = decision['decision_document'];
  if (decision['decision_ref'] !=
          'BLDS-PHASE3-KEYBOARD-ACCESSORY-DESIGN-DECISION-2026-07-28' ||
      decisionDocument !=
          'docs/BLDS_PHASE_3_KEYBOARD_ACCESSORY_DESIGN_DECISION.md') {
    errors.add(
      'KeyboardAccessoryBar decision must cite the exact approved packet and '
      'durable document.',
    );
  } else {
    _containedFile(
      repositoryRoot,
      decisionDocument as String,
      errors,
      label: 'KeyboardAccessoryBar Design decision',
    );
  }

  const expectedTokenModes = <String, List<String>>{
    'component.keyboard-accessory.surface-start': [
      '#99FFFFFF',
      '#26FFFFFF',
      '#FFFFFF',
      '#121212',
    ],
    'component.keyboard-accessory.surface-end': [
      '#4DFFFFFF',
      '#14FFFFFF',
      '#FFFFFF',
      '#121212',
    ],
    'component.keyboard-accessory.border': [
      '#66FFFFFF',
      '#33FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.keyboard-accessory.foreground': [
      '#B3000000',
      '#E6FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.keyboard-accessory.disabled-foreground': [
      '#36000000',
      '#45FFFFFF',
      '#6B7280',
      '#9CA3AF',
    ],
    'component.keyboard-accessory.divider': [
      '#1A000000',
      '#33FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.keyboard-accessory.hover-overlay': [
      '#14000000',
      '#14FFFFFF',
      '#1F000000',
      '#1FFFFFFF',
    ],
    'component.keyboard-accessory.pressed-overlay': [
      '#1F000000',
      '#1FFFFFFF',
      '#33000000',
      '#33FFFFFF',
    ],
    'component.keyboard-accessory.focus-outline': [
      '#000000',
      '#FFFFFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.keyboard-accessory.focus-outer-ring': [
      '#5B7FFF',
      '#5B7FFF',
      '#000000',
      '#FFFFFF',
    ],
    'component.keyboard-accessory.shadow': [
      '#26000000',
      '#26000000',
      '#00000000',
      '#00000000',
    ],
    'component.keyboard-accessory.blur': ['20px', '20px', '0px', '0px'],
  };
  const modes = <String>[
    'light',
    'dark',
    'high-contrast-light',
    'high-contrast-dark',
  ];
  for (final entry in expectedTokenModes.entries) {
    for (var index = 0; index < modes.length; index += 1) {
      final actual = model.resolve(entry.key, modes[index]);
      final expected = entry.value[index];
      if (actual != expected) {
        errors.add(
          'KeyboardAccessoryBar token drift for ${entry.key} '
          '${modes[index]}: expected $expected, found $actual.',
        );
      }
    }
  }

  const exactValues = <String, Object>{
    'scope': 'keyboard-accessory-bar-family-only',
    'public_api.inheritance': 'StatefulWidget',
    'public_api.const_constructor_retained': true,
    'public_api.legacy_constructor_source_compatible': true,
    'public_api.legacy_defaults_unchanged': true,
    'public_api.haptic_api': false,
    'rendering.done': 'always-rendered-enabled',
    'rendering.navigation':
        'render-when-showNavigation-enable-callback-and-can-flag',
    'rendering.editing_actions': 'render-when-callback-enable-can-flag',
    'semantics.role': 'native-button',
    'semantics.names_per_action': 1,
    'semantics.supplied_labels': 'reject-blank-after-trim',
    'semantics.icon_semantics': 'excluded',
    'geometry.natural_target': '48x48',
    'geometry.minimum_target': '44x44',
    'narrow_width.addendum_ref':
        'BLDS-PHASE3-KEYBOARD-ACCESSORY-NARROW-WIDTH-ADDENDUM-2026-07-28',
    'narrow_width.required_width_formula': '32+48*(L+H+1)+max(0,L-1)+H',
    'narrow_width.maximum_composition_required_width': 373,
    'narrow_width.minimum_valid_host_width_formula':
        '32+48+(L+H>0?48:0)+(H>0?1:0)',
    'narrow_width.minimum_valid_host_width.done_only': 80,
    'narrow_width.minimum_valid_host_width.with_leading_without_history': 128,
    'narrow_width.minimum_valid_host_width.with_history': 129,
    'narrow_width.minimum_scrolling_viewport_width': 48,
    'narrow_width.invalid_host_behavior':
        'debug-diagnostic-no-conformance-claim',
    'narrow_width.overflow_trigger': 'finite-maxWidth-less-than-requiredWidth',
    'narrow_width.sufficient_or_unbounded': 'fixed-row-with-Spacer',
    'narrow_width.scrolling_actions': 'all-rendered-actions-except-Done',
    'narrow_width.pinned_action': 'Done-logical-trailing',
    'narrow_width.pinned_divider': 'one-when-Undo-or-Redo-rendered',
    'narrow_width.maximum_scrolling_content_width': 292,
    'narrow_width.maximum_pinned_block_width': 49,
    'narrow_width.viewport_320': 239,
    'narrow_width.viewport_360': 279,
    'narrow_width.controller':
        'owned-non-primary-horizontal-clamping-no-scrollbar',
    'narrow_width.initial_position': 'logical-start',
    'narrow_width.focus_reveal': 'complete-48px-target',
    'narrow_width.normal_reveal_duration': 'BLabMotion.durPress',
    'narrow_width.reveal_curve': 'BLabMotion.ease',
    'narrow_width.accessibility_focus': 'reveal-without-keyboard-focus',
    'narrow_width.native_scroll_semantics':
        'physical-direction-only-while-real-overflow',
    'narrow_width.manual_scroll': 'neutral-and-cancels-pressed-repeat',
    'narrow_width.edge_affordance': false,
    'narrow_width.public_api_added': false,
    'narrow_width.tokens_added': false,
    'keyboard.focus_model': 'individual-logical-tab-stops',
    'keyboard.focus_trap': false,
    'keyboard.activation': 'enter-space-exactly-once',
    'pointer.activation': 'exactly-once',
    'pointer.keyboard_focus_decoration': false,
    'repeat.trigger': 'pointer-long-press-only',
    'repeat.initial_callback': 'once-at-recognized-long-press',
    'repeat.initial_delay_ms': 500,
    'repeat.interval_ms': 100,
    'repeat.first_repeat': 'at-initial-delay',
    'repeat.tap_after_long_press': false,
    'repeat.semantic_repeat': false,
    'repeat.keyboard_repeat': false,
    'direction.rtl_group_placement': 'mirrored',
    'direction.rtl_history_glyphs': 'undo-redo-logical-directions-swapped',
    'host_ownership.safe_area': 'host',
    'host_ownership.view_insets': 'host',
    'host_ownership.overlay': 'host',
    'host_ownership.component_overlay': false,
    'visual_modes.standard': 'legacy-gradient-blur-shadow-preserved',
    'visual_modes.high_contrast_surface': 'opaque',
    'visual_modes.high_contrast_gradient': false,
    'visual_modes.high_contrast_blur': false,
    'visual_modes.high_contrast_shadow': false,
    'motion.interaction_duration': 'BLabMotion.durPress',
    'motion.curve': 'BLabMotion.ease',
    'motion.reduced_motion': 'immediate',
    'motion.repeat_cadence_affected': false,
    'haptic.enabled': false,
    'conformance.family_partial': true,
    'conformance.repository_wide_claim': false,
    'conformance.device_conformance_claim': false,
  };
  for (final entry in exactValues.entries) {
    final actual = _valueAtPath(decision, entry.key);
    if (actual != entry.value) {
      errors.add(
        'KeyboardAccessoryBar decision drift for ${entry.key}: '
        'expected ${entry.value}, found $actual.',
      );
    }
  }

  const expectedLabels = <String>[
    'upSemanticLabel',
    'downSemanticLabel',
    'copySemanticLabel',
    'clearAllSemanticLabel',
    'undoSemanticLabel',
    'redoSemanticLabel',
    'doneSemanticLabel',
  ];
  final labels = _valueAtPath(decision, 'public_api.additive_optional_labels');
  if (labels is! List ||
      !_sameOrderedValues(
        labels.whereType<String>().toList(),
        expectedLabels,
      )) {
    errors.add(
      'KeyboardAccessoryBar additive localized labels must remain exact and '
      'ordered.',
    );
  }

  const expectedCancellation = <String>[
    'pointer-up',
    'pointer-cancel',
    'callback-change',
    'enabled-change',
    'app-lifecycle-change',
    'another-repeat-pointer-down',
    'dispose',
    'callback-exception',
  ];
  final cancellation = _valueAtPath(decision, 'repeat.cancellation');
  if (cancellation is! List ||
      !_sameOrderedValues(
        cancellation.whereType<String>().toList(),
        expectedCancellation,
      )) {
    errors.add(
      'KeyboardAccessoryBar repeat cancellation matrix must remain exact.',
    );
  }

  const expectedImmediateReveals = <String>[
    'initial',
    'directionality-reset',
    'accessibility-focus',
    'reduced-motion',
  ];
  final immediateReveals = _valueAtPath(
    decision,
    'narrow_width.immediate_reveal',
  );
  if (immediateReveals is! List ||
      !_sameOrderedValues(
        immediateReveals.whereType<String>().toList(),
        expectedImmediateReveals,
      )) {
    errors.add(
      'KeyboardAccessoryBar narrow-width immediate reveal matrix must remain '
      'exact.',
    );
  }
}

void _validateSegmentedControlDecision(
  Directory repositoryRoot,
  YamlMap contract,
  BlabTokenModel model,
  List<String> errors,
) {
  final decision = _valueAtPath(
    contract,
    'component_decisions.segmented-control',
  );
  if (decision is! Map) return;

  const expectedPrecedence = <String>[
    'disabled',
    'keyboard-visible-focus',
    'pressed',
    'hover',
    'selected',
    'unselected',
  ];
  final precedence = decision['precedence'];
  if (precedence is! List ||
      !_sameOrderedValues(
        precedence.whereType<String>().toList(),
        expectedPrecedence,
      )) {
    errors.add(
      'SegmentedControl precedence must remain '
      '${expectedPrecedence.join(' > ')}.',
    );
  }

  const expectedUnsupported = <String>[
    'loading',
    'busy',
    'invalid',
    'error',
    'overlay',
    'expanded',
    'current',
    'disclosure',
    'drag',
    'haptic',
  ];
  final unsupported = decision['unsupported_not_simulated'];
  if (unsupported is! List ||
      !_sameOrderedValues(
        unsupported.whereType<String>().toList(),
        expectedUnsupported,
      )) {
    errors.add(
      'SegmentedControl unsupported states must remain explicit and '
      'unclaimed.',
    );
  }

  final decisionDocument = decision['decision_document'];
  if (decisionDocument !=
      'docs/BLDS_PHASE_3_SEGMENTED_CONTROL_DESIGN_DECISION.md') {
    errors.add(
      'SegmentedControl decision_document must cite the durable approved '
      'packet.',
    );
  } else {
    _containedFile(
      repositoryRoot,
      decisionDocument as String,
      errors,
      label: 'SegmentedControl Design decision',
    );
  }

  final addendumDocument = decision['addendum_document'];
  if (decision['addendum_ref'] !=
          'BLDS-PHASE3-NAVIGATION-SEGMENTED-SCROLLABLE-OVERFLOW-ADDENDUM-2026-07-26' ||
      addendumDocument !=
          'docs/BLDS_PHASE_3_SEGMENTED_CONTROL_SCROLLABLE_OVERFLOW_ADDENDUM.md') {
    errors.add(
      'SegmentedControl scrollable-overflow addendum must cite the exact '
      'approved packet and durable document.',
    );
  } else {
    _containedFile(
      repositoryRoot,
      addendumDocument as String,
      errors,
      label: 'SegmentedControl scrollable-overflow addendum',
    );
  }

  const expectedTokenModes = <String, List<String>>{
    'component.segmented.container-surface': [
      '#FFF5F5F5',
      '#FF232323',
      '#FFFFFFFF',
      '#FF121212',
    ],
    'component.segmented.container-border': [
      '#00000000',
      '#00000000',
      '#FF000000',
      '#FFFFFFFF',
    ],
    'component.segmented.selected-surface': [
      '#FFFFFFFF',
      '#FF2C2C2E',
      '#FFFFFFFF',
      '#FF121212',
    ],
    'component.segmented.selected-indicator': [
      '#FF5B7FFF',
      '#FF5B7FFF',
      '#FF000000',
      '#FFFFFFFF',
    ],
    'component.segmented.selected-foreground': [
      '#FF000000',
      '#FFFFFFFF',
      '#FF000000',
      '#FFFFFFFF',
    ],
    'component.segmented.unselected-foreground': [
      '#DD000000',
      '#DDFFFFFF',
      '#FF000000',
      '#FFFFFFFF',
    ],
    'component.segmented.disabled-foreground': [
      '#FF68707D',
      '#FF9CA3AF',
      '#FF6B7280',
      '#FF9CA3AF',
    ],
    'component.segmented.hover-overlay': [
      '#14000000',
      '#14FFFFFF',
      '#1F000000',
      '#1FFFFFFF',
    ],
    'component.segmented.pressed-overlay': [
      '#1F000000',
      '#1FFFFFFF',
      '#33000000',
      '#33FFFFFF',
    ],
    'component.segmented.focus-outline': [
      '#FF000000',
      '#FFFFFFFF',
      '#FF000000',
      '#FFFFFFFF',
    ],
    'component.segmented.focus-outer-ring': [
      '#FF5B7FFF',
      '#FF5B7FFF',
      '#FF000000',
      '#FFFFFFFF',
    ],
    'component.segmented.selected-shadow': [
      '#14000000',
      '#14000000',
      '#00000000',
      '#00000000',
    ],
  };
  const modes = <String>[
    'light',
    'dark',
    'high-contrast-light',
    'high-contrast-dark',
  ];
  for (final entry in expectedTokenModes.entries) {
    for (var index = 0; index < modes.length; index += 1) {
      final actual = model.resolve(entry.key, modes[index]);
      final expected = entry.value[index];
      if (actual != expected) {
        errors.add(
          'SegmentedControl token drift for ${entry.key} ${modes[index]}: '
          'expected $expected, found $actual.',
        );
      }
    }
  }

  const exactValues = <String, Object>{
    'focus.outline_width': 'semantic.focus.outline-width',
    'focus.outer_ring_width': 'semantic.focus.ring-width',
    'selection.selected_weight': 600,
    'selection.unselected_weight': 400,
    'selection.indicator_height': 2,
    'selection.indicator_node': 'stable-per-item-opacity-color',
    'geometry.visible_height': 40,
    'geometry.padding': 3,
    'geometry.font_size': 13,
    'geometry.narrow_width_behavior':
        'conditional-owned-horizontal-scroll-no-target-shrink',
    'overflow.condition':
        'finite-viewport-and-itemCount-times-44-plus-two-times-padding-exceeds-width',
    'overflow.controller': 'owned-non-primary-horizontal',
    'overflow.physics': 'clamping',
    'overflow.initial_origin': 'logical-start-ltr-left-rtl-right',
    'overflow.initial_selected_reveal':
        'immediate-including-disabled-selection',
    'overflow.focus_reveal': 'arrow-home-end-enabled-focus-wins',
    'overflow.external_enabled_selection':
        'inside-sync-focus-and-reveal-outside-reveal-only',
    'overflow.external_disabled_selection':
        'inside-enabled-focus-wins-outside-disabled-selection-reveals',
    'overflow.focus_ring_inline_allowance': 3,
    'overflow.programmatic_duration': 'BLabMotion.durPress',
    'overflow.programmatic_curve': 'BLabMotion.ease',
    'overflow.reduced_motion': 'immediate',
    'overflow.retargeting': 'latest-request-wins',
    'overflow.already_visible': 'no-animation-restart',
    'overflow.manual_scroll': 'neutral-preserved-until-next-reveal',
    'overflow.native_semantics':
        'horizontal-physical-direction-only-when-overflow',
    'overflow.scrollbar_gradient_affordance': 'none',
    'overflow.vertical_gesture_ownership': 'ancestor',
    'keyboard.external_selection_sync_trigger': 'selectedValue-change-only',
    'keyboard.navigation_focus_request_count': 1,
    'contrast.normal_text_minimum': 4.5,
    'contrast.non_text_and_focus_minimum': 3.0,
    'high_contrast.container_border_width': 1,
    'additive_api.item_enabled_default': true,
    'additive_api.control_enabled_default': true,
    'additive_api.public_widget_base': 'StatelessWidget',
  };
  for (final entry in exactValues.entries) {
    final actual = _valueAtPath(decision, entry.key);
    if (actual != entry.value) {
      errors.add(
        'SegmentedControl decision drift for ${entry.key}: '
        'expected ${entry.value}, found $actual.',
      );
    }
  }

  const expectedTextPairs = <String>[
    'selected-foreground/selected-surface',
    'unselected-foreground-composited/container-surface',
    'disabled-foreground/container-surface',
    'disabled-foreground/selected-surface',
    'unselected-foreground-composited/hover-over-container',
    'unselected-foreground-composited/pressed-over-container',
    'selected-foreground/hover-over-selected',
    'selected-foreground/pressed-over-selected',
  ];
  final textPairs = _valueAtPath(decision, 'contrast.text_pairs');
  if (textPairs is! List ||
      !_sameOrderedValues(
        textPairs.whereType<String>().toList(),
        expectedTextPairs,
      )) {
    errors.add(
      'SegmentedControl contrast text pairs must describe the actual '
      'composited layers.',
    );
  }

  const expectedRingAdjacencies = <String>[
    'surface-base',
    'component.segmented.container-surface',
    'component.segmented.selected-surface',
  ];
  final ringAdjacencies = _valueAtPath(
    decision,
    'contrast.outer_ring_adjacencies',
  );
  if (ringAdjacencies is! List ||
      !_sameOrderedValues(
        ringAdjacencies.whereType<String>().toList(),
        expectedRingAdjacencies,
      )) {
    errors.add(
      'SegmentedControl outer-ring contrast must cover every actual adjacent '
      'surface.',
    );
  }
}

YamlMap? _loadYamlMap(File file, List<String> errors) {
  if (!file.existsSync()) {
    errors.add('Missing required YAML file: ${file.path}');
    return null;
  }

  try {
    final document = loadYaml(file.readAsStringSync());
    if (document is! YamlMap) {
      errors.add('${file.path} must contain a YAML mapping at its root.');
      return null;
    }
    return document;
  } on YamlException catch (error) {
    errors.add('${file.path} is not valid YAML: ${error.message}');
    return null;
  }
}

void _validateSchemaRules(
  YamlMap contract,
  YamlMap schema,
  List<String> errors,
) {
  if (schema['schema'] != 'blab.contract-validation/v1') {
    errors.add('Unsupported contract validation schema: ${schema['schema']}');
  }

  final rules = schema['rules'];
  if (rules is! YamlList || rules.isEmpty) {
    errors.add('$contractSchemaPath must define at least one validation rule.');
    return;
  }

  for (final rawRule in rules) {
    if (rawRule is! YamlMap) {
      errors.add('Every schema rule must be a mapping.');
      continue;
    }

    final path = rawRule['path'];
    final expectedType = rawRule['type'];
    if (path is! String || expectedType is! String) {
      errors.add('Every schema rule needs string path and type values.');
      continue;
    }

    final value = _valueAtPath(contract, path);
    if (value == null) {
      errors.add('Missing required contract value: $path');
      continue;
    }

    if (!_hasType(value, expectedType)) {
      errors.add('$path must be $expectedType, but was ${value.runtimeType}.');
      continue;
    }

    if (rawRule['non_empty'] == true && _isEmpty(value)) {
      errors.add('$path must not be empty.');
    }

    if (rawRule.containsKey('equals') && value != rawRule['equals']) {
      errors.add('$path must equal ${rawRule['equals']}, but was $value.');
    }

    final allowed = rawRule['allowed'];
    if (allowed is YamlList && !allowed.contains(value)) {
      errors.add('$path must be one of ${allowed.toList()}, but was $value.');
    }
  }
}

Object? _valueAtPath(Map root, String path) {
  Object? current = root;
  for (final segment in path.split('.')) {
    if (current is! Map || !current.containsKey(segment)) {
      return null;
    }
    current = current[segment];
  }
  return current;
}

bool _hasType(Object value, String expectedType) {
  return switch (expectedType) {
    'boolean' => value is bool,
    'list' => value is List,
    'map' => value is Map,
    'number' => value is num,
    'string' => value is String,
    _ => false,
  };
}

bool _isEmpty(Object value) {
  return switch (value) {
    String() => value.isEmpty,
    Iterable() => value.isEmpty,
    Map() => value.isEmpty,
    _ => false,
  };
}

void _validateReferenceManifest(
  Directory repositoryRoot,
  YamlMap contract,
  List<String> errors,
) {
  final manifest = _valueAtPath(contract, 'values.reference_manifest');
  if (manifest is! List) {
    return;
  }

  final seenPaths = <String>{};
  for (final entry in manifest) {
    if (entry is! Map) {
      errors.add('Every values.reference_manifest entry must be a mapping.');
      continue;
    }

    final path = entry['path'];
    final historicalDigest = entry['historical_sha256'] ?? entry['sha256'];
    final current = entry['current'];
    final currentDigest = current is Map ? current['sha256'] : null;
    final expectedDigest = currentDigest ?? historicalDigest;
    if (path is! String || historicalDigest is! String) {
      errors.add(
        'Every reference manifest entry needs path and a historical SHA-256.',
      );
      continue;
    }
    if (!seenPaths.add(path)) {
      errors.add('Duplicate reference manifest path: $path');
      continue;
    }
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(historicalDigest)) {
      errors.add(
        'Historical reference digest must be lowercase SHA-256 for $path.',
      );
      continue;
    }
    final immutableHistoricalDigest = _phaseZeroHistoricalDigests[path];
    if (immutableHistoricalDigest != null &&
        historicalDigest != immutableHistoricalDigest) {
      errors.add(
        'Immutable Phase 0 digest for $path must remain '
        '$immutableHistoricalDigest, but was $historicalDigest.',
      );
    }
    if (current != null) {
      if (current is! Map ||
          current['phase'] is! int ||
          currentDigest is! String ||
          current['evidence'] is! List ||
          (current['evidence'] as List).isEmpty) {
        errors.add(
          'Migrated reference $path must declare current phase, SHA-256, '
          'and non-empty evidence.',
        );
        continue;
      }
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(currentDigest)) {
        errors.add('Current digest must be lowercase SHA-256 for $path.');
        continue;
      }
      for (final evidencePath in current['evidence'] as List) {
        if (evidencePath is! String) {
          errors.add('Current evidence for $path must contain paths.');
          continue;
        }
        _containedFile(
          repositoryRoot,
          evidencePath,
          errors,
          label: 'Current implementation evidence for $path',
        );
      }
    }

    final referencedFile = _containedFile(
      repositoryRoot,
      path,
      errors,
      label: 'Referenced Phase 0 value source',
    );
    if (referencedFile == null) {
      continue;
    }

    final actualDigest = sha256
        .convert(referencedFile.readAsBytesSync())
        .toString();
    if (actualDigest != expectedDigest) {
      errors.add(
        'Current reference drift for $path: expected $expectedDigest, '
        'found $actualDigest.',
      );
    }
  }

  final declaredPaths = _declaredValueSourcePaths(contract, errors);
  for (final missingPath in declaredPaths.difference(seenPaths)) {
    errors.add(
      'Declared value source is missing from reference_manifest: $missingPath',
    );
  }
  for (final extraPath in seenPaths.difference(declaredPaths)) {
    errors.add(
      'Reference manifest path is not declared by a token layer: $extraPath',
    );
  }
}

Set<String> _declaredValueSourcePaths(YamlMap contract, List<String> errors) {
  final tokenLayers = _valueAtPath(contract, 'values.token_layers');
  if (tokenLayers is! Map) {
    errors.add('values.token_layers must be a mapping.');
    return {};
  }

  final paths = <String>{};
  for (final entry in tokenLayers.entries) {
    final layer = entry.value;
    if (layer is! Map || layer['current_value_refs'] is! List) {
      errors.add(
        'values.token_layers.${entry.key}.current_value_refs must be a list.',
      );
      continue;
    }
    for (final path in layer['current_value_refs'] as List) {
      if (path is! String || path.isEmpty) {
        errors.add(
          'values.token_layers.${entry.key}.current_value_refs '
          'must contain non-empty strings.',
        );
        continue;
      }
      paths.add(path);
    }
  }
  return paths;
}

void _validateOutputs(
  Directory repositoryRoot,
  YamlMap contract,
  List<String> errors,
) {
  final outputs = contract['outputs'];
  if (outputs is! List) {
    return;
  }

  final seenIds = <String>{};
  const allowedStatuses = {
    'design-owned-source',
    'manually-preserved-not-generated',
    'planned-phase1-output',
    'planned-phase1-output-no-remote-mutation',
    'downstream-distribution-mirror-not-mutated',
    'generated-owned-additive',
  };

  for (final output in outputs) {
    if (output is! Map) {
      errors.add('Every outputs entry must be a mapping.');
      continue;
    }

    final id = output['id'];
    final status = output['phase0_status'];
    final path = output['path'];
    if (id is! String ||
        id.isEmpty ||
        status is! String ||
        path is! String ||
        path.isEmpty) {
      errors.add(
        'Every output needs non-empty id, path, and phase0_status strings.',
      );
      continue;
    }
    if (!seenIds.add(id)) {
      errors.add('Duplicate output id: $id');
    }
    if (!allowedStatuses.contains(status)) {
      errors.add('Unsupported Phase 0 output status for $id: $status');
    }
    if (status == 'generated-owned-additive') {
      _validateSafePath(repositoryRoot, path, errors, label: 'Output $id');
    }
  }
}

void _validateReferencedContractFiles(
  Directory repositoryRoot,
  YamlMap contract,
  List<String> errors,
) {
  final refs = <String>[
    if (_valueAtPath(contract, 'values.typed_token_model_ref')
        case final String value)
      value,
    if (_valueAtPath(contract, 'accessibility.component_state_manifest_ref')
        case final String value)
      value,
    if (_valueAtPath(contract, 'accessibility.visual_baseline_manifest_ref')
        case final String value)
      value,
    if (_valueAtPath(contract, 'license.license_file') case final String value)
      value,
  ];
  final basis = _valueAtPath(contract, 'provenance.contract_basis');
  if (basis is List) {
    refs.addAll(basis.whereType<String>());
  }
  for (final ref in refs.toSet()) {
    _containedFile(
      repositoryRoot,
      ref,
      errors,
      label: 'Referenced contract file',
    );
  }

  for (final refPath in [
    _valueAtPath(contract, 'accessibility.component_state_manifest_ref'),
    _valueAtPath(contract, 'accessibility.visual_baseline_manifest_ref'),
  ].whereType<String>()) {
    final file = File('${repositoryRoot.path}/$refPath');
    if (!file.existsSync()) {
      continue;
    }
    final document = _loadYamlMap(file, errors);
    if (document == null) {
      continue;
    }
    if (refPath.endsWith('state-applicability.yaml')) {
      _validateStateManifest(repositoryRoot, document, refPath, errors);
    } else if (refPath.endsWith('visual-baselines.yaml')) {
      _validateBaselineManifest(document, refPath, errors);
    }
  }
}

void _validateStateManifest(
  Directory repositoryRoot,
  YamlMap manifest,
  String path,
  List<String> errors,
) {
  if (manifest['schema'] != 'blab.component-states/v1') {
    errors.add('Unsupported component-state schema: ${manifest['schema']}');
  }
  final metadata = manifest['metadata'];
  if (metadata is! Map ||
      metadata['version'] is! String ||
      metadata['owner'] != 'byungskerlab-design-team' ||
      metadata['approved_by'] != 'byungsker') {
    errors.add(
      '$path metadata must declare version, Design owner, and approval.',
    );
  }
  final rules = manifest['rules'];
  if (rules is! Map ||
      rules['applicable_states_require_behavior_semantics_and_evidence'] !=
          true ||
      rules['not_applicable_states_must_not_be_simulated'] != true) {
    errors.add('$path must preserve the approved applicability rules.');
  }
  final components = manifest['components'];
  _validateUniqueIds(components, '$path components', errors);
  if (components is! List || components.isEmpty) {
    errors.add('$path components must be a non-empty list.');
    return;
  }
  final publicTypes = <String>{};
  for (final component in components) {
    if (component is! Map ||
        component['id'] is! String ||
        component['public_type'] is! String) {
      errors.add('Every $path component needs string id and public_type.');
      continue;
    }
    final id = component['id'] as String;
    final publicType = component['public_type'] as String;
    if (!publicTypes.add(publicType)) {
      errors.add('Duplicate public_type in $path components: $publicType');
    }
    final categories = <String, Set<String>>{};
    for (final category in <String>[
      'required',
      'conditional',
      'not_applicable',
    ]) {
      final rawStates = component[category];
      if (rawStates is! List || rawStates.any((state) => state is! String)) {
        errors.add('$path $id $category must be a list of state ids.');
        continue;
      }
      final states = <String>{};
      for (final state in rawStates.cast<String>()) {
        if (state.isEmpty) {
          errors.add('$path $id $category state ids must not be empty.');
        }
        if (!states.add(state)) {
          errors.add('Duplicate $category state for $id: $state');
        }
      }
      categories[category] = states;
    }
    final requiredWhen = component['required_when'];
    if (requiredWhen != null &&
        (requiredWhen is! Map ||
            requiredWhen.keys.any((key) => key is! String) ||
            requiredWhen.values.any((value) => value is! String))) {
      errors.add('$path $id required_when must map state ids to conditions.');
    }
    final applicable = <String>{
      ...?categories['required'],
      ...?categories['conditional'],
      if (requiredWhen is Map) ...requiredWhen.keys.whereType<String>(),
    };
    final overlap = applicable.intersection(
      categories['not_applicable'] ?? const <String>{},
    );
    for (final state in overlap.toList()..sort()) {
      errors.add(
        'State $state for $id cannot be both applicable and not applicable.',
      );
    }
    final implementationEvidence = component['implementation_evidence'];
    if (implementationEvidence != null && implementationEvidence is! Map) {
      errors.add('$path $id implementation_evidence must be a state map.');
      continue;
    }
    if (implementationEvidence is Map) {
      for (final entry in implementationEvidence.entries) {
        final state = entry.key;
        final evidence = entry.value;
        if (state is! String || !applicable.contains(state)) {
          errors.add(
            '$path $id implementation evidence must reference an applicable '
            'state: $state',
          );
          continue;
        }
        if (evidence is! Map ||
            evidence['status'] != 'implemented-local' ||
            evidence['test'] is! String ||
            evidence['documentation'] is! String) {
          errors.add(
            '$path $id/$state implementation evidence must declare '
            'implemented-local test and documentation paths.',
          );
          continue;
        }
        _containedFile(
          repositoryRoot,
          evidence['test'] as String,
          errors,
          label: '$path $id/$state test evidence',
        );
        _containedFile(
          repositoryRoot,
          evidence['documentation'] as String,
          errors,
          label: '$path $id/$state documentation evidence',
        );
      }
    }
    final absenceEvidence = component['absence_evidence'];
    if (absenceEvidence != null && absenceEvidence is! Map) {
      errors.add('$path $id absence_evidence must be a state map.');
      continue;
    }
    if (absenceEvidence is Map) {
      const allowedAbsenceStatuses = <String>{
        'observable-runtime-semantics-absence',
        'observable-runtime-validation-absence',
        'typed-code-inspection-only',
      };
      final eligibleAbsenceStates = <String>{
        ...?categories['conditional'],
        ...?categories['not_applicable'],
      };
      for (final entry in absenceEvidence.entries) {
        final state = entry.key;
        final evidence = entry.value;
        if (state is! String || !eligibleAbsenceStates.contains(state)) {
          errors.add(
            '$path $id absence evidence must reference a conditional or '
            'not-applicable state: $state',
          );
          continue;
        }
        if (evidence is! Map ||
            !allowedAbsenceStatuses.contains(evidence['status']) ||
            evidence['evidence'] is! List ||
            (evidence['evidence'] as List).isEmpty) {
          errors.add(
            '$path $id/$state absence evidence must declare an approved '
            'status and non-empty evidence paths.',
          );
          continue;
        }
        for (final evidencePath in evidence['evidence'] as List) {
          if (evidencePath is! String) {
            errors.add('$path $id/$state absence evidence must be paths.');
            continue;
          }
          _containedFile(
            repositoryRoot,
            evidencePath,
            errors,
            label: '$path $id/$state absence evidence',
          );
        }
      }
    }
  }
}

void _validateBaselineManifest(
  YamlMap manifest,
  String path,
  List<String> errors,
) {
  if (manifest['schema'] != 'blab.visual-baselines/v1') {
    errors.add('Unsupported visual-baseline schema: ${manifest['schema']}');
  }
  final metadata = manifest['metadata'];
  if (metadata is! Map ||
      metadata['version'] is! String ||
      metadata['visual_intent_owner'] != 'byungskerlab-design-team' ||
      metadata['capture_owner'] != 'engineering-design-system-frontend') {
    errors.add(
      '$path metadata must declare version, Design intent owner, and '
      'Engineering capture owner.',
    );
  }
  final policy = manifest['policy'];
  if (policy is! Map ||
      policy['automatic_golden_acceptance_forbidden'] != true ||
      policy['golden_equality_is_not_accessibility_evidence'] != true) {
    errors.add('$path must preserve the approved baseline safety policy.');
  }
  final matrix = manifest['capture_matrix'];
  for (final key in <String>[
    'brightness',
    'text_scalers',
    'locales',
    'reduced_motion',
  ]) {
    if (matrix is! Map ||
        matrix[key] is! List ||
        (matrix[key] as List).isEmpty) {
      errors.add('$path capture_matrix.$key must be a non-empty list.');
    }
  }
  _validateUniqueIds(manifest['baselines'], '$path baselines', errors);
  if (manifest['baselines'] is! List) {
    errors.add('$path baselines must be a list.');
  }
}

void _validateUniqueIds(Object? rawList, String label, List<String> errors) {
  if (rawList == null) {
    return;
  }
  if (rawList is! List) {
    errors.add('$label must be a list.');
    return;
  }
  final ids = <String>{};
  for (final entry in rawList) {
    if (entry is! Map || entry['id'] is! String) {
      errors.add('Every $label entry needs a string id.');
      continue;
    }
    final id = entry['id'] as String;
    if (!ids.add(id)) {
      errors.add('Duplicate id in $label: $id');
    }
  }
}

File? _containedFile(
  Directory repositoryRoot,
  String path,
  List<String> errors, {
  required String label,
}) {
  if (!_validateSafePath(repositoryRoot, path, errors, label: label)) {
    return null;
  }
  final file = File('${repositoryRoot.path}/$path');
  if (!file.existsSync()) {
    errors.add('$label does not exist: $path');
    return null;
  }
  if (!_isCanonicallyInside(repositoryRoot, file)) {
    errors.add('$label escapes the repository: $path');
    return null;
  }
  return file;
}

bool _validateSafePath(
  Directory repositoryRoot,
  String path,
  List<String> errors, {
  required String label,
}) {
  if (_isUnsafeRelativePath(path)) {
    errors.add('$label path must stay inside the repository: $path');
    return false;
  }
  final parent = File('${repositoryRoot.path}/$path').parent;
  if (parent.existsSync() && !_isCanonicallyInside(repositoryRoot, parent)) {
    errors.add('$label parent escapes the repository: $path');
    return false;
  }
  return true;
}

bool _isUnsafeRelativePath(String path) {
  return path.isEmpty ||
      RegExp(r'^(?:/|[A-Za-z]:[\\/]|\\\\)').hasMatch(path) ||
      path.split(RegExp(r'[/\\]')).contains('..');
}

bool _isCanonicallyInside(Directory repositoryRoot, FileSystemEntity target) {
  final canonicalRoot = repositoryRoot.resolveSymbolicLinksSync();
  final canonicalTarget = target.resolveSymbolicLinksSync();
  return canonicalTarget == canonicalRoot ||
      canonicalTarget.startsWith('$canonicalRoot${Platform.pathSeparator}');
}
