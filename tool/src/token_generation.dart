import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import 'contract_validation.dart';

const generatedTokenDataPath = 'lib/src/generated/blab_token_data.g.dart';
const generatedThemeExtensionPath = 'lib/src/theme/blab_token_theme.dart';
const generatedCssPath = 'generated/blab.tokens.css';
const generatedTraceabilityPath = 'generated/token-traceability.md';
const generatedKoreanTokenDocumentationPath =
    'generated/token-reference.ko-KR.md';
const generatedFigmaMappingPath = 'generated/figma-token-mapping.json';
const generatedComponentStateCoveragePath =
    'generated/component-state-coverage.yaml';
const generatedCapabilityManifestPath = 'generated/blab-capabilities.v1.json';

const generatedTokenPaths = [
  generatedTokenDataPath,
  generatedThemeExtensionPath,
  generatedCssPath,
  generatedTraceabilityPath,
  generatedKoreanTokenDocumentationPath,
  generatedFigmaMappingPath,
  generatedComponentStateCoveragePath,
  generatedCapabilityManifestPath,
];

const _modes = ['light', 'dark', 'high-contrast-light', 'high-contrast-dark'];

Map<String, String> buildGeneratedTokenOutputs(
  Directory repositoryRoot, {
  BlabContractInspection? inspection,
}) {
  final inspected = inspection ?? inspectBlabContract(repositoryRoot);
  final validationErrors = inspected.errors;
  if (validationErrors.isNotEmpty) {
    throw StateError(
      'Cannot generate from an invalid Blab contract:\n'
      '${validationErrors.map((error) => '- $error').join('\n')}',
    );
  }
  final model = inspected.tokenModel;
  if (model == null) {
    throw StateError('Unable to load the typed Blab token model.');
  }
  final sourceChecksum = _sourceChecksum(repositoryRoot, model.sourcePath);
  final contract =
      loadYaml(File('${repositoryRoot.path}/$contractPath').readAsStringSync())
          as YamlMap;
  const glossaryPath = 'contracts/glossary/blab.terms.yaml';
  const statePath = 'contracts/components/state-applicability.yaml';

  return {
    generatedTokenDataPath: _withDartHeader(
      sourcePath: model.sourcePath,
      version: model.version,
      sourceChecksum: sourceChecksum,
      body: _buildTokenDataBody(model),
    ),
    generatedThemeExtensionPath: _withDartHeader(
      sourcePath: model.sourcePath,
      version: model.version,
      sourceChecksum: sourceChecksum,
      body: _buildThemeExtensionBody(model),
    ),
    generatedCssPath: _withCssHeader(
      sourcePath: model.sourcePath,
      version: model.version,
      sourceChecksum: sourceChecksum,
      body: _buildCssBody(model),
    ),
    generatedTraceabilityPath: _withMarkdownHeader(
      sourcePath: model.sourcePath,
      version: model.version,
      sourceChecksum: sourceChecksum,
      body: _buildTraceabilityBody(repositoryRoot, model),
    ),
    generatedKoreanTokenDocumentationPath: _withMarkdownHeader(
      sourcePath: '${model.sourcePath} + $glossaryPath',
      version: model.version,
      sourceChecksum: _combinedSourceChecksum(repositoryRoot, <String>[
        contractPath,
        model.sourcePath,
        glossaryPath,
      ]),
      body: _buildKoreanTokenDocumentationBody(repositoryRoot, model),
    ),
    generatedFigmaMappingPath: _buildFigmaMappingJson(repositoryRoot, model),
    generatedComponentStateCoveragePath: _buildStateCoverageYaml(
      repositoryRoot,
      contract,
      statePath,
    ),
    generatedCapabilityManifestPath: _buildCapabilityManifestJson(
      repositoryRoot,
      contract,
    ),
  };
}

void writeGeneratedTokenOutputs(
  Directory outputRoot,
  Map<String, String> outputs,
) {
  final destinations = _validatedGeneratedDestinations(outputRoot);
  for (var index = 0; index < generatedTokenPaths.length; index += 1) {
    final path = generatedTokenPaths[index];
    final content = outputs[path];
    if (content == null) {
      throw StateError('Missing generated content for $path.');
    }
    final file = destinations[path]!;
    file.parent.createSync(recursive: true);
    final temporary = _createSiblingTemporaryFile(file, index);
    try {
      temporary.writeAsStringSync(content, flush: true);
      temporary.renameSync(file.path);
    } finally {
      if (temporary.existsSync()) {
        temporary.deleteSync();
      }
    }
  }
}

List<String> findGeneratedTokenDrift(
  Directory outputRoot,
  Map<String, String> expected,
) {
  final drift = <String>[];
  final destinations = _validatedGeneratedDestinations(outputRoot);
  for (final path in generatedTokenPaths) {
    final file = destinations[path]!;
    if (!file.existsSync()) {
      drift.add('$path is missing');
      continue;
    }
    if (file.readAsStringSync() != expected[path]) {
      drift.add('$path differs from deterministic generation');
    }
  }
  return drift;
}

