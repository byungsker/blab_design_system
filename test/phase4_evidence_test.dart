import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import '../tool/src/doctor.dart';
import '../tool/src/phase4_evidence_validation.dart';
import '../tool/run_consumer_smoke.dart' as consumer_smoke;

void main() {
  test('Phase 4 evidence contracts and candidate baselines are consistent', () {
    expect(validatePhase4Evidence(Directory.current), isEmpty);
  });

  test(
    'BLabButton browser evidence cannot broaden web support or lose limits',
    () {
      final source = File(platformSupportPath).readAsStringSync();
      final current = loadYaml(source) as YamlMap;
      expect(validateBoundedWebPlatformClaims(current), isEmpty);

      final broadened =
          loadYaml(
                source.replaceFirst(
                  'package_support: "unverified"\n'
                      '    local_evidence: "component-scoped-executed"',
                  'package_support: "declared-platform-neutral"\n'
                      '    local_evidence: "executed"',
                ),
              )
              as YamlMap;
      expect(
        validateBoundedWebPlatformClaims(broadened),
        contains(
          'Web evidence must remain component-scoped and cannot become a '
          'public package-support or CI claim.',
        ),
      );

      final missingLimitation =
          loadYaml(
                source.replaceFirst('        - "not-public-web-support"\n', ''),
              )
              as YamlMap;
      expect(
        validateBoundedWebPlatformClaims(missingLimitation),
        contains(
          'BLabButton browser evidence must preserve every bounded limitation.',
        ),
      );
    },
  );

  test('story manifest covers all nine public component contract ids', () {
    final stories = loadYaml(File(storyManifestPath).readAsStringSync());
    final components = loadYaml(
      File('contracts/components/state-applicability.yaml').readAsStringSync(),
    );
    final storyIds = <String>{
      for (final story in stories['stories'] as YamlList)
        (story as YamlMap)['component_id'] as String,
    };
    final componentIds = <String>{
      for (final component in components['components'] as YamlList)
        (component as YamlMap)['id'] as String,
    };

    expect(storyIds, componentIds);
    expect(storyIds, hasLength(9));
  });

  test('baseline inventory records the bounded local Design approval', () {
    final manifest =
        loadYaml(File(visualBaselinesPath).readAsStringSync()) as YamlMap;
    final baselines = manifest['baselines'] as YamlList;

    expect(
      manifest['metadata']['baseline_design_approval'],
      'design-approved-local',
    );
    expect(manifest['metadata']['baseline_reviewed_on'], '2026-07-28');
    expect(
      manifest['metadata']['baseline_reviewer_role'],
      'byungskerlab-design-team',
    );
    expect(
      manifest['metadata']['baseline_review_evidence_ref'],
      'design-final-gate-handoff:button_contrast_standard_goldens:2026-07-28',
    );
    expect(
      manifest['metadata']['baseline_approval_scope'],
      'local-reproducibility-and-fixture-review-only',
    );
    expect(baselines, hasLength(10));
    for (final baseline in baselines.whereType<YamlMap>()) {
      final id = baseline['id'] as String;
      expect(baseline['approval_status'], 'design-approved-local', reason: id);
      expect(baseline.containsKey('candidate_decision_ref'), isFalse);
      expect(File(baseline['path'] as String).existsSync(), isTrue, reason: id);
    }
  });

  test('durable Design approval fails closed when a hash is changed', () {
    final manifest =
        loadYaml(File(visualBaselinesPath).readAsStringSync()) as YamlMap;
    final approvalSource = File(phase4DesignApprovalPath).readAsStringSync();
    final changedApproval =
        loadYaml(
              approvalSource.replaceFirst(
                'ff9d5ba52b372b2a08b5137444e7b584d8a2689ca4f7b233ca3956312c09218c',
                '0000000000000000000000000000000000000000000000000000000000000000',
              ),
            )
            as YamlMap;

    expect(
      validateVisualBaselineApprovalBinding(manifest, changedApproval),
      contains(contains('hash is not bound by the durable Design approval')),
    );
  });

  test('custody bounds local claims and delivery remains typed blocked', () {
    final custody =
        loadYaml(File(phase4CustodyPath).readAsStringSync()) as YamlMap;
    final target =
        loadYaml(File(targetDeliveryContractPath).readAsStringSync())
            as YamlMap;

    expect(custody['excluded_paths'], contains('.codex/'));
    expect(custody['excluded_paths'], contains('lib/'));
    expect(
      custody['claims']['package_runtime_files_changed_by_phase4'],
      isEmpty,
    );
    expect(custody['claims']['public_api_files_changed_by_phase4'], isEmpty);
    expect(target['observed']['package_version'], '0.0.1');
    expect(target['required_contract']['target_version'], isNull);
    expect(target['readiness']['local_evidence_verification'], 'allowed');
    expect(target['readiness']['git_delivery'], 'blocked');
    expect(target['readiness']['decision'], 'REQUEST_CHANGES');
  });

  test('candidate fixtures remain test-only, licensed, and multilingual', () {
    final manifest =
        loadYaml(File(visualBaselinesPath).readAsStringSync()) as YamlMap;
    final fonts = manifest['font_fixtures'] as YamlList;
    final ids = <String>{
      for (final font in fonts.whereType<YamlMap>()) font['id'] as String,
    };

    expect(
      ids,
      containsAll(const <String>[
        'noto-sans-kr-variable',
        'noto-sans-arabic-variable',
        'material-icons-test-fixture',
        'cupertino-icons-test-fixture',
      ]),
    );
    for (final font in fonts.whereType<YamlMap>()) {
      expect(font['runtime_asset'], isFalse);
      expect(File(font['path'] as String).existsSync(), isTrue);
      expect(File(font['license_path'] as String).existsSync(), isTrue);
    }
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('test/assets/fonts')),
    );
    expect(
      manifest['claim_boundary']['excludes'],
      contains('accessibility conformance'),
    );
  });

  test('candidate overlay and expansion claims remain narrowly scoped', () {
    final manifest =
        loadYaml(File(visualBaselinesPath).readAsStringSync()) as YamlMap;

    expect(
      manifest['capture_environment']['overlay_context'],
      contains('MaterialApp.builder'),
    );
    expect(
      manifest['capture_environment']['overlay_context'],
      contains('Navigator and Overlay'),
    );
    expect(
      manifest['capture_matrix']['expansion_claim'],
      'rune-count-only synthetic stress; no 40 percent rendered-width claim',
    );
  });

  test('doctor reports reproducibility without a conformance claim', () async {
    final envelope = await buildDoctorEnvelope(Directory.current);
    final check = envelope.result!.checks.singleWhere(
      (entry) => entry.id == 'phase4-evidence',
    );

    expect(check.severity, DoctorSeverity.pass);
    expect(check.message, contains('Design-approved local baseline evidence'));
    expect(check.message, contains('remain pending'));
    expect(check.message, contains('does not establish'));
    expect(check.message, contains('accessibility or visual conformance'));
  });

  test(
    'consumer smoke preflight returns a typed non-mutating result',
    () async {
      final result = await Process.run('dart', const <String>[
        'run',
        'tool/run_consumer_smoke.dart',
        '--json',
      ]);

      expect(result.exitCode, 0, reason: result.stderr as String);
      final document = jsonDecode(result.stdout as String);
      expect(document['schema'], 'blab.consumer-smoke-result/v1');
      expect(document['status'], 'skipped');
      expect(
        document['reason'],
        isIn(const <String>[
          'consumer-checkout-missing',
          'consumer-repository-mismatch',
          'consumer-worktree-dirty',
          'consumer-custody-unverified',
          'consumer-authority-unverified',
          'execution-not-requested',
        ]),
      );
      expect(document['mutated_consumer'], isFalse);
      expect(document['executed_commands'], isEmpty);
    },
  );

  test('consumer package boundary rejects path escape before any write', () {
    final checkout = Directory.systemTemp.createTempSync(
      'blab-consumer-boundary-',
    );
    try {
      final package = Directory('${checkout.path}/app')..createSync();
      final safe = consumer_smoke.inspectIsolatedConsumerPackage(
        checkout: checkout,
        packagePath: 'app',
      );
      expect(safe.isSafe, isTrue);
      expect(safe.packageDirectory!.path, package.resolveSymbolicLinksSync());
      expect(safe.overrideFile!.existsSync(), isFalse);

      final escaped = consumer_smoke.inspectIsolatedConsumerPackage(
        checkout: checkout,
        packagePath: '../outside',
      );
      expect(escaped.isSafe, isFalse);
      expect(escaped.reason, 'unsafe-package-path');

      final override = File('${package.path}/pubspec_overrides.yaml')
        ..writeAsStringSync('sentinel');
      final occupied = consumer_smoke.inspectIsolatedConsumerPackage(
        checkout: checkout,
        packagePath: 'app',
      );
      expect(occupied.isSafe, isFalse);
      expect(occupied.reason, 'consumer-override-path-occupied');
      expect(override.readAsStringSync(), 'sentinel');
    } finally {
      checkout.deleteSync(recursive: true);
    }
  });

  test(
    'consumer package boundary rejects a symlinked package root',
    () {
      final checkout = Directory.systemTemp.createTempSync(
        'blab-consumer-link-checkout-',
      );
      final outside = Directory.systemTemp.createTempSync(
        'blab-consumer-link-outside-',
      );
      final link = Link('${checkout.path}/app');
      try {
        link.createSync(outside.path);
        final result = consumer_smoke.inspectIsolatedConsumerPackage(
          checkout: checkout,
          packagePath: 'app',
        );

        expect(result.isSafe, isFalse);
        expect(result.reason, 'consumer-package-boundary-unsafe');
        expect(outside.listSync(), isEmpty);
      } finally {
        if (link.existsSync()) {
          link.deleteSync();
        }
        checkout.deleteSync(recursive: true);
        outside.deleteSync(recursive: true);
      }
    },
    skip: Platform.isWindows
        ? 'Windows CI does not guarantee symbolic-link creation permission.'
        : false,
  );
}
