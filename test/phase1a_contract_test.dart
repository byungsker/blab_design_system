import 'dart:convert';
import 'dart:io';

import 'package:blab_design_system/blab_design_system.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/src/contract_validation.dart';
import '../tool/src/token_generation.dart';

void main() {
  test('contract validation rejects cycles in the typed token graph', () {
    final fixture = Directory.systemTemp.createTempSync('blab-phase1a-cycle-');
    addTearDown(() => fixture.deleteSync(recursive: true));

    File('${fixture.path}/contracts/schema/blab.design.schema.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
schema: "blab.contract-validation/v1"
rules:
  - path: "schema"
    type: "string"
    equals: "blab.design/v1"
''');
    File('${fixture.path}/contracts/blab.design.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
schema: "blab.design/v1"
values:
  token_layers: {}
  reference_manifest: []
tokens:
  primitives:
    - id: "primitive.cycle.a"
      type: "color"
      value: "{primitive.cycle.b}"
    - id: "primitive.cycle.b"
      type: "color"
      value: "{primitive.cycle.a}"
  semantics: []
  components: []
outputs: []
''');

    expect(
      validateBlabContract(fixture),
      contains(
        'Token reference cycle: '
        'primitive.cycle.a -> primitive.cycle.b -> primitive.cycle.a',
      ),
    );
  });

  test('contract validation rejects missing typed-token references', () {
    final fixture = _createTypedFixture('''
  primitives:
    - id: "primitive.color.only"
      type: "color"
      value: "{primitive.color.missing}"
  semantics: []
  components: []
''');
    addTearDown(() => fixture.deleteSync(recursive: true));

    expect(
      validateBlabContract(fixture),
      contains(
        'Missing token reference from primitive.color.only: '
        'primitive.color.missing',
      ),
    );
  });

  test('contract validation rejects duplicate typed-token ids', () {
    final fixture = _createTypedFixture('''
  primitives:
    - {id: "primitive.color.duplicate", type: "color", value: "#000000"}
    - {id: "primitive.color.duplicate", type: "color", value: "#FFFFFF"}
  semantics: []
  components: []
''');
    addTearDown(() => fixture.deleteSync(recursive: true));

    expect(
      validateBlabContract(fixture),
      contains('Duplicate token id: primitive.color.duplicate'),
    );
  });

  test('contract validation rejects unapproved output statuses', () {
    final fixture = _createTypedFixture(
      '''
  primitives:
    - {id: "primitive.color.only", type: "color", value: "#000000"}
  semantics: []
  components: []
''',
      outputs: '''
  - id: "unsafe"
    path: "generated/unsafe.txt"
    phase0_status: "silently-published"
''',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));

    expect(
      validateBlabContract(fixture),
      contains(
        'Unsupported Phase 0 output status for unsafe: silently-published',
      ),
    );
  });

  test('contract validation rejects malformed typed-token literals', () {
    final fixture = _createTypedFixture('''
  primitives:
    - {id: "primitive.color.invalid", type: "color", value: "blue"}
    - {id: "primitive.optional.invalid", type: "color-or-none", value: "transparent"}
    - {id: "primitive.dimension.invalid", type: "dimension", value: "25"}
    - {id: "primitive.percentage.invalid", type: "percentage", value: "1.8"}
    - {id: "primitive.shadow.invalid", type: "shadow-or-none", value: "large"}
    - {id: "primitive.shadow.unitless", type: "shadow-or-none", value: "5 8px 32px rgba(0,0,0,0.15)"}
    - {id: "primitive.shadow.range", type: "shadow-or-none", value: "0 8px 32px rgba(999,0,0,1.1)"}
  semantics: []
  components: []
''');
    addTearDown(() => fixture.deleteSync(recursive: true));

    final errors = validateBlabContract(fixture);
    expect(
      errors,
      contains('Invalid color literal for primitive.color.invalid: blue'),
    );
    expect(
      errors,
      contains(
        'Invalid color-or-none literal for primitive.optional.invalid: '
        'transparent',
      ),
    );
    expect(
      errors,
      contains('Invalid dimension literal for primitive.dimension.invalid: 25'),
    );
    expect(
      errors,
      contains(
        'Invalid percentage literal for primitive.percentage.invalid: 1.8',
      ),
    );
    expect(
      errors,
      contains(
        'Invalid shadow-or-none literal for primitive.shadow.invalid: large',
      ),
    );
    expect(
      errors,
      contains(
        'Invalid shadow-or-none literal for primitive.shadow.unitless: '
        '5 8px 32px rgba(0,0,0,0.15)',
      ),
    );
    expect(
      errors,
      contains(
        'Invalid shadow-or-none literal for primitive.shadow.range: '
        '0 8px 32px rgba(999,0,0,1.1)',
      ),
    );
  });

  test('contract validation rejects incompatible token-reference types', () {
    final fixture = _createTypedFixture('''
  primitives:
    - {id: "primitive.color.base", type: "color", value: "#000000"}
  semantics:
    - id: "semantic.dimension.invalid"
      type: "dimension"
      modes:
        light: "{primitive.color.base}"
        dark: "{primitive.color.base}"
        high-contrast-light: "{primitive.color.base}"
        high-contrast-dark: "{primitive.color.base}"
  components: []
''');
    addTearDown(() => fixture.deleteSync(recursive: true));

    expect(
      validateBlabContract(fixture),
      contains(
        'Token reference type mismatch from semantic.dimension.invalid '
        '(dimension) to primitive.color.base (color)',
      ),
    );
  });

  test('legacy Dart classifications are restricted to approved enums', () {
    final fixture = _copyCurrentContractFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));
    final tokenFile = File('${fixture.path}/contracts/tokens/blab.tokens.yaml');
    final source = tokenFile.readAsStringSync();
    final dartSection = source.indexOf('  dart:');
    final mappedClassification = source.indexOf(
      'classification: "mapped"',
      dartSection,
    );
    expect(mappedClassification, greaterThan(dartSection));
    tokenFile.writeAsStringSync(
      source.replaceRange(
        mappedClassification,
        mappedClassification + 'classification: "mapped"'.length,
        'classification: "component-local-raw"',
      ),
    );

    expect(
      validateBlabContract(fixture),
      contains(
        'Unsupported legacy Dart classification for BLabColors.primary: '
        'component-local-raw',
      ),
    );
  });

  test('component raw-value inventory rejects fabricated values', () {
    final fixture = _copyCurrentContractFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));
    final tokenFile = File('${fixture.path}/contracts/tokens/blab.tokens.yaml');
    final source = tokenFile.readAsStringSync();
    final componentSection = source.indexOf('  component_raw_values:');
    final rawValue = source.indexOf('"42:19:40"', componentSection);
    expect(rawValue, greaterThan(componentSection));
    tokenFile.writeAsStringSync(
      source.replaceRange(
        rawValue,
        rawValue + '"42:19:40"'.length,
        '"42:19:fabricated"',
      ),
    );

    expect(
      validateBlabContract(fixture).any(
        (error) => error.startsWith(
          'Component raw-value drift for '
          'lib/src/widgets/blab_segmented_control.dart',
        ),
      ),
      isTrue,
    );
  });

  test('mapped legacy Dart values must equal their token source values', () {
    final fixture = _copyCurrentContractFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));
    final colorsFile = File('${fixture.path}/lib/src/theme/app_colors.dart');
    colorsFile.writeAsStringSync(
      colorsFile.readAsStringSync().replaceFirst(
        'Color(0xFF5B7FFF)',
        'Color(0xFF000001)',
      ),
    );

    expect(
      validateBlabContract(fixture),
      contains(
        'Legacy Dart mapped value drift for BLabColors.primary (light): '
        'expected #5B7FFF, found #000001',
      ),
    );
  });

  test('the approved typed graph resolves all modes exactly', () {
    final errors = <String>[];
    final model = loadBlabTokenModel(Directory.current, errors: errors);

    expect(errors, isEmpty);
    expect(model, isNotNull);
    // Phase 3 KeyboardAccessoryBar adds twelve component-scoped tokens to the
    // previously approved 134-node graph.
    expect(model!.nodes.length, 146);
    expect(model.cssMappings.length, 134);
    expect(model.dartMappingCount, 139);
    // The count mirrors the validator-approved, source-exact component raw
    // inventory after the KeyboardAccessoryBar implementation.
    expect(model.componentRawValueCount, 297);
    expect(model.resolve('semantic.surface.base', 'light'), '#FAFAFA');
    expect(model.resolve('semantic.surface.base', 'dark'), '#121212');
    expect(
      model.resolve('component.button.primary.foreground', 'light'),
      '#000000',
    );
    expect(
      model.resolve(
        'component.button.primary.foreground',
        'high-contrast-light',
      ),
      '#000000',
    );
    expect(
      model.resolve('component.button.primary.hover-overlay', 'light'),
      '#14000000',
    );
    expect(
      model.resolve('component.button.primary.hover-overlay', 'dark'),
      '#14000000',
    );
    expect(
      model.resolve(
        'component.button.primary.hover-overlay',
        'high-contrast-light',
      ),
      '#1FFFFFFF',
    );
    expect(
      model.resolve('component.button.secondary.hover-overlay', 'light'),
      '#14000000',
    );
    expect(
      model.resolve('component.button.secondary.hover-overlay', 'dark'),
      '#14FFFFFF',
    );
    expect(
      model.resolve(
        'component.button.secondary.hover-overlay',
        'high-contrast-light',
      ),
      '#1F000000',
    );
    expect(
      model.resolve(
        'component.button.secondary.hover-overlay',
        'high-contrast-dark',
      ),
      '#1FFFFFFF',
    );
    expect(model.resolve('component.text-field.label', 'light'), '#B3000000');
    expect(model.resolve('component.text-field.hint', 'dark'), '#99FFFFFF');
    expect(
      model.resolve('component.text-field.hover-border', 'light'),
      '#26000000',
    );
    expect(
      model.resolve('component.text-field.focus-outline', 'light'),
      '#000000',
    );
    expect(
      model.resolve('component.text-field.focus-outline', 'high-contrast-dark'),
      '#FFFFFF',
    );
    expect(
      model.resolve('component.text-field.clear-background', 'dark'),
      '#99FFFFFF',
    );
    expect(
      model.resolve(
        'component.text-field.clear-foreground',
        'high-contrast-dark',
      ),
      '#000000',
    );
    expect(
      model.resolve('component.segmented.container-surface', 'light'),
      '#FFF5F5F5',
    );
    expect(
      model.resolve('component.segmented.selected-indicator', 'dark'),
      '#FF5B7FFF',
    );
    expect(
      model.resolve('component.segmented.focus-outline', 'high-contrast-dark'),
      '#FFFFFFFF',
    );
    expect(
      model.resolve(
        'component.segmented.selected-shadow',
        'high-contrast-light',
      ),
      '#00000000',
    );
    expect(
      model.resolve('component.tab.selected-indicator', 'light'),
      '#000000',
    );
    expect(
      model.resolve('component.tab.unselected-foreground', 'dark'),
      '#DDFFFFFF',
    );
    expect(
      model.resolve('component.tab.hover-overlay', 'high-contrast-light'),
      '#1F000000',
    );
    expect(
      model.resolve('component.tab.focus-outer-ring', 'high-contrast-dark'),
      '#FFFFFF',
    );
  });

  test('TabBar approved token drift is rejected', () {
    final fixture = _copyCurrentContractFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));
    final tokenFile = File('${fixture.path}/contracts/tokens/blab.tokens.yaml');
    tokenFile.writeAsStringSync(
      tokenFile.readAsStringSync().replaceFirst(
        'id: "component.tab.hover-overlay"\n'
            '      type: "color"\n'
            '      modes:\n'
            '        light: "#14000000"',
        'id: "component.tab.hover-overlay"\n'
            '      type: "color"\n'
            '      modes:\n'
            '        light: "#15000000"',
      ),
    );

    expect(
      validateBlabContract(fixture),
      contains(
        'TabBar token drift for component.tab.hover-overlay light: '
        'expected #14000000, found #15000000.',
      ),
    );
  });

  test('SegmentedControl approved token drift is rejected', () {
    final fixture = _copyCurrentContractFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));
    final tokenFile = File('${fixture.path}/contracts/tokens/blab.tokens.yaml');
    tokenFile.writeAsStringSync(
      tokenFile.readAsStringSync().replaceFirst(
        'light: "#FFF5F5F5"',
        'light: "#FFF4F4F4"',
      ),
    );

    expect(
      validateBlabContract(fixture),
      contains(
        'SegmentedControl token drift for '
        'component.segmented.container-surface light: '
        'expected #FFF5F5F5, found #FFF4F4F4.',
      ),
    );
  });

  test(
    'SegmentedControl layout and public widget compatibility drift is rejected',
    () {
      final fixture = _copyCurrentContractFixture();
      addTearDown(() => fixture.deleteSync(recursive: true));
      final contractFile = File('${fixture.path}/contracts/blab.design.yaml');
      contractFile.writeAsStringSync(
        contractFile
            .readAsStringSync()
            .replaceFirst(
              'narrow_width_behavior: "conditional-owned-horizontal-scroll-no-target-shrink"',
              'narrow_width_behavior: "shrink-targets"',
            )
            .replaceFirst(
              'controller: "owned-non-primary-horizontal"',
              'controller: "primary"',
            )
            .replaceFirst(
              'public_widget_base: "StatelessWidget"',
              'public_widget_base: "StatefulWidget"',
            ),
      );

      final errors = validateBlabContract(fixture);
      expect(
        errors.any(
          (error) => error.contains(
            'component_decisions.segmented-control.geometry.narrow_width_behavior',
          ),
        ),
        isTrue,
      );
      expect(
        errors.any(
          (error) => error.contains(
            'component_decisions.segmented-control.overflow.controller',
          ),
        ),
        isTrue,
      );
      expect(
        errors.any(
          (error) => error.contains(
            'component_decisions.segmented-control.additive_api.public_widget_base',
          ),
        ),
        isTrue,
      );
    },
  );

  test('standard ThemeExtension values equal hand-maintained Dart sources', () {
    expect(BLabTokenTheme.light.surfaceBase, BLabColors.scaffoldLight);
    expect(BLabTokenTheme.dark.surfaceBase, BLabColors.scaffoldDark);
    expect(BLabTokenTheme.light.surfaceRaised, BLabColors.surfaceLight);
    expect(BLabTokenTheme.dark.surfaceRaised, BLabColors.surfaceDark);
    expect(BLabTokenTheme.light.textPrimary, BLabColors.textPrimaryLight);
    expect(BLabTokenTheme.dark.textPrimary, BLabColors.textPrimaryDark);
    expect(BLabTokenTheme.light.textSecondary, BLabColors.textSecondaryLight);
    expect(BLabTokenTheme.dark.textSecondary, BLabColors.textSecondaryDark);
    expect(BLabTokenTheme.light.borderDefault, BLabColors.borderDefaultLight);
    expect(BLabTokenTheme.dark.borderDefault, BLabColors.borderDefaultDark);
    expect(BLabTokenTheme.light.actionPrimary, BLabColors.actionPrimary);
    expect(BLabTokenTheme.dark.actionPrimary, BLabColors.actionPrimary);
    expect(BLabTokenTheme.light.glassBlur, BLabGlass.blur);
    expect(BLabTokenTheme.dark.glassSaturation, BLabGlass.saturation);
  });

  test('high-contrast ThemeExtension values equal approved mappings', () {
    const light = BLabTokenTheme.highContrastLight;
    const dark = BLabTokenTheme.highContrastDark;

    expect(light.surfaceBase, const Color(0xFFFFFFFF));
    expect(dark.surfaceBase, const Color(0xFF121212));
    expect(light.textPrimary, const Color(0xFF000000));
    expect(dark.textPrimary, const Color(0xFFFFFFFF));
    expect(light.borderDefault, const Color(0xFF000000));
    expect(dark.borderDefault, const Color(0xFFFFFFFF));
    expect(light.focusRing, const Color(0xFF000000));
    expect(dark.focusRing, const Color(0xFFFFFFFF));
    expect(light.actionPrimaryForeground, const Color(0xFF000000));
    expect(dark.actionDestructiveForeground, const Color(0xFF000000));
    expect(light.disabledForeground, const Color(0xFF6B7280));
    expect(dark.disabledForeground, const Color(0xFF9CA3AF));
    expect(light.glassBlur, 0);
    expect(dark.glassSaturation, 1);
    expect(light.glassHighlight, isNull);
    expect(dark.glassShadowEnabled, isFalse);
  });

  test('generation is deterministic and checked-in outputs have no drift', () {
    final first = buildGeneratedTokenOutputs(Directory.current);
    final second = buildGeneratedTokenOutputs(Directory.current);

    expect(second, first);
    expect(findGeneratedTokenDrift(Directory.current, first), isEmpty);
    for (final path in generatedTokenPaths) {
      if (path.endsWith('.json')) {
        final document = jsonDecode(first[path]!) as Map<String, Object?>;
        final generated = document['_generated'] as Map<String, Object?>;
        expect(document['version'], isNotNull);
        expect(generated['source_checksum_sha256'], hasLength(64));
        expect(generated['content_checksum_sha256'], hasLength(64));
      } else {
        expect(first[path], contains('Contract version: 0.2.0'));
        expect(first[path], contains('Content checksum (SHA-256, body only):'));
      }
    }
  });

  test(
    'generated Dart theme is canonical dart format on first write',
    () async {
      final fixture = Directory.systemTemp.createTempSync(
        'blab-generated-theme-format-',
      );
      addTearDown(() => fixture.deleteSync(recursive: true));
      final generatedTheme =
          File('${fixture.path}/$generatedThemeExtensionPath')
            ..createSync(recursive: true)
            ..writeAsStringSync(
              buildGeneratedTokenOutputs(
                Directory.current,
              )[generatedThemeExtensionPath]!,
            );

      final result = await Process.run('dart', <String>[
        'format',
        '--output=none',
        '--set-exit-if-changed',
        generatedTheme.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    },
  );

  test('manual generated-output drift is rejected in an isolated fixture', () {
    final expected = buildGeneratedTokenOutputs(Directory.current);
    final fixture = Directory.systemTemp.createTempSync(
      'blab-generated-drift-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    writeGeneratedTokenOutputs(fixture, expected);
    File(
      '${fixture.path}/$generatedCssPath',
    ).writeAsStringSync('\n/* deliberate mutation */\n', mode: FileMode.append);

    expect(
      findGeneratedTokenDrift(fixture, expected),
      contains('$generatedCssPath differs from deterministic generation'),
    );
  });

  test(
    'generated writes reject an output symlink without modifying its target',
    () {
      final expected = buildGeneratedTokenOutputs(Directory.current);
      final fixture = Directory.systemTemp.createTempSync(
        'blab-generated-symlink-',
      );
      final outside = Directory.systemTemp.createTempSync(
        'blab-generated-outside-',
      );
      addTearDown(() => fixture.deleteSync(recursive: true));
      addTearDown(() => outside.deleteSync(recursive: true));

      final outsideTarget = File('${outside.path}/protected.dart')
        ..writeAsStringSync('outside-sentinel');
      final earlierOutput = File('${fixture.path}/$generatedTokenDataPath')
        ..createSync(recursive: true)
        ..writeAsStringSync('earlier-output-sentinel');
      final outputLink = Link('${fixture.path}/$generatedCssPath');
      outputLink.parent.createSync(recursive: true);
      outputLink.createSync(outsideTarget.path);

      expect(
        () => writeGeneratedTokenOutputs(fixture, expected),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Generated output target must not be a symbolic link'),
          ),
        ),
      );
      expect(outsideTarget.readAsStringSync(), 'outside-sentinel');
      expect(earlierOutput.readAsStringSync(), 'earlier-output-sentinel');
      expect(
        File('${fixture.path}/$generatedThemeExtensionPath').existsSync(),
        isFalse,
      );
    },
  );

  test('the protected DESIGN.md remains byte-identical', () {
    final digest = sha256
        .convert(File('DESIGN.md').readAsBytesSync())
        .toString();

    expect(
      digest,
      '3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4',
    );
  });
}