Map<String, File> _validatedGeneratedDestinations(Directory outputRoot) {
  if (!outputRoot.existsSync()) {
    throw StateError(
      'Generated output root does not exist: ${outputRoot.path}',
    );
  }
  final canonicalRoot = outputRoot.resolveSymbolicLinksSync();
  final destinations = <String, File>{};
  for (final path in generatedTokenPaths) {
    if (_isUnsafeGeneratedPath(path)) {
      throw StateError('Generated output path is unsafe: $path');
    }
    final target = File('${outputRoot.path}/$path');
    if (Link(target.path).existsSync()) {
      throw StateError(
        'Generated output target must not be a symbolic link: $path',
      );
    }

    final existingAncestor = _nearestExistingAncestor(target.parent);
    final canonicalAncestor = existingAncestor.resolveSymbolicLinksSync();
    if (!_canonicalPathIsInside(canonicalRoot, canonicalAncestor)) {
      throw StateError(
        'Generated output parent escapes the output root: $path',
      );
    }
    if (target.existsSync()) {
      final canonicalTarget = target.resolveSymbolicLinksSync();
      if (!_canonicalPathIsInside(canonicalRoot, canonicalTarget)) {
        throw StateError(
          'Generated output target escapes the output root: $path',
        );
      }
    }
    destinations[path] = target;
  }
  return destinations;
}

Directory _nearestExistingAncestor(Directory directory) {
  var current = directory;
  while (!current.existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Generated output has no existing parent: ${directory.path}',
      );
    }
    current = parent;
  }
  return current;
}

bool _canonicalPathIsInside(String root, String target) {
  return target == root || target.startsWith('$root${Platform.pathSeparator}');
}

bool _isUnsafeGeneratedPath(String path) {
  return path.isEmpty ||
      RegExp(r'^(?:/|[A-Za-z]:[\\/]|\\\\)').hasMatch(path) ||
      path.split(RegExp(r'[/\\]')).contains('..');
}

File _createSiblingTemporaryFile(File target, int index) {
  var attempt = 0;
  while (true) {
    final temporary = File(
      '${target.path}.tmp.$pid.$index.'
      '${DateTime.now().microsecondsSinceEpoch}.$attempt',
    );
    try {
      temporary.createSync(exclusive: true);
      return temporary;
    } on FileSystemException {
      attempt += 1;
      if (attempt >= 100) {
        throw StateError(
          'Could not reserve an atomic temporary output for ${target.path}.',
        );
      }
    }
  }
}

String _sourceChecksum(Directory repositoryRoot, String modelPath) {
  return _combinedSourceChecksum(repositoryRoot, <String>[
    contractPath,
    modelPath,
  ]);
}

String _combinedSourceChecksum(Directory repositoryRoot, List<String> paths) {
  final bytes = <int>[];
  for (var index = 0; index < paths.length; index += 1) {
    if (index > 0) {
      bytes.add(0x0A);
    }
    bytes.addAll(
      File('${repositoryRoot.path}/${paths[index]}').readAsBytesSync(),
    );
  }
  return sha256.convert(bytes).toString();
}

String _withDartHeader({
  required String sourcePath,
  required String version,
  required String sourceChecksum,
  required String body,
}) {
  final bodyChecksum = sha256.convert(utf8.encode(body)).toString();
  return '''
// GENERATED CODE - DO NOT EDIT.
// Source: $contractPath + $sourcePath
// Contract version: $version
// Source checksum (SHA-256): $sourceChecksum
// Content checksum (SHA-256, body only): $bodyChecksum

$body''';
}

String _withCssHeader({
  required String sourcePath,
  required String version,
  required String sourceChecksum,
  required String body,
}) {
  final bodyChecksum = sha256.convert(utf8.encode(body)).toString();
  return '''
/* GENERATED CODE - DO NOT EDIT.
 * Source: $contractPath + $sourcePath
 * Contract version: $version
 * Source checksum (SHA-256): $sourceChecksum
 * Content checksum (SHA-256, body only): $bodyChecksum
 */

$body''';
}

String _withMarkdownHeader({
  required String sourcePath,
  required String version,
  required String sourceChecksum,
  required String body,
}) {
  final bodyChecksum = sha256.convert(utf8.encode(body)).toString();
  return '''
<!-- GENERATED CODE - DO NOT EDIT.
Source: $contractPath + $sourcePath
Contract version: $version
Source checksum (SHA-256): $sourceChecksum
Content checksum (SHA-256, body only): $bodyChecksum
-->

$body''';
}

String _buildTokenDataBody(BlabTokenModel model) {
  final buffer = StringBuffer()
    ..writeln('library;')
    ..writeln()
    ..writeln('abstract final class BlabGeneratedTokenData {')
    ..writeln("  static const contractVersion = '${model.version}';")
    ..writeln();

  for (final mode in _modes) {
    buffer.writeln('  static const Map<String, String> ${_dartMode(mode)} = {');
    final ids = model.nodes.keys.toList()..sort();
    for (final id in ids) {
      buffer.writeln(
        "    ${_dartString(id)}: ${_dartString(model.resolve(id, mode))},",
      );
    }
    buffer
      ..writeln('  };')
      ..writeln();
  }
  buffer.writeln('}');
  return buffer.toString().replaceFirst(RegExp(r'\n\n}\n$'), '\n}\n');
}

String _dartMode(String mode) {
  final parts = mode.split('-');
  return [
    parts.first,
    ...parts
        .skip(1)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}'),
  ].join();
}

