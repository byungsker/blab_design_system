import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import '../tool/src/phase5_compatibility.dart';
import '../tool/src/phase5_baseline_validation.dart';
import '../tool/src/phase5_inventory_scope.dart';
import '../tool/src/phase5_readiness_validation.dart';
import '../tool/capture_package_dry_run.dart' as package_dry_run_capture;

const _zeroSha256 =
    '0000000000000000000000000000000000000000000000000000000000000000';

void main() {
  group('Phase 5 bounded canonical contract', () {
    test('records local preparation without conformance or release claims', () {
      final contract =
          loadYaml(File('contracts/blab.design.yaml').readAsStringSync())
              as YamlMap;
      final capabilities = contract['capabilities'] as YamlMap;
      expect(
        (capabilities['phase_status'] as YamlMap)['phase-5'],
        'local-preparation-implemented-exit-blocked',
      );
      final migrationAndRelease = (capabilities['entries'] as YamlList)
          .whereType<YamlMap>()
          .singleWhere((entry) => entry['id'] == 'migration-and-release');
      expect(
        migrationAndRelease['status'],
        'local-preparation-implemented-exit-blocked',
      );
      final scope = migrationAndRelease['scope'] as YamlMap;
      expect(scope['phase5_exit_complete'], isFalse);
      expect(scope['conformance_claimed'], isFalse);
      expect(scope['release_authorized'], isFalse);
      expect(scope['publication_authorized'], isFalse);

      final pressable =
          (contract['component_decisions'] as YamlMap)['pressable-card']
              as YamlMap;
      final publicApi = pressable['public_api'] as YamlMap;
      expect(
        publicApi['constructor_on_tap_input'],
        'required-nullable-controls-effective-actionability',
      );
      expect(
        publicApi['null_input_exported_on_tap_behavior'],
        'stable-no-op-must-not-signal-actionability',
      );

      final assetsAndFonts = contract['assets_and_fonts'] as YamlMap;
      final flutterPackage = assetsAndFonts['flutter_package'] as YamlMap;
      expect(flutterPackage['bundles_font_files'], isFalse);
      expect(flutterPackage['fetches_font_files'], isFalse);
      expect(
        flutterPackage['production_self_host_fallback_or_remote_strategy'],
        'unresolved-design-legal-product-decision',
      );
      expect(contract['license']['release_or_publication_authorized'], isFalse);

      final readiness =
          loadYaml(
                File(
                  'contracts/release/phase5-readiness.yaml',
                ).readAsStringSync(),
              )
              as YamlMap;
      final readinessMetadata = readiness['metadata'] as YamlMap;
      expect(readinessMetadata['package_version'], '0.2.0');
      expect(readinessMetadata['release_target'], '0.2.0-repository-only');
      final openBlockers = (readiness['blockers'] as YamlList)
          .whereType<YamlMap>()
          .map((entry) => entry['id']);
      expect(
        openBlockers,
        isNot(contains('canonical-repository-owner-and-remote')),
      );
      final resolvedGates = (readiness['resolved_gates'] as YamlList)
          .whereType<YamlMap>()
          .toList();
      expect(resolvedGates, hasLength(2));
      final repositoryGate = resolvedGates.singleWhere(
        (entry) => entry['id'] == 'canonical-repository-owner-and-remote',
      );
      expect(repositoryGate['id'], 'canonical-repository-owner-and-remote');
      expect(
        repositoryGate['canonical_repository'],
        'https://github.com/byungsker/blab_design_system',
      );
      expect(
        repositoryGate['boundary'],
        contains('does not establish copyright ownership'),
      );
      expect(
        resolvedGates.singleWhere(
          (entry) => entry['id'] == 'exact-target-delivery-contract',
        )['target_version'],
        '0.2.0',
      );

      final activeTdc =
          loadYaml(
                File(
                  'contracts/delivery/blab-design-system-0.2.0.yaml',
                ).readAsStringSync(),
              )
              as YamlMap;
      final delivery = activeTdc['delivery'] as YamlMap;
      expect(delivery['delivery_unit'], 'blab-design-system');
      expect(delivery['delivery_profile'], 'package-or-local');
      expect(delivery['target_version'], '0.2.0');
      expect(delivery['expected_base_branch'], 'main');
      expect(
        delivery['protected_design_restoration_sha256'],
        '3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4',
      );
      expect(
        delivery['expected_head_branch'],
        'codex/feature/blab-design-system/0.2.0/'
        'astryx-capability-adoption',
      );
      final authority = activeTdc['authority'] as YamlMap;
      expect(authority['draft_pull_request'], isTrue);
      expect(authority['protected_design_restoration'], isTrue);
      expect(authority['merge'], isFalse);
      expect(authority['publication'], isFalse);
    });

    test(
      'diff hygiene uses the active TDC base and rejects caller overrides',
      () async {
        final activeTdc =
            loadYaml(
                  File(
                    'contracts/delivery/blab-design-system-0.2.0.yaml',
                  ).readAsStringSync(),
                )
                as YamlMap;
        final expectedBase =
            ((activeTdc['delivery'] as YamlMap)['expected_base_sha'] as String);

        final result = await Process.run('dart', <String>[
          'run',
          'tool/validate_diff_hygiene.dart',
        ]);
        expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
        expect(
          result.stdout,
          contains('BLDS diff hygiene passed against $expectedBase'),
        );

        final rejectedOverride = await Process.run(
          'dart',
          <String>['run', 'tool/validate_diff_hygiene.dart'],
          environment: <String, String>{
            ...Platform.environment,
            'BLDS_DIFF_BASE': 'HEAD',
          },
        );
        expect(rejectedOverride.exitCode, 1);
        expect(
          '${rejectedOverride.stdout}${rejectedOverride.stderr}',
          contains('could not resolve a comparison base'),
        );
      },
    );

    test('package identity ignores only host-dependent compressed size', () {
      final recorded = <String, Object?>{
        'schema': 'blab.package-dry-run-inventory/v1',
        'compressed_archive_size': '123 KB',
        'compressed_archive_size_scope':
            'informational-platform-dependent-local-observation',
        'file_count': 82,
        'name_manifest_sha256': 'names',
        'content_manifest_sha256': 'content',
      };
      final anotherHost = Map<String, Object?>.of(recorded)
        ..['compressed_archive_size'] = '121 KB';
      expect(
        package_dry_run_capture.packageDryRunInventoriesMatchStable(
          jsonEncode(recorded),
          anotherHost,
        ),
        isTrue,
      );

      final changedContent = Map<String, Object?>.of(anotherHost)
        ..['content_manifest_sha256'] = 'changed';
      expect(
        package_dry_run_capture.packageDryRunInventoriesMatchStable(
          jsonEncode(recorded),
          changedContent,
        ),
        isFalse,
      );
    });
  });

  group('Phase 5 compatibility classifier', () {
    test('current repository preserves two approved breaking corrections', () {
      final report = classifyRepositoryCompatibility(Directory.current);
      expect(report.violations, isEmpty);
      expect(report.classifications['breaking'], 2);
      expect(report.classifications['deprecated'], isNull);
      expect(
        report.classificationSupport['deprecated'],
        'not-supported-in-phase5-classifier',
      );
      expect(report.classifications['additive'], 469);
      final breaking = report.changes
          .where(
            (change) =>
                change.classification == CompatibilityClassification.breaking,
          )
          .toList();
      expect(
        breaking.map((change) => change.id),
        containsAll(<String>[
          'typed:semantic.action.primary-foreground',
          'typed:semantic.action.destructive-foreground',
        ]),
      );
      expect(
        breaking.every(
          (change) =>
              change.surface == CompatibilitySurface.token &&
              change.kind == CompatibilityChangeKind.value,
        ),
        isTrue,
      );
    });

    test('deprecated detection cannot claim implementation or numeric zero', () {
      final fixture = _fixture();
      addTearDown(() => fixture.deleteSync(recursive: true));
      File('${fixture.path}/contracts/compatibility/policy.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
classifications:
  deprecated:
    support_status: "implemented"
    result_status: "zero"
    limitation: ""
''');
      expect(
        validateDeprecatedSupportOnly(fixture),
        contains(
          'Deprecated classification must remain typed unknown and unsupported '
          'until a deterministic detector exists.',
        ),
      );
    });

    test('deprecated numeric or absence documentation claims fail closed', () {
      final fixture = _fixture();
      addTearDown(() => fixture.deleteSync(recursive: true));
      File('${fixture.path}/contracts/compatibility/policy.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
classifications:
  deprecated:
    support_status: "not-supported-in-phase5-classifier"
    result_status: "unknown-not-detected"
    limitation: "A deterministic detector is not implemented."
''');
      File('${fixture.path}/docs/status.md')
        ..createSync(recursive: true)
        ..writeAsStringSync('Current result: 0 deprecated, 0 breaking.\n');
      expect(
        validateDeprecatedSupportOnly(fixture),
        contains(
          'Deprecated documentation must use typed unknown/unsupported, not '
          'numeric or absence claims: docs/status.md.',
        ),
      );
    });

    test(
      'baseline Git objects and API reproduction match the recorded evidence',
      () async {
        expect(await validatePhase5Baselines(Directory.current), isEmpty);
      },
    );

    test(
      'baseline and checksum co-mutation cannot replace Git truth',
      () async {
        final fixture = _fixture();
        addTearDown(() => fixture.deleteSync(recursive: true));
        expect(
          Process.runSync('git', [
            'init',
            '-q',
          ], workingDirectory: fixture.path).exitCode,
          0,
        );
        File('${fixture.path}/docs/design/tokens.css')
          ..createSync(recursive: true)
          ..writeAsStringSync(':root { --trusted: #000; }\n');
        expect(
          Process.runSync('git', [
            'add',
            'docs/design/tokens.css',
          ], workingDirectory: fixture.path).exitCode,
          0,
        );
        expect(
          Process.runSync('git', [
            '-c',
            'user.name=BLDS Test',
            '-c',
            'user.email=blds-test@example.invalid',
            'commit',
            '-q',
            '-m',
            'fixture',
          ], workingDirectory: fixture.path).exitCode,
          0,
        );
        final commit =
            (Process.runSync('git', [
                      'rev-parse',
                      'HEAD',
                    ], workingDirectory: fixture.path).stdout
                    as String)
                .trim();
        final mutatedTokens =
            File('${fixture.path}/contracts/compatibility/baselines/tokens.css')
              ..createSync(recursive: true)
              ..writeAsStringSync(':root { --mutated: #fff; }\n');
        final apiBaseline =
            File('${fixture.path}/contracts/compatibility/baselines/api.txt')
              ..writeAsStringSync(
                File(
                  'contracts/compatibility/baselines/head-ee78fbe.api.txt',
                ).readAsStringSync(),
              );
        File('${fixture.path}/contracts/compatibility/baseline-provenance.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
metadata:
  mutation_policy: "never-regenerate-in-place"
  admission_workflow: "contracts/compatibility/baseline-admission.template.yaml"
origin:
  commit: "$commit"
  git_object_validation: "required-cat-file-commit"
api:
  path: "contracts/compatibility/baselines/api.txt"
  sha256: "${sha256File(apiBaseline)}"
  reproducibility_check: "analyzer-regeneration-from-origin-commit-lib-blobs-with-pinned-local-package-config-no-network"
tokens:
  path: "contracts/compatibility/baselines/tokens.css"
  source_path_at_origin: "docs/design/tokens.css"
  sha256: "${sha256File(mutatedTokens)}"
  reproducibility_check: "byte-equality-with-git-show-origin.commit-source_path_at_origin"
''');
        _writeBaselineAdmissionFixture(fixture);

        expect(
          await validatePhase5Baselines(fixture, reproduceApi: false),
          contains(
            'Token baseline does not equal origin.commit Git blob: '
            'docs/design/tokens.css.',
          ),
        );
      },
    );

    test('checksum-only snapshot header drift is ignored', () {
      const body = '\nclass Example\n  field final int value\n\n';
      const before =
          '# Public API input checksum (SHA-256): '
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n'
          '# Content checksum (SHA-256, body only): '
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\n'
          '$body';
      const after =
          '# Public API input checksum (SHA-256): '
          'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc\n'
          '# Content checksum (SHA-256, body only): '
          'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd\n'
          '$body';
      expect(classifyApiCompatibility(before, after), isEmpty);
    });

    test('public API removal fails closed as breaking', () {
      const before =
          'class Example\n'
          '  field final int value\n\n';
      const after = 'class Example\n\n';
      final changes = classifyApiCompatibility(before, after);
      expect(
        changes,
        contains(
          isA<CompatibilityChange>()
              .having(
                (change) => change.kind,
                'kind',
                CompatibilityChangeKind.removal,
              )
              .having(
                (change) => change.classification,
                'classification',
                CompatibilityClassification.breaking,
              ),
        ),
      );
    });

    test('public API parameter type change fails closed as breaking', () {
      const before =
          'class Example\n'
          '  method void run(int value)\n\n';
      const after =
          'class Example\n'
          '  method void run(String value)\n\n';
      final changes = classifyApiCompatibility(before, after);
      expect(
        changes.single.classification,
        CompatibilityClassification.breaking,
      );
      expect(changes.single.kind, CompatibilityChangeKind.signature);
    });

    test('token value and semantic changes fail closed as breaking', () {
      final changes = classifyTokenEntryMaps(
        const {
          'css:--blab-example:light': 'color|#000000',
          'typed:semantic.example': 'color|value=#000000',
        },
        const {
          'css:--blab-example:light': 'color|#FFFFFF',
          'typed:semantic.example': 'dimension|value={primitive.size}',
        },
      );
      expect(
        changes.map((change) => change.kind),
        containsAll([
          CompatibilityChangeKind.value,
          CompatibilityChangeKind.semantic,
        ]),
      );
      expect(
        changes.every(
          (change) =>
              change.classification == CompatibilityClassification.breaking,
        ),
        isTrue,
      );
    });
  });

  group('Phase 5 registry and rights negative gates', () {
    test('repository has no categorical unsigned Astryx provenance claim', () {
      expect(validateUnsignedProvenanceClaimsOnly(Directory.current), isEmpty);
    });

    test('categorical unsigned Astryx provenance claim fails closed', () {
      for (final claim in const [
        'The owner attests that it did not copy Astryx source.',
        'The implementation did not copy Astryx assets.',
        'Astryx values were not adopted by this repository.',
        'This package was developed without Astryx source.',
      ]) {
        final fixture = _fixture();
        addTearDown(() => fixture.deleteSync(recursive: true));
        _writeProvenanceClaimFixture(fixture, claim);
        expect(
          validateUnsignedProvenanceClaimsOnly(fixture),
          contains('Categorical unsigned provenance claim remains: README.md.'),
          reason: claim,
        );
      }
    });

    test(
      'categorical MIT ownership phrase fails closed while authority is unknown',
      () {
        final fixture = _fixture();
        addTearDown(() => fixture.deleteSync(recursive: true));
        _writeLicenseOwnershipClaimFixture(fixture);
        expect(
          validateUnknownLicenseOwnershipClaimsOnly(fixture),
          contains(
            'Categorical MIT ownership claim remains while project license '
            'authority is unresolved: README.md.',
          ),
        );
      },
    );

    test(
      'remote CSS import ledger is complete and matches package disposition',
      () {
        expect(validateRemoteCssImportsOnly(Directory.current), isEmpty);
      },
    );

    test('unrecorded remote CSS import fails closed', () {
      final fixture = _fixture();
      addTearDown(() => fixture.deleteSync(recursive: true));
      _writeRemoteCssFixture(fixture);
      expect(
        validateRemoteCssImportsOnly(fixture),
        contains('Remote CSS import inventory is missing path: sample.css.'),
      );
    });

    test(
      'recorded package archive preserves runtime and excludes fixtures',
      () {
        final inventory = File(
          'contracts/release/package-dry-run-inventory.json',
        );
        expect(inventory.existsSync(), isTrue);
        final source = inventory.readAsStringSync();
        for (final included in const [
          'lib/blab_design_system.dart',
          'contracts/compatibility/policy.yaml',
          'contracts/release/package-composition-candidate.yaml',
          'LICENSE',
          'README.md',
          'CHANGELOG.md',
          'THIRD_PARTY_NOTICES.md',
          'doc/README.md',
        ]) {
          expect(source, contains('"$included"'));
        }
        for (final excluded in const [
          'test/assets/fonts/NotoSansKR[wght].ttf',
          'test/phase5_readiness_test.dart',
          'tool/verify.dart',
          'AGENTS.md',
          'DESIGN.md',
          'analysis_options.yaml',
          'test/goldens/candidates/phase4-light.png',
          'generated/blab-capabilities.v1.json',
          'api/blab_design_system.api.txt',
          'contracts/approvals/',
          'contracts/delivery/',
          'contracts/legal/attestations/',
          'contracts/legal/file-origin-map.yaml',
          'contracts/sbom/',
          'contracts/release/package-dry-run',
          'contracts/compatibility/baselines/',
          'contracts/compatibility/baseline-provenance.yaml',
          'contracts/compatibility/baseline-admission.template.yaml',
          '.codex/',
          'build/',
        ]) {
          expect(source, isNot(contains('"$excluded"')));
        }
      },
    );

    test(
      'readiness package summary fails on file-count and clean-state drift',
      () {
        final fixture = _fixture();
        addTearDown(() => fixture.deleteSync(recursive: true));
        for (final path in const [
          'contracts/release/phase5-readiness.yaml',
          'contracts/release/package-dry-run.yaml',
          'contracts/release/package-dry-run-inventory.json',
        ]) {
          File('${fixture.path}/$path')
            ..createSync(recursive: true)
            ..writeAsStringSync(File(path).readAsStringSync());
        }
        expect(validatePackageDryRunOnly(fixture), isEmpty);

        final readiness = File(
          '${fixture.path}/contracts/release/phase5-readiness.yaml',
        );
        final canonical = readiness.readAsStringSync();
        for (final drift in const [
          '81-files-deterministic-digests-clean-git-no-publication',
          '82-files-deterministic-digests-dirty-git-warning-no-publication',
        ]) {
          readiness.writeAsStringSync(
            canonical.replaceFirst(
              '82-files-deterministic-digests-clean-git-no-publication',
              drift,
            ),
          );
          expect(
            validatePackageDryRunOnly(fixture),
            contains(
              'Phase 5 readiness package summary disagrees with canonical '
              'package inventory.',
            ),
            reason: drift,
          );
        }
      },
    );

    test('stale migration input is rejected', () {
      final fixture = _fixture();
      addTearDown(() => fixture.deleteSync(recursive: true));
      _writeMigrationFixture(fixture, inputHash: _zeroSha256);
      expect(
        validateMigrationRegistryOnly(fixture),
        contains('Stale migration rehearsal identity: current.txt.'),
      );
    });

    test('rollback identity mismatch is rejected', () {
      final fixture = _fixture();
      addTearDown(() => fixture.deleteSync(recursive: true));
      _writeMigrationFixture(fixture, rollbackHash: _zeroSha256);
      expect(
        validateMigrationRegistryOnly(fixture),
        contains('Rollback artifact identity mismatch: baseline.txt.'),
      );
      expect(
        rehearsePhase5Migration(fixture).errors,
        contains('Rollback artifact identity mismatch: baseline.txt.'),
      );
    });

    test('migration input and rollback paths reject traversal and symlinks '
        'without outside access and clean disposable state', () {
      final outside = _fixture();
      addTearDown(() => outside.deleteSync(recursive: true));
      final sentinel = File('${outside.path}/sentinel.txt')
        ..writeAsStringSync('outside-unchanged');
      final outsideName = outside.path.split(Platform.pathSeparator).last;
      final unsafePaths = <String>[
        '',
        '/${sentinel.path.split('/').where((part) => part.isNotEmpty).join('/')}',
        'C:/outside/sentinel.txt',
        '//server/share/sentinel.txt',
        '../$outsideName/sentinel.txt',
        './current.txt',
      ];
      for (final role in const ['input', 'rollback']) {
        for (final unsafePath in unsafePaths) {
          final fixture = _fixture();
          addTearDown(() => fixture.deleteSync(recursive: true));
          _writeUnsafeMigrationFixture(
            fixture,
            inputPath: role == 'input' ? unsafePath : 'current.txt',
            rollbackPath: role == 'rollback' ? unsafePath : 'baseline.txt',
          );
          final beforeTemps = _rehearsalTempPaths();
          final validation = validateMigrationRegistryOnly(fixture);
          final rehearsal = rehearsePhase5Migration(fixture);
          expect(
            [...validation, ...rehearsal.errors].join('\n'),
            contains(
              role == 'input'
                  ? 'Unsafe migration input'
                  : 'Unsafe rollback artifact',
            ),
            reason: '$role:$unsafePath',
          );
          expect(sentinel.readAsStringSync(), 'outside-unchanged');
          expect(_rehearsalTempPaths(), beforeTemps);
        }
      }

      for (final linkRole in const [
        'input-parent',
        'input-source',
        'rollback-parent',
        'rollback-source',
      ]) {
        final fixture = _fixture();
        addTearDown(() => fixture.deleteSync(recursive: true));
        final sourceLink = linkRole.endsWith('source');
        final isInput = linkRole.startsWith('input');
        final linkPath = sourceLink ? 'sentinel-link.txt' : 'outside-link';
        Link(
          '${fixture.path}/$linkPath',
        ).createSync(sourceLink ? sentinel.path : outside.path);
        final unsafePath = sourceLink ? linkPath : '$linkPath/sentinel.txt';
        _writeUnsafeMigrationFixture(
          fixture,
          inputPath: isInput ? unsafePath : 'current.txt',
          rollbackPath: isInput ? 'baseline.txt' : unsafePath,
        );
        final beforeTemps = _rehearsalTempPaths();
        final errors = rehearsePhase5Migration(fixture).errors;
        expect(errors.join('\n'), contains('symlink rejected'));
        expect(sentinel.readAsStringSync(), 'outside-unchanged');
        expect(_rehearsalTempPaths(), beforeTemps);
      }
    });

    test(
      'origin scope is fresh-clone-equivalent and never selects ignored secrets',
      () {
        final fixture = _fixture();
        addTearDown(() => fixture.deleteSync(recursive: true));
        expect(
          Process.runSync('git', [
            'init',
            '-q',
          ], workingDirectory: fixture.path).exitCode,
          0,
        );
        File(
          '${fixture.path}/.gitignore',
        ).writeAsStringSync('*.secret\n.idea/\n.claude/\n*.iml\n');
        File('${fixture.path}/tracked.txt').writeAsStringSync('tracked');
        expect(
          Process.runSync('git', [
            'add',
            '.gitignore',
            'tracked.txt',
          ], workingDirectory: fixture.path).exitCode,
          0,
        );
        File('${fixture.path}/docs/candidate.md')
          ..createSync(recursive: true)
          ..writeAsStringSync('candidate');
        File('${fixture.path}/ignored.secret').writeAsStringSync('secret');
        File('${fixture.path}/.idea/workspace.xml')
          ..createSync(recursive: true)
          ..writeAsStringSync('editor-secret');
        File('${fixture.path}/.claude/settings.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('local-secret');
        File('${fixture.path}/project.iml').writeAsStringSync('editor-state');
        File('${fixture.path}/scratch.txt').writeAsStringSync('arbitrary');
        Link(
          '${fixture.path}/docs/external-secret',
        ).createSync('${fixture.path}/ignored.secret');

        final paths = freshCloneEquivalentOriginPaths(fixture);
        expect(paths, containsAll(['.gitignore', 'tracked.txt']));
        expect(paths, contains('docs/candidate.md'));
        expect(
          paths,
          isNot(
            containsAll([
              'ignored.secret',
              '.idea/workspace.xml',
              '.claude/settings.json',
              'project.iml',
              'scratch.txt',
              'docs/external-secret',
            ]),
          ),
        );
        for (final excluded in const [
          'ignored.secret',
          '.idea/workspace.xml',
          '.claude/settings.json',
          'project.iml',
          'scratch.txt',
          'docs/external-secret',
        ]) {
          expect(paths, isNot(contains(excluded)));
        }
      },
    );

    test('missing rights evidence is rejected', () {
      final fixture = _fixture();
      addTearDown(() => fixture.deleteSync(recursive: true));
      _writeRightsFixture(fixture, duplicateApproval: false);
      expect(
        validateRightsOnly(fixture),
        contains('Rights evidence identity mismatch: missing-font.ttf.'),
      );
    });

    test('approval reuse is rejected', () {
      final fixture = _fixture();
      addTearDown(() => fixture.deleteSync(recursive: true));
      _writeRightsFixture(fixture, duplicateApproval: true);
      expect(
        validateRightsOnly(fixture),
        contains('Human approval or attestation id reuse is forbidden.'),
      );
    });
  });
}

Directory _fixture() =>
    Directory.systemTemp.createTempSync('blds-phase5-negative-');

void _writeMigrationFixture(
  Directory fixture, {
  String? inputHash,
  String? rollbackHash,
}) {
  final current = File('${fixture.path}/current.txt')..writeAsStringSync('now');
  final baseline = File('${fixture.path}/baseline.txt')
    ..writeAsStringSync('before');
  File('${fixture.path}/contracts/migrations/registry.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
schema: "blab.migration-registry/v1"
codemod:
  status: "not-applicable"
migrations: []
rehearsal:
  consumer_source_mutation: "forbidden"
  source_checkout_execution: "forbidden"
  inputs:
    - path: "current.txt"
      sha256: "${inputHash ?? sha256File(current)}"
rollback:
  artifacts:
    - path: "baseline.txt"
      sha256: "${rollbackHash ?? sha256File(baseline)}"
''');
}

void _writeUnsafeMigrationFixture(
  Directory fixture, {
  required String inputPath,
  required String rollbackPath,
}) {
  final current = File('${fixture.path}/current.txt')..writeAsStringSync('now');
  final baseline = File('${fixture.path}/baseline.txt')
    ..writeAsStringSync('before');
  File('${fixture.path}/contracts/migrations/registry.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
schema: "blab.migration-registry/v1"
codemod:
  status: "not-applicable"
migrations: []
rehearsal:
  consumer_source_mutation: "forbidden"
  source_checkout_execution: "forbidden"
  inputs:
    - path: ${_yamlString(inputPath)}
      sha256: "${sha256File(current)}"
rollback:
  artifacts:
    - path: ${_yamlString(rollbackPath)}
      sha256: "${sha256File(baseline)}"
''');
}

Set<String> _rehearsalTempPaths() => Directory.systemTemp
    .listSync(followLinks: false)
    .whereType<Directory>()
    .map((directory) => directory.path)
    .where(
      (path) => path
          .split(Platform.pathSeparator)
          .last
          .startsWith('blds-phase5-rehearsal-'),
    )
    .toSet();

String _yamlString(String value) =>
    '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';

void _writeBaselineAdmissionFixture(Directory fixture) {
  File(
      '${fixture.path}/contracts/compatibility/'
      'baseline-admission.template.yaml',
    )
    ..createSync(recursive: true)
    ..writeAsStringSync('''
authority:
  status: "human-approval-required"
  approved: false
boundary:
  mutate_existing_baseline: false
  admission_performed: false
''');
}

void _writeRightsFixture(Directory fixture, {required bool duplicateApproval}) {
  final templateOne = File('${fixture.path}/one.yaml')
    ..writeAsStringSync('''
attestation:
  id: "ONE"
  status: "unsigned"
''');
  final templateTwo = File('${fixture.path}/two.yaml')
    ..writeAsStringSync('''
attestation:
  id: "${duplicateApproval ? 'ONE' : 'TWO'}"
  status: "unsigned"
''');
  File('${fixture.path}/contracts/legal/astryx.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync('schema: "fixture"\n');
  for (final path in const [
    'missing-license.txt',
    'missing-2.txt',
    'missing-3.txt',
    'missing-4.txt',
  ]) {
    File('${fixture.path}/$path').writeAsStringSync('fixture license');
  }
  File('${fixture.path}/contracts/legal/rights-provenance.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
project_license:
  release_or_publication_authorized: false
  copyright_holder_identity_status: "unknown-requires-human-authority"
  notice_authority_status: "unknown-requires-human-authority"
phase4_test_assets:
  entries:
    - {path: "missing-font.ttf", sha256: "$_zeroSha256", license_path: "missing-license.txt"}
    - {path: "missing-2.ttf", sha256: "$_zeroSha256", license_path: "missing-2.txt"}
    - {path: "missing-3.ttf", sha256: "$_zeroSha256", license_path: "missing-3.txt"}
    - {path: "missing-4.ttf", sha256: "$_zeroSha256", license_path: "missing-4.txt"}
remote_fonts:
  activation_authorized: false
  production_strategy_status: "unknown-requires-design-legal-product-decision"
human_attestations:
  templates:
    - {id: "ONE", path: "${_relative(fixture, templateOne)}"}
    - {id: "${duplicateApproval ? 'ONE' : 'TWO'}", path: "${_relative(fixture, templateTwo)}"}
astryx:
  evidence_packet: "contracts/legal/astryx.yaml"
''');
}

void _writeRemoteCssFixture(Directory fixture) {
  File(
    '${fixture.path}/sample.css',
  ).writeAsStringSync("@import url('https://example.invalid/font.css');\n");
  File('${fixture.path}/contracts/legal/rights-provenance.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
remote_fonts:
  css_import_inventory: []
''');
  File('${fixture.path}/contracts/release/package-dry-run-inventory.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('{"files": []}\n');
}

void _writeProvenanceClaimFixture(Directory fixture, String claim) {
  File('${fixture.path}/README.md').writeAsStringSync('$claim\n');
  for (final path in const [
    'contracts/blab.design.yaml',
    'contracts/schema/blab.design.schema.yaml',
    'contracts/legal/astryx-0.1.3-evidence.yaml',
    'THIRD_PARTY_NOTICES.md',
  ]) {
    File('${fixture.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync('fixture\n');
  }
  Directory('${fixture.path}/docs').createSync();
}

void _writeLicenseOwnershipClaimFixture(Directory fixture) {
  File('${fixture.path}/README.md').writeAsStringSync(
    'BLDS-owned source remains under the repository MIT license.\n',
  );
  File('${fixture.path}/contracts/legal/rights-provenance.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
project_license:
  copyright_holder_identity_status: "unknown-requires-human-authority"
  notice_authority_status: "unknown-requires-human-authority"
''');
  Directory('${fixture.path}/docs').createSync();
}

String _relative(Directory root, File file) =>
    file.path.substring(root.path.length + 1);
