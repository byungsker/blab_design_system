import 'dart:io';

import 'package:blab_design_system/blab_design_system.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/src/contract_validation.dart';
import '../tool/src/public_api_snapshot.dart';

void main() {
  test('the public package library exposes Blab tokens and components', () {
    expect(BLabColors.primary, isNotNull);
    expect(BLabTheme.light.useMaterial3, isTrue);
    expect(BLabButtonVariant.values, [
      BLabButtonVariant.primary,
      BLabButtonVariant.secondary,
      BLabButtonVariant.destructive,
    ]);
  });

  test('Material elevated buttons use the approved primary foreground', () {
    for (final (theme, tokens) in [
      (BLabTheme.light, BLabTokenTheme.light),
      (BLabTheme.dark, BLabTokenTheme.dark),
    ]) {
      final style = theme.elevatedButtonTheme.style!;
      expect(style.backgroundColor!.resolve(const {}), tokens.actionPrimary);
      expect(
        style.foregroundColor!.resolve(const {}),
        tokens.actionPrimaryForeground,
      );
    }
  });

  test('the approved Blab contract is valid and reference-locked', () {
    expect(validateBlabContract(Directory.current), isEmpty);
  });

  test('contract validation rejects incomplete reference coverage', () {
    final fixture = _createContractFixture(
      declaredPath: 'declared.txt',
      manifestPath: 'manifest-only.txt',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));

    expect(
      validateBlabContract(fixture),
      contains(
        'Declared value source is missing from reference_manifest: '
        'declared.txt',
      ),
    );
  });

  test('contract validation rejects a symlink that escapes the repository', () {
    final fixture = Directory.systemTemp.createTempSync('blab-contract-root-');
    final outside = Directory.systemTemp.createTempSync(
      'blab-contract-outside-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    addTearDown(() => outside.deleteSync(recursive: true));

    final outsideFile = File('${outside.path}/outside.txt')
      ..writeAsStringSync('outside');
    final linkPath = '${fixture.path}/linked.txt';
    Link(linkPath).createSync(outsideFile.path);
    _writeMinimalContractFiles(
      fixture,
      declaredPath: 'linked.txt',
      manifestPath: 'linked.txt',
      manifestDigest: sha256.convert(outsideFile.readAsBytesSync()).toString(),
    );

    expect(
      validateBlabContract(fixture),
      contains(
        'Referenced Phase 0 value source escapes the repository: linked.txt',
      ),
    );
  });

  test('contract validation rejects an escaping glossary symlink', () {
    final fixture = _createContractFixture(
      declaredPath: 'value.txt',
      manifestPath: 'value.txt',
    );
    final outside = Directory.systemTemp.createTempSync(
      'blab-glossary-outside-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    addTearDown(() => outside.deleteSync(recursive: true));

    final outsideGlossary = File('${outside.path}/blab.terms.yaml')
      ..writeAsStringSync('''
schema: "blab.glossary/v1"
terms:
  - id: "blab-brand"
    canonical: "Blab"
''');
    final glossaryLink = Link(
      '${fixture.path}/contracts/glossary/blab.terms.yaml',
    );
    glossaryLink.parent.createSync(recursive: true);
    glossaryLink.createSync(outsideGlossary.path);
    final valueFile = File('${fixture.path}/value.txt');
    _writeMinimalContractFiles(
      fixture,
      declaredPath: 'value.txt',
      manifestPath: 'value.txt',
      manifestDigest: sha256.convert(valueFile.readAsBytesSync()).toString(),
      glossaryRef: 'contracts/glossary/blab.terms.yaml',
    );

    expect(
      validateBlabContract(fixture),
      contains(
        'Glossary source escapes the repository: '
        'contracts/glossary/blab.terms.yaml',
      ),
    );
  });

  test(
    'the checked-in public API snapshot has no analyzer-visible drift',
    () async {
      final repositoryRoot = Directory.current;
      final generated = await buildPublicApiSnapshot(repositoryRoot);
      final checkedIn = File(
        '${repositoryRoot.path}/$publicApiSnapshotPath',
      ).readAsStringSync();

      expect(generated, checkedIn);
      expect(
        generated,
        isNot(
          contains('BLabInteractiveTargetPolicy.BLabInteractiveTargetPolicy.'),
        ),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('named API constructors are emitted exactly once', () {
    expect(
      formatPublicApiConstructorName(
        interfaceName: 'BLabInteractiveTargetPolicy',
        constructorName: 'documentedException',
      ),
      'BLabInteractiveTargetPolicy.documentedException',
    );
    expect(
      formatPublicApiConstructorName(
        interfaceName: 'BLabInteractiveTargetPolicy',
        constructorName: 'new',
      ),
      'BLabInteractiveTargetPolicy',
    );
  });
}

Directory _createContractFixture({
  required String declaredPath,
  required String manifestPath,
}) {
  final fixture = Directory.systemTemp.createTempSync('blab-contract-fixture-');
  final manifestFile = File('${fixture.path}/$manifestPath')
    ..createSync(recursive: true)
    ..writeAsStringSync('manifest');
  File('${fixture.path}/$declaredPath')
    ..createSync(recursive: true)
    ..writeAsStringSync('declared');
  _writeMinimalContractFiles(
    fixture,
    declaredPath: declaredPath,
    manifestPath: manifestPath,
    manifestDigest: sha256.convert(manifestFile.readAsBytesSync()).toString(),
  );
  return fixture;
}

void _writeMinimalContractFiles(
  Directory root, {
  required String declaredPath,
  required String manifestPath,
  required String manifestDigest,
  String? glossaryRef,
}) {
  final schemaFile = File(
    '${root.path}/contracts/schema/blab.design.schema.yaml',
  )..createSync(recursive: true);
  schemaFile.writeAsStringSync('''
schema: "blab.contract-validation/v1"
rules:
  - path: "schema"
    type: "string"
    equals: "blab.design/v1"
''');

  final contractFile = File('${root.path}/contracts/blab.design.yaml')
    ..createSync(recursive: true);
  final localization = glossaryRef == null
      ? ''
      : '''
localization:
  glossary_ref: "$glossaryRef"
''';
  contractFile.writeAsStringSync('''
schema: "blab.design/v1"
values:
  token_layers:
    primitive:
      current_value_refs:
        - "$declaredPath"
  reference_manifest:
    - path: "$manifestPath"
      sha256: "$manifestDigest"
outputs: []
$localization
''');
}