String _buildThemeExtensionBody(BlabTokenModel model) {
  const colorFields = <String, String>{
    'surfaceBase': 'semantic.surface.base',
    'surfaceRaised': 'semantic.surface.raised',
    'surfaceOverlay': 'semantic.surface.overlay',
    'glassSurface': 'semantic.surface.glass',
    'textPrimary': 'semantic.text.primary',
    'textSecondary': 'semantic.text.secondary',
    'textTertiary': 'semantic.text.tertiary',
    'textInverse': 'semantic.text.inverse',
    'borderSubtle': 'semantic.border.subtle',
    'borderDefault': 'semantic.border.default',
    'borderStrong': 'semantic.border.strong',
    'focusRing': 'semantic.focus.ring',
    'focusCanvas': 'semantic.focus.canvas',
    'focusSurface': 'semantic.focus.surface',
    'focusAccent': 'semantic.focus.accent',
    'actionPrimary': 'semantic.action.primary',
    'actionPrimaryForeground': 'semantic.action.primary-foreground',
    'actionDestructive': 'semantic.action.destructive',
    'actionDestructiveForeground': 'semantic.action.destructive-foreground',
    'buttonPrimaryHoverOverlay': 'component.button.primary.hover-overlay',
    'buttonSecondaryHoverOverlay': 'component.button.secondary.hover-overlay',
    'buttonDestructiveHoverOverlay':
        'component.button.destructive.hover-overlay',
    'buttonPrimaryFocusOutline': 'component.button.primary.focus-outline',
    'buttonSecondaryFocusOutline': 'component.button.secondary.focus-outline',
    'buttonDestructiveFocusOutline':
        'component.button.destructive.focus-outline',
    'buttonFocusOuterRing': 'component.button.focus-outer-ring',
    'textFieldLabel': 'component.text-field.label',
    'textFieldHint': 'component.text-field.hint',
    'textFieldHoverBorder': 'component.text-field.hover-border',
    'textFieldFocusOutline': 'component.text-field.focus-outline',
    'textFieldFocusOuterRing': 'component.text-field.focus-outer-ring',
    'textFieldErrorBorder': 'component.text-field.error-border',
    'textFieldClearBackground': 'component.text-field.clear-background',
    'textFieldClearForeground': 'component.text-field.clear-foreground',
    'segmentedContainerSurface': 'component.segmented.container-surface',
    'segmentedContainerBorder': 'component.segmented.container-border',
    'segmentedSelectedSurface': 'component.segmented.selected-surface',
    'segmentedSelectedIndicator': 'component.segmented.selected-indicator',
    'segmentedSelectedForeground': 'component.segmented.selected-foreground',
    'segmentedUnselectedForeground':
        'component.segmented.unselected-foreground',
    'segmentedDisabledForeground': 'component.segmented.disabled-foreground',
    'segmentedHoverOverlay': 'component.segmented.hover-overlay',
    'segmentedPressedOverlay': 'component.segmented.pressed-overlay',
    'segmentedFocusOutline': 'component.segmented.focus-outline',
    'segmentedFocusOuterRing': 'component.segmented.focus-outer-ring',
    'segmentedSelectedShadow': 'component.segmented.selected-shadow',
    'snackbarSurface': 'component.snackbar.surface',
    'snackbarForeground': 'component.snackbar.foreground',
    'snackbarBorder': 'component.snackbar.border',
    'snackbarBadgeSuccess': 'component.snackbar.badge-success',
    'snackbarBadgeError': 'component.snackbar.badge-error',
    'snackbarBadgeWarning': 'component.snackbar.badge-warning',
    'snackbarBadgeInfo': 'component.snackbar.badge-info',
    'snackbarBadgeGlyph': 'component.snackbar.badge-glyph',
    'snackbarBadgeOutline': 'component.snackbar.badge-outline',
    'keyboardAccessorySurfaceStart':
        'component.keyboard-accessory.surface-start',
    'keyboardAccessorySurfaceEnd': 'component.keyboard-accessory.surface-end',
    'keyboardAccessoryBorder': 'component.keyboard-accessory.border',
    'keyboardAccessoryForeground': 'component.keyboard-accessory.foreground',
    'keyboardAccessoryDisabledForeground':
        'component.keyboard-accessory.disabled-foreground',
    'keyboardAccessoryDivider': 'component.keyboard-accessory.divider',
    'keyboardAccessoryHoverOverlay':
        'component.keyboard-accessory.hover-overlay',
    'keyboardAccessoryPressedOverlay':
        'component.keyboard-accessory.pressed-overlay',
    'keyboardAccessoryFocusOutline':
        'component.keyboard-accessory.focus-outline',
    'keyboardAccessoryFocusOuterRing':
        'component.keyboard-accessory.focus-outer-ring',
    'keyboardAccessoryShadow': 'component.keyboard-accessory.shadow',
    'cardSurface': 'component.card.surface',
    'cardBorder': 'component.card.border',
    'pressableHoverOverlay': 'component.pressable.hover-overlay',
    'pressablePressedOverlay': 'component.pressable.pressed-overlay',
    'pressableFocusOutline': 'component.pressable.focus-outline',
    'pressableFocusOuterRing': 'component.pressable.focus-outer-ring',
    'statusSuccess': 'semantic.status.success',
    'statusError': 'semantic.status.error',
    'statusWarning': 'semantic.status.warning',
    'statusInfo': 'semantic.status.info',
    'statusForeground': 'semantic.status.foreground',
    'disabledForeground': 'semantic.state.disabled-foreground',
  };
  const additiveColorFields = <String>{
    'focusCanvas',
    'focusSurface',
    'focusAccent',
    'buttonPrimaryHoverOverlay',
    'buttonSecondaryHoverOverlay',
    'buttonDestructiveHoverOverlay',
    'buttonPrimaryFocusOutline',
    'buttonSecondaryFocusOutline',
    'buttonDestructiveFocusOutline',
    'buttonFocusOuterRing',
    'textFieldLabel',
    'textFieldHint',
    'textFieldHoverBorder',
    'textFieldFocusOutline',
    'textFieldFocusOuterRing',
    'textFieldErrorBorder',
    'textFieldClearBackground',
    'textFieldClearForeground',
    'segmentedContainerSurface',
    'segmentedContainerBorder',
    'segmentedSelectedSurface',
    'segmentedSelectedIndicator',
    'segmentedSelectedForeground',
    'segmentedUnselectedForeground',
    'segmentedDisabledForeground',
    'segmentedHoverOverlay',
    'segmentedPressedOverlay',
    'segmentedFocusOutline',
    'segmentedFocusOuterRing',
    'segmentedSelectedShadow',
    'snackbarSurface',
    'snackbarForeground',
    'snackbarBorder',
    'snackbarBadgeSuccess',
    'snackbarBadgeError',
    'snackbarBadgeWarning',
    'snackbarBadgeInfo',
    'snackbarBadgeGlyph',
    'snackbarBadgeOutline',
    'keyboardAccessorySurfaceStart',
    'keyboardAccessorySurfaceEnd',
    'keyboardAccessoryBorder',
    'keyboardAccessoryForeground',
    'keyboardAccessoryDisabledForeground',
    'keyboardAccessoryDivider',
    'keyboardAccessoryHoverOverlay',
    'keyboardAccessoryPressedOverlay',
    'keyboardAccessoryFocusOutline',
    'keyboardAccessoryFocusOuterRing',
    'keyboardAccessoryShadow',
    'cardSurface',
    'cardBorder',
    'pressableHoverOverlay',
    'pressablePressedOverlay',
    'pressableFocusOutline',
    'pressableFocusOuterRing',
  };
  final buffer = StringBuffer()
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln()
    ..writeln(
      'enum BLabVisualMode { light, dark, highContrastLight, '
      'highContrastDark }',
    )
    ..writeln()
    ..writeln('@immutable')
    ..writeln('class BLabTokenTheme extends ThemeExtension<BLabTokenTheme> {')
    ..writeln('  const BLabTokenTheme({');
  for (final field in colorFields.keys) {
    if (additiveColorFields.contains(field)) {
      buffer.writeln(
        '    this.$field = '
        'const ${_dartColor(model.resolve(colorFields[field]!, 'light'))},',
      );
    } else {
      buffer.writeln('    required this.$field,');
    }
  }
  buffer
    ..writeln(
      '    this.focusOutlineWidth = '
      '${_dimension(model.resolve('semantic.focus.outline-width', 'light'))},',
    )
    ..writeln(
      '    this.focusRingWidth = '
      '${_dimension(model.resolve('semantic.focus.ring-width', 'light'))},',
    )
    ..writeln(
      '    this.keyboardAccessoryBlur = '
      '${_dimension(model.resolve('component.keyboard-accessory.blur', 'light'))},',
    )
    ..writeln('    required this.glassBlur,')
    ..writeln('    required this.glassSaturation,')
    ..writeln('    required this.glassHighlight,')
    ..writeln('    required this.glassShadowEnabled,')
    ..writeln('  });')
    ..writeln();
  for (final field in colorFields.keys) {
    buffer.writeln('  final Color $field;');
  }
  buffer
    ..writeln('  final double focusOutlineWidth;')
    ..writeln('  final double focusRingWidth;')
    ..writeln('  final double keyboardAccessoryBlur;')
    ..writeln('  final double glassBlur;')
    ..writeln('  final double glassSaturation;')
    ..writeln('  final Color? glassHighlight;')
    ..writeln('  final bool glassShadowEnabled;')
    ..writeln();

  for (final mode in _modes) {
    buffer.writeln(
      '  static const BLabTokenTheme ${_dartMode(mode)} = '
      'BLabTokenTheme(',
    );
    for (final entry in colorFields.entries) {
      buffer.writeln(
        '    ${entry.key}: ${_dartColor(model.resolve(entry.value, mode))},',
      );
    }
    buffer
      ..writeln(
        '    focusOutlineWidth: '
        '${_dimension(model.resolve('semantic.focus.outline-width', mode))},',
      )
      ..writeln(
        '    focusRingWidth: '
        '${_dimension(model.resolve('semantic.focus.ring-width', mode))},',
      )
      ..writeln(
        '    keyboardAccessoryBlur: '
        '${_dimension(model.resolve('component.keyboard-accessory.blur', mode))},',
      )
      ..writeln(
        '    glassBlur: '
        '${_dimension(model.resolve('semantic.glass.blur', mode))},',
      )
      ..writeln(
        '    glassSaturation: '
        '${_percentage(model.resolve('semantic.glass.saturation', mode))},',
      );
    final highlight = model.resolve('semantic.glass.highlight', mode);
    buffer
      ..writeln(
        '    glassHighlight: '
        '${highlight == 'none' ? 'null' : _dartColor(highlight)},',
      )
      ..writeln(
        '    glassShadowEnabled: '
        '${model.resolve('semantic.glass.shadow', mode) != 'none'},',
      )
      ..writeln('  );')
      ..writeln();
  }

  buffer
    ..writeln('  static BLabTokenTheme forMode(BLabVisualMode mode) {')
    ..writeln('    return switch (mode) {')
    ..writeln('      BLabVisualMode.light => light,')
    ..writeln('      BLabVisualMode.dark => dark,')
    ..writeln('      BLabVisualMode.highContrastLight => highContrastLight,')
    ..writeln('      BLabVisualMode.highContrastDark => highContrastDark,')
    ..writeln('    };')
    ..writeln('  }')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  BLabTokenTheme copyWith({');
  for (final field in colorFields.keys) {
    buffer.writeln('    Color? $field,');
  }
  buffer
    ..writeln('    double? focusOutlineWidth,')
    ..writeln('    double? focusRingWidth,')
    ..writeln('    double? keyboardAccessoryBlur,')
    ..writeln('    double? glassBlur,')
    ..writeln('    double? glassSaturation,')
    ..writeln('    Color? glassHighlight,')
    ..writeln('    bool clearGlassHighlight = false,')
    ..writeln('    bool? glassShadowEnabled,')
    ..writeln('  }) {')
    ..writeln('    return BLabTokenTheme(');
  for (final field in colorFields.keys) {
    final line = '      $field: $field ?? this.$field,';
    if (line.length <= 80) {
      buffer.writeln(line);
    } else {
      final expression = '$field ?? this.$field,';
      buffer.writeln('      $field:');
      if ('          $expression'.length <= 80) {
        buffer.writeln('          $expression');
      } else {
        buffer
          ..writeln('          $field ??')
          ..writeln('          this.$field,');
      }
    }
  }
  buffer
    ..writeln(
      '      focusOutlineWidth: '
      'focusOutlineWidth ?? this.focusOutlineWidth,',
    )
    ..writeln('      focusRingWidth: focusRingWidth ?? this.focusRingWidth,')
    ..writeln('      keyboardAccessoryBlur:')
    ..writeln('          keyboardAccessoryBlur ?? this.keyboardAccessoryBlur,')
    ..writeln('      glassBlur: glassBlur ?? this.glassBlur,')
    ..writeln(
      '      glassSaturation: '
      'glassSaturation ?? this.glassSaturation,',
    )
    ..writeln('      glassHighlight: clearGlassHighlight')
    ..writeln('          ? null')
    ..writeln('          : glassHighlight ?? this.glassHighlight,')
    ..writeln(
      '      glassShadowEnabled: '
      'glassShadowEnabled ?? this.glassShadowEnabled,',
    )
    ..writeln('    );')
    ..writeln('  }')
    ..writeln()
    ..writeln('  @override')
    ..writeln(
      '  BLabTokenTheme lerp(covariant BLabTokenTheme? other, double t) {',
    )
    ..writeln('    if (other == null) return this;')
    ..writeln('    return BLabTokenTheme(');
  for (final field in colorFields.keys) {
    final line = '      $field: Color.lerp($field, other.$field, t)!,';
    if (line.length <= 80) {
      buffer.writeln(line);
    } else {
      buffer
        ..writeln('      $field: Color.lerp(')
        ..writeln('        $field,')
        ..writeln('        other.$field,')
        ..writeln('        t,')
        ..writeln('      )!,');
    }
  }
  buffer
    ..writeln('      focusOutlineWidth:')
    ..writeln(
      '          focusOutlineWidth + '
      '(other.focusOutlineWidth - focusOutlineWidth) * t,',
    )
    ..writeln('      focusRingWidth:')
    ..writeln(
      '          focusRingWidth + '
      '(other.focusRingWidth - focusRingWidth) * t,',
    )
    ..writeln('      keyboardAccessoryBlur:')
    ..writeln('          keyboardAccessoryBlur +')
    ..writeln(
      '          (other.keyboardAccessoryBlur - keyboardAccessoryBlur) * t,',
    )
    ..writeln(
      '      glassBlur: '
      'glassBlur + (other.glassBlur - glassBlur) * t,',
    )
    ..writeln('      glassSaturation:')
    ..writeln(
      '          glassSaturation + '
      '(other.glassSaturation - glassSaturation) * t,',
    )
    ..writeln(
      '      glassHighlight: '
      'Color.lerp(glassHighlight, other.glassHighlight, t),',
    )
    ..writeln('      glassShadowEnabled: t < 0.5')
    ..writeln('          ? glassShadowEnabled')
    ..writeln('          : other.glassShadowEnabled,')
    ..writeln('    );')
    ..writeln('  }')
    ..writeln('}');
  return buffer.toString();
}

String _dartColor(String value) {
  final hex = value.substring(1);
  final argb = hex.length == 6 ? 'FF$hex' : hex;
  return 'Color(0x$argb)';
}

String _dimension(String value) => value.replaceFirst('px', '');

String _percentage(String value) {
  final percent = double.parse(value.replaceFirst('%', ''));
  return (percent / 100).toString();
}

String _buildCssBody(BlabTokenModel model) {
  final buffer = StringBuffer()..writeln(':root {');
  for (final mapping in model.cssMappings) {
    buffer.writeln('  ${mapping.name}: ${mapping.light};');
  }
  buffer
    ..writeln('}')
    ..writeln()
    ..writeln('[data-theme="dark"], .blab-dark {');
  for (final mapping in model.cssMappings.where(
    (mapping) => mapping.dark != null,
  )) {
    buffer.writeln('  ${mapping.name}: ${mapping.dark};');
  }
  buffer
    ..writeln('}')
    ..writeln();

  for (final mode in ['high-contrast-light', 'high-contrast-dark']) {
    final className = mode == 'high-contrast-light'
        ? 'blab-high-contrast-light'
        : 'blab-high-contrast-dark';
    buffer.writeln('[data-theme="$mode"], .$className {');
    for (final mapping in model.cssMappings.where(
      (mapping) => mapping.token?.startsWith('semantic.') ?? false,
    )) {
      buffer.writeln(
        '  ${mapping.name}: ${model.resolve(mapping.token!, mode)};',
      );
    }
    final semanticIds =
        model.nodes.values
            .where((node) => node.layer == 'semantics')
            .map((node) => node.id)
            .toList()
          ..sort();
    for (final id in semanticIds) {
      buffer.writeln(
        '  --blab-token-${id.replaceAll('.', '-')}: '
        '${model.resolve(id, mode)};',
      );
    }
    buffer
      ..writeln('}')
      ..writeln();
  }
  return buffer.toString();
}

String _buildTraceabilityBody(Directory repositoryRoot, BlabTokenModel model) {
  final tokenDocument =
      loadYaml(
            File(
              '${repositoryRoot.path}/${model.sourcePath}',
            ).readAsStringSync(),
          )
          as YamlMap;
  final dartSources =
      tokenDocument['legacy_mappings']['dart']['sources'] as YamlList;
  final rawMappings =
      tokenDocument['legacy_mappings']['component_raw_values'] as YamlList;
  final layerCounts = <String, int>{};
  for (final node in model.nodes.values) {
    layerCounts.update(node.layer, (count) => count + 1, ifAbsent: () => 1);
  }

  final buffer = StringBuffer()
    ..writeln('# Blab token traceability matrix')
    ..writeln()
    ..writeln(
      'This additive Phase 1A artifact maps the approved typed contract to '
      'the compatibility-locked standard sources. It is not a conformance '
      'claim.',
    )
    ..writeln()
    ..writeln('| Inventory | Count |')
    ..writeln('| --- | ---: |')
    ..writeln('| Primitive tokens | ${layerCounts['primitives'] ?? 0} |')
    ..writeln('| Semantic tokens | ${layerCounts['semantics'] ?? 0} |')
    ..writeln('| Component tokens | ${layerCounts['components'] ?? 0} |')
    ..writeln('| Legacy CSS names | ${model.cssMappings.length} |')
    ..writeln('| Legacy Dart symbols | ${model.dartMappingCount} |')
    ..writeln(
      '| Classified component-local raw values | '
      '${model.componentRawValueCount} |',
    )
    ..writeln()
    ..writeln('## Typed token graph')
    ..writeln()
    ..writeln(
      '| Layer | Token | Type | Light | Dark | High-contrast light | '
      'High-contrast dark |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
  final nodes = model.nodes.values.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  for (final node in nodes) {
    buffer.writeln(
      '| ${node.layer} | `${node.id}` | `${node.type}` | '
      '`${model.resolve(node.id, 'light')}` | '
      '`${model.resolve(node.id, 'dark')}` | '
      '`${model.resolve(node.id, 'high-contrast-light')}` | '
      '`${model.resolve(node.id, 'high-contrast-dark')}` |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Legacy CSS compatibility')
    ..writeln()
    ..writeln(
      '| CSS name | Light | Dark | Typed token / classification | '
      'Deprecation |',
    )
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final mapping in model.cssMappings) {
    buffer.writeln(
      '| `${mapping.name}` | `${mapping.light}` | '
      '`${mapping.dark ?? mapping.light}` | '
      '`${mapping.token ?? mapping.classification}` | '
      '`${mapping.deprecation}` |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Legacy Dart compatibility')
    ..writeln()
    ..writeln(
      '| Source | Dart symbol | Typed token / classification | Deprecation |',
    )
    ..writeln('| --- | --- | --- | --- |');
  final dartRows = <({String path, YamlMap symbol})>[];
  for (final rawSource in dartSources) {
    final source = rawSource as YamlMap;
    for (final rawSymbol in source['symbols'] as YamlList) {
      dartRows.add((
        path: source['path'] as String,
        symbol: rawSymbol as YamlMap,
      ));
    }
  }
  dartRows.sort(
    (left, right) => (left.symbol['symbol'] as String).compareTo(
      right.symbol['symbol'] as String,
    ),
  );
  for (final row in dartRows) {
    buffer.writeln(
      '| `${row.path}` | `${row.symbol['symbol']}` | '
      '`${row.symbol['token'] ?? row.symbol['classification']}` | '
      '`${row.symbol['deprecation']}` |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Component-local raw-value classifications')
    ..writeln()
    ..writeln('| Source | Raw value | Classification | Deprecation |')
    ..writeln('| --- | --- | --- | --- |');
  final rawRows =
      <
        ({String path, String value, String classification, String deprecation})
      >[];
  for (final rawMapping in rawMappings) {
    final mapping = rawMapping as YamlMap;
    for (final rawValue in mapping['raw_values'] as YamlList) {
      rawRows.add((
        path: mapping['path'] as String,
        value: rawValue as String,
        classification: mapping['classification'] as String,
        deprecation: mapping['deprecation'] as String,
      ));
    }
  }
  rawRows.sort((left, right) {
    final pathOrder = left.path.compareTo(right.path);
    return pathOrder == 0 ? left.value.compareTo(right.value) : pathOrder;
  });
  for (final row in rawRows) {
    buffer.writeln(
      '| `${row.path}` | `${row.value}` | `${row.classification}` | '
      '`${row.deprecation}` |',
    );
  }
  return buffer.toString();
}

String _buildKoreanTokenDocumentationBody(
  Directory repositoryRoot,
  BlabTokenModel model,
) {
  final glossary =
      loadYaml(
            File(
              '${repositoryRoot.path}/contracts/glossary/blab.terms.yaml',
            ).readAsStringSync(),
          )
          as YamlMap;
  final terms = <String, String>{
    for (final rawTerm in glossary['terms'] as YamlList)
      (rawTerm as YamlMap)['id'] as String: rawTerm['canonical'] as String,
  };
  final layerLabels = <String, String>{
    'primitives': terms['primitive-token'] ?? '원시 토큰',
    'semantics': terms['semantic-token'] ?? '의미 토큰',
    'components': terms['component-token'] ?? '컴포넌트 토큰',
  };
  final nodes = model.nodes.values.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final buffer = StringBuffer()
    ..writeln('# Blab 토큰 참조표')
    ..writeln()
    ..writeln(
      '이 표는 `ko-KR` 기준의 정식 생성 문서이며 승인된 토큰 계약을 '
      '결정론적으로 표시합니다. 구현, 접근성, 시각 또는 로케일 적합성을 '
      '주장하지 않습니다.',
    )
    ..writeln()
    ..writeln(
      '| 계층 | 토큰 ID | 형식 | 라이트 | 다크 | 고대비 라이트 | '
      '고대비 다크 |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
  for (final node in nodes) {
    buffer.writeln(
      '| ${layerLabels[node.layer]} | `${node.id}` | `${node.type}` | '
      '`${model.resolve(node.id, 'light')}` | '
      '`${model.resolve(node.id, 'dark')}` | '
      '`${model.resolve(node.id, 'high-contrast-light')}` | '
      '`${model.resolve(node.id, 'high-contrast-dark')}` |',
    );
  }
  return buffer.toString();
}

String _buildFigmaMappingJson(Directory repositoryRoot, BlabTokenModel model) {
  final nodes = model.nodes.values.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final mappings = <Map<String, Object?>>[
    for (final node in nodes)
      <String, Object?>{
        'token_id': node.id,
        'figma_path': node.id.split('.').join('/'),
        'collection': node.layer,
        'type': node.type,
        'resolved_modes': <String, String>{
          for (final mode in _modes) mode: model.resolve(node.id, mode),
        },
      },
  ];
  return _generatedJson(
    schema: 'blab.figma-token-mapping/v1',
    version: model.version,
    sources: <String>[contractPath, model.sourcePath],
    sourceChecksum: _sourceChecksum(repositoryRoot, model.sourcePath),
    dataKey: 'mappings',
    data: mappings,
    extraGenerated: const <String, Object?>{
      'remote_mutation': false,
      'custody': 'repository-local',
    },
  );
}

String _buildStateCoverageYaml(
  Directory repositoryRoot,
  YamlMap contract,
  String statePath,
) {
  final manifest =
      loadYaml(File('${repositoryRoot.path}/$statePath').readAsStringSync())
          as YamlMap;
  final metadata = manifest['metadata'] as YamlMap;
  final version = metadata['version'] as String;
  final components =
      (manifest['components'] as YamlList).cast<YamlMap>().toList()..sort(
        (left, right) =>
            (left['id'] as String).compareTo(right['id'] as String),
      );
  final implementationFamilies = components
      .where((component) {
        final evidence = component['implementation_evidence'];
        return evidence is YamlMap && evidence.isNotEmpty;
      })
      .map((component) => component['id'] as String)
      .toList();
  final hasImplementationEvidence = implementationFamilies.isNotEmpty;
  final sourceChecksum = _combinedSourceChecksum(repositoryRoot, <String>[
    contractPath,
    statePath,
  ]);
  final body = StringBuffer()
    ..writeln('schema: "blab.component-state-coverage/v1"')
    ..writeln('metadata:')
    ..writeln('  version: "$version"')
    ..writeln('  source_locale: "ko-KR"')
    ..writeln(
      '  implementation_evidence: "'
      '${hasImplementationEvidence ? 'partial-component-families-only' : 'not-claimed'}"',
    )
    ..writeln(
      '  implementation_family_scope: "'
      '${hasImplementationEvidence ? implementationFamilies.join(',') : 'none'}"',
    )
    ..writeln('  global_capability_complete: false')
    ..writeln('  loading_busy_claimed: false')
    ..writeln(
      '  accessibility_evidence: "'
      '${hasImplementationEvidence ? 'partial-component-families-automated-only' : 'not-claimed'}"',
    )
    ..writeln('  visual_evidence: "not-claimed"')
    ..writeln('  phase: ${hasImplementationEvidence ? 3 : 1}')
    ..writeln('components:');
  for (final component in components) {
    final implementationEvidence = component['implementation_evidence'];
    final states = <({String id, String classification, String? condition})>[];
    for (final state in (component['required'] as YamlList).cast<String>()) {
      states.add((
        id: state,
        classification: 'required-by-design-contract',
        condition: null,
      ));
    }
    for (final state in (component['conditional'] as YamlList).cast<String>()) {
      states.add((
        id: state,
        classification: 'conditional-by-design-contract',
        condition: null,
      ));
    }
    final requiredWhen = component['required_when'];
    if (requiredWhen is YamlMap) {
      for (final entry in requiredWhen.entries) {
        states.add((
          id: entry.key as String,
          classification: 'required-when-by-design-contract',
          condition: entry.value as String,
        ));
      }
    }
    states.sort((left, right) => left.id.compareTo(right.id));
    final notApplicable =
        (component['not_applicable'] as YamlList).cast<String>().toList()
          ..sort();
    body
      ..writeln('  - id: "${component['id']}"')
      ..writeln('    public_type: "${component['public_type']}"')
      ..writeln('    applicable_states:');
    for (final state in states) {
      final rawEvidence = implementationEvidence is YamlMap
          ? implementationEvidence[state.id]
          : null;
      final evidence = rawEvidence is YamlMap ? rawEvidence : null;
      body
        ..writeln('      - id: "${state.id}"')
        ..writeln('        classification: "${state.classification}"')
        ..writeln(
          '        implementation_evidence: "'
          '${evidence?['status'] ?? 'not-claimed'}"',
        );
      if (evidence != null) {
        body
          ..writeln('        test_evidence: "${evidence['test']}"')
          ..writeln(
            '        documentation_evidence: "${evidence['documentation']}"',
          );
      }
      if (state.condition != null) {
        body.writeln('        condition: "${state.condition}"');
      }
    }
    body.writeln('    not_applicable_states:');
    for (final state in notApplicable) {
      body.writeln('      - "$state"');
    }
    final absenceEvidence = component['absence_evidence'];
    if (absenceEvidence is YamlMap && absenceEvidence.isNotEmpty) {
      body.writeln('    absence_evidence:');
      final absenceIds = absenceEvidence.keys.cast<String>().toList()..sort();
      for (final state in absenceIds) {
        final evidence = absenceEvidence[state] as YamlMap;
        body
          ..writeln('      - id: "$state"')
          ..writeln('        status: "${evidence['status']}"')
          ..writeln('        evidence:');
        final paths = (evidence['evidence'] as YamlList).cast<String>().toList()
          ..sort();
        for (final path in paths) {
          body.writeln('          - "$path"');
        }
      }
    }
  }
  final bodyText = body.toString();
  final contentChecksum = sha256.convert(utf8.encode(bodyText)).toString();
  return '''
# GENERATED CODE - DO NOT EDIT.
# Source: $contractPath + $statePath
# Contract version: ${contract['metadata']['contract_version']}
# Source checksum (SHA-256): $sourceChecksum
# Content checksum (SHA-256, body only): $contentChecksum

$bodyText''';
}

String _buildCapabilityManifestJson(
  Directory repositoryRoot,
  YamlMap contract,
) {
  final capabilities = contract['capabilities'] as YamlMap;
  final phaseStatus = <String, String>{
    for (final entry in (capabilities['phase_status'] as YamlMap).entries)
      entry.key as String: entry.value as String,
  };
  final claims = <String, bool>{
    for (final entry in (capabilities['claims'] as YamlMap).entries)
      entry.key as String: entry.value as bool,
  };
  final entries =
      (capabilities['entries'] as YamlList)
          .cast<YamlMap>()
          .map(
            (entry) => <String, Object?>{
              'id': entry['id'] as String,
              'phase': entry['phase'] as int,
              'status': entry['status'] as String,
              if (entry['scope'] case final YamlMap scope)
                'scope': <String, Object?>{
                  for (final scopeEntry in scope.entries)
                    scopeEntry.key as String: scopeEntry.value,
                },
              'evidence':
                  (entry['evidence'] as YamlList).cast<String>().toList()
                    ..sort(),
            },
          )
          .toList()
        ..sort(
          (left, right) =>
              (left['id'] as String).compareTo(right['id'] as String),
        );
  return _generatedJson(
    schema: 'blab.capabilities/v1',
    version: capabilities['version'] as String,
    sources: const <String>[contractPath],
    sourceChecksum: _combinedSourceChecksum(repositoryRoot, const <String>[
      contractPath,
    ]),
    dataKey: 'capabilities',
    data: entries,
    additionalTopLevel: <String, Object?>{
      'phase_status': phaseStatus,
      'claims': claims,
    },
  );
}

String _generatedJson({
  required String schema,
  required String version,
  required List<String> sources,
  required String sourceChecksum,
  required String dataKey,
  required Object data,
  Map<String, Object?> extraGenerated = const <String, Object?>{},
  Map<String, Object?> additionalTopLevel = const <String, Object?>{},
}) {
  final content = <String, Object?>{
    'version': version,
    dataKey: data,
    ...additionalTopLevel,
  };
  final contentChecksum = sha256
      .convert(utf8.encode(jsonEncode(content)))
      .toString();
  final document = <String, Object?>{
    'schema': schema,
    '_generated': <String, Object?>{
      'notice': 'GENERATED CODE - DO NOT EDIT.',
      'sources': sources,
      'source_checksum_sha256': sourceChecksum,
      'content_checksum_sha256': contentChecksum,
      ...extraGenerated,
    },
    ...content,
  };
  return '${const JsonEncoder.withIndent('  ').convert(document)}\n';
}

String _dartString(String value) {
  return "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
}