Directory _createTypedFixture(String tokenYaml, {String outputs = '[]'}) {
  final fixture = Directory.systemTemp.createTempSync('blab-phase1a-fixture-');
  File('${fixture.path}/contracts/schema/blab.design.schema.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
schema: "blab.contract-validation/v1"
rules:
  - path: "schema"
    type: "string"
    equals: "blab.design/v1"
''');
  final outputYaml = outputs == '[]' ? 'outputs: []' : 'outputs:\n$outputs';
  File('${fixture.path}/contracts/blab.design.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
schema: "blab.design/v1"
values:
  token_layers: {}
  reference_manifest: []
tokens:
$tokenYaml
$outputYaml
''');
  return fixture;
}

Directory _copyCurrentContractFixture() {
  final fixture = Directory.systemTemp.createTempSync('blab-phase1a-current-');
  for (final path in ['contracts', 'docs', 'lib']) {
    _copyDirectory(Directory(path), Directory('${fixture.path}/$path'));
  }
  File('LICENSE').copySync('${fixture.path}/LICENSE');
  return fixture;
}

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final targetPath =
        '${destination.path}/${entity.uri.pathSegments.where((part) => part.isNotEmpty).last}';
    if (entity is Directory) {
      _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      entity.copySync(targetPath);
    } else {
      throw StateError('Unsupported fixture entity: ${entity.path}');
    }
  }
}
