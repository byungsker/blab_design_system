import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import 'json_schema_validation.dart';

const storyManifestPath = 'contracts/stories/blab.stories.yaml';
const storySchemaPath = 'contracts/schema/blab.story-manifest.schema.json';
const platformSupportPath = 'contracts/platform-support.yaml';
const platformSchemaPath = 'contracts/schema/blab.platform-support.schema.json';
const representativeConsumersPath =
    'contracts/consumers/representative-consumers.yaml';
const representativeConsumersSchemaPath =
    'contracts/schema/blab.representative-consumers.schema.json';
const visualBaselinesPath = 'contracts/visual-baselines.yaml';
const visualBaselinesSchemaPath =
    'contracts/schema/blab.visual-baselines.schema.json';
const phase4DesignApprovalPath =
    'contracts/approvals/phase4-local-baselines.design-approval.yaml';
const phase4DesignApprovalSchemaPath =
    'contracts/schema/blab.phase4-design-approval.schema.json';
const phase4CustodyPath = 'contracts/delivery/phase4-custody.yaml';
const phase4CustodySchemaPath =
    'contracts/schema/blab.phase4-custody.schema.json';
const targetDeliveryContractPath =
    'contracts/delivery/phase4-target-delivery.yaml';
const targetDeliveryContractSchemaPath =
    'contracts/schema/blab.target-delivery-contract.schema.json';
const webButtonEvidenceCommand =
    'flutter test --platform chrome test/blab_button_test.dart';
const webButtonClaimBoundary =
    'Local execution is limited to the macOS arm64 package evidence and one '
    'BLabButton-only Chrome widget suite. The browser result is not '
    'full-package web, browser-matrix, device, assistive-technology, haptic, '
    'rendering-conformance, shared-web-package, or public-support evidence. '
    'CI entries are syntax-validated configuration and are not remote-run '
    'evidence.';
const webButtonEvidenceLimitations = <String>{
  'not-full-package-web-test',
  'not-web-build-or-deployment',
  'not-browser-matrix',
  'not-physical-device',
  'not-assistive-technology',
  'not-haptic',
  'not-golden-or-rendering-conformance',
  'not-shared-web-package-authority',
  'not-public-web-support',
};

List<String> validatePhase4Evidence(Directory root) {
  final errors = <String>[];
  final stories = _loadAndValidate(
    root,
    storyManifestPath,
    storySchemaPath,
    errors,
  );
  final platforms = _loadAndValidate(
    root,
    platformSupportPath,
    platformSchemaPath,
    errors,
  );
  final consumers = _loadAndValidate(
    root,
    representativeConsumersPath,
    representativeConsumersSchemaPath,
    errors,
  );
  final visualBaselines = _loadAndValidate(
    root,
    visualBaselinesPath,
    visualBaselinesSchemaPath,
    errors,
  );
  final designApproval = _loadAndValidate(
    root,
    phase4DesignApprovalPath,
    phase4DesignApprovalSchemaPath,
    errors,
  );
  final custody = _loadAndValidate(
    root,
    phase4CustodyPath,
    phase4CustodySchemaPath,
    errors,
  );
  final targetDelivery = _loadAndValidate(
    root,
    targetDeliveryContractPath,
    targetDeliveryContractSchemaPath,
    errors,
  );
  if (stories != null) {
    _validateStories(root, stories, errors);
  }
  if (platforms != null) {
    _validatePlatforms(root, platforms, errors);
  }
  if (consumers != null) {
    _validateConsumers(consumers, errors);
  }
  if (custody != null) {
    _validateCustody(root, custody, errors);
  }
  if (targetDelivery != null) {
    _validateTargetDeliveryContract(targetDelivery, errors);
  }
  if (visualBaselines != null && designApproval != null) {
    _validateVisualBaselines(root, visualBaselines, designApproval, errors);
  }
  return errors;
}

YamlMap? _loadAndValidate(
  Directory root,
  String documentPath,
  String schemaPath,
  List<String> errors,
) {
  final documentFile = File('${root.path}/$documentPath');
  final schemaFile = File('${root.path}/$schemaPath');
  if (!documentFile.existsSync()) {
    errors.add('$documentPath is missing.');
    return null;
  }
  if (!schemaFile.existsSync()) {
    errors.add('$schemaPath is missing.');
    return null;
  }
  try {
    final document = loadYaml(documentFile.readAsStringSync());
    if (document is! YamlMap) {
      errors.add('$documentPath must contain a YAML mapping.');
      return null;
    }
    final schema = jsonDecode(schemaFile.readAsStringSync());
    for (final error in validateJsonAgainstSchema(document, schema)) {
      errors.add('$documentPath $error');
    }
    return document;
  } on YamlException catch (error) {
    errors.add('$documentPath is invalid YAML: ${error.message}');
  } on FormatException catch (error) {
    errors.add('$schemaPath is invalid: ${error.message}');
  }
  return null;
}

void _validateStories(Directory root, YamlMap manifest, List<String> errors) {
  final contractFile = File(
    '${root.path}/contracts/components/state-applicability.yaml',
  );
  if (!contractFile.existsSync()) {
    errors.add('contracts/components/state-applicability.yaml is missing.');
    return;
  }
  final contract = loadYaml(contractFile.readAsStringSync());
  if (contract is! YamlMap || contract['components'] is! YamlList) {
    errors.add('Component state contract must contain components.');
    return;
  }

  final expected = <String, _ComponentEvidence>{};
  for (final raw in contract['components'] as YamlList) {
    if (raw is! YamlMap) continue;
    final id = raw['id'];
    final publicType = raw['public_type'];
    final implementation = raw['implementation_evidence'];
    final notApplicable = raw['not_applicable'];
    if (id is! String ||
        publicType is! String ||
        implementation is! YamlMap ||
        notApplicable is! YamlList) {
      continue;
    }
    expected[id] = _ComponentEvidence(
      publicType: publicType,
      implementedStates: <String>{
        for (final entry in implementation.entries)
          if (entry.key is String &&
              entry.value is YamlMap &&
              (entry.value as YamlMap)['status'] == 'implemented-local')
            entry.key as String,
      },
      notApplicableStates: notApplicable.whereType<String>().toSet(),
    );
  }

  final registeredSource = File(
    '${root.path}/${manifest['metadata']['registration_source']}',
  );
  if (!registeredSource.existsSync()) {
    errors.add('Story registration source is missing.');
    return;
  }
  final registrationText = registeredSource.readAsStringSync();
  final registered = <String, String>{
    for (final match in RegExp(
      r"id: '([^']+)',\s+componentId: '([^']+)'",
      multiLine: true,
    ).allMatches(registrationText))
      match.group(2)!: match.group(1)!,
  };

  final observed = <String>{};
  final fixtureIds = <String>{};
  final stories = manifest['stories'];
  if (stories is! YamlList) return;
  for (final raw in stories) {
    if (raw is! YamlMap) continue;
    final componentId = raw['component_id'];
    final publicType = raw['public_type'];
    final storyId = raw['story_id'];
    final source = raw['source'];
    final fixtures = raw['fixtures'];
    if (componentId is! String ||
        publicType is! String ||
        storyId is! String ||
        source is! String ||
        fixtures is! YamlList) {
      continue;
    }
    if (!observed.add(componentId)) {
      errors.add('Duplicate story component id: $componentId');
    }
    final component = expected[componentId];
    if (component == null) {
      errors.add('Unknown story component id: $componentId');
      continue;
    }
    if (component.publicType != publicType) {
      errors.add(
        '$componentId public type mismatch: '
        '$publicType != ${component.publicType}',
      );
    }
    if (registered[componentId] != storyId) {
      errors.add(
        '$componentId is not registered as story $storyId in '
        '${manifest['metadata']['registration_source']}.',
      );
    }
    if (!File('${root.path}/$source').existsSync()) {
      errors.add('$componentId story source is missing: $source');
    }
    final coveredStates = <String>{};
    for (final fixture in fixtures) {
      if (fixture is! YamlMap) continue;
      final fixtureId = fixture['id'];
      final states = fixture['states'];
      if (fixtureId is String && !fixtureIds.add(fixtureId)) {
        errors.add('Duplicate story fixture id: $fixtureId');
      }
      if (states is! YamlList) continue;
      for (final state in states.whereType<String>()) {
        if (!coveredStates.add(state)) {
          errors.add('$componentId state $state is registered more than once.');
        }
        if (component.notApplicableStates.contains(state)) {
          errors.add(
            '$componentId story fabricates not-applicable state $state.',
          );
        }
        if (!component.implementedStates.contains(state)) {
          errors.add(
            '$componentId story claims unsupported or unimplemented state '
            '$state.',
          );
        }
      }
    }
    final missing = component.implementedStates.difference(coveredStates);
    final extra = coveredStates.difference(component.implementedStates);
    if (missing.isNotEmpty) {
      errors.add(
        '$componentId story misses implemented states: '
        '${_sorted(missing).join(', ')}',
      );
    }
    if (extra.isNotEmpty) {
      errors.add(
        '$componentId story has extra states: ${_sorted(extra).join(', ')}',
      );
    }
  }
  final missingComponents = expected.keys.toSet().difference(observed);
  final extraComponents = observed.difference(expected.keys.toSet());
  if (missingComponents.isNotEmpty) {
    errors.add(
      'Story manifest misses components: '
      '${_sorted(missingComponents).join(', ')}',
    );
  }
  if (extraComponents.isNotEmpty) {
    errors.add(
      'Story manifest has unknown components: '
      '${_sorted(extraComponents).join(', ')}',
    );
  }

  final unsupported = manifest['unsupported_fixture_categories'];
  final unsupportedIds = <String>{
    if (unsupported is YamlList)
      for (final entry in unsupported)
        if (entry is YamlMap && entry['id'] is String) entry['id'] as String,
  };
  for (final requiredExclusion in const <String>{'loading', 'no-results'}) {
    if (!unsupportedIds.contains(requiredExclusion)) {
      errors.add(
        'Story manifest must explicitly preserve unsupported fixture '
        'category $requiredExclusion.',
      );
    }
  }
  final captureScope =
      manifest['metadata']['candidate_capture_scope'] as YamlMap;
  final capturedComponents =
      (captureScope['required_component_ids'] as YamlList)
          .whereType<String>()
          .toSet();
  if (!_sameSet(capturedComponents, expected.keys.toSet())) {
    errors.add(
      'Story candidate capture scope must require exactly the nine public '
      'component ids.',
    );
  }
  final excludedClaims = (captureScope['excluded_claims'] as YamlList)
      .whereType<String>()
      .toSet();
  if (!excludedClaims.contains('accessibility conformance')) {
    errors.add(
      'Story candidate capture scope must exclude accessibility conformance.',
    );
  }
}

void _validatePlatforms(Directory root, YamlMap matrix, List<String> errors) {
  errors.addAll(validateBoundedWebPlatformClaims(matrix));
  final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
  final dartConstraint = matrix['toolchain']['dart_constraint'];
  final flutterConstraint = matrix['toolchain']['flutter_constraint'];
  if (!pubspec.contains('sdk: $dartConstraint')) {
    errors.add('Platform Dart constraint does not match pubspec.yaml.');
  }
  if (!pubspec.contains('flutter: "$flutterConstraint"')) {
    errors.add('Platform Flutter constraint does not match pubspec.yaml.');
  }
  final workflowFile = File('${root.path}/${matrix['ci']['workflow']}');
  if (!workflowFile.existsSync()) {
    errors.add('Configured CI workflow is missing.');
    return;
  }
  final workflow = loadYaml(workflowFile.readAsStringSync());
  if (workflow is! YamlMap) {
    errors.add('Configured CI workflow must contain a YAML mapping.');
    return;
  }
  final jobs = workflow['jobs'];
  final verify = jobs is YamlMap ? jobs['verify'] : null;
  final strategy = verify is YamlMap ? verify['strategy'] : null;
  final workflowMatrix = strategy is YamlMap ? strategy['matrix'] : null;
  final workflowRunners = workflowMatrix is YamlMap
      ? workflowMatrix['os']
      : null;
  final configuredRows = (matrix['ci']['matrix'] as YamlList)
      .whereType<YamlMap>()
      .toList();
  final configuredRunners = <String>{
    for (final row in configuredRows)
      if (row['os'] is String) row['os'] as String,
  };
  final actualWorkflowRunners = workflowRunners is YamlList
      ? workflowRunners.whereType<String>().toSet()
      : <String>{};
  const expectedRunners = <String>{
    'ubuntu-latest',
    'macos-latest',
    'windows-latest',
  };
  if (!_sameSet(configuredRunners, expectedRunners) ||
      configuredRows.length != expectedRunners.length ||
      !_sameSet(actualWorkflowRunners, expectedRunners) ||
      workflowRunners is! YamlList ||
      workflowRunners.length != expectedRunners.length) {
    errors.add(
      'Platform contract and workflow must map exactly the three configured '
      'runners.',
    );
  }
  const expectedChecks = <String>{
    'contract',
    'generation-drift',
    'api',
    'analyze',
    'package-tests',
    'golden-check',
    'example-build',
  };
  for (final row in configuredRows) {
    final os = row['os'];
    final checks = row['checks'];
    final observedChecks = checks is YamlList
        ? checks.whereType<String>().toSet()
        : <String>{};
    if (os is! String ||
        !_sameSet(observedChecks, expectedChecks) ||
        checks is! YamlList ||
        checks.length != expectedChecks.length) {
      errors.add(
        'Platform runner $os must map exactly the aggregate verification '
        'checks, including example-build.',
      );
    }
  }
  final steps = verify is YamlMap ? verify['steps'] : null;
  final stepRows = steps is YamlList ? steps.whereType<YamlMap>().toList() : [];
  final aggregateRuns = stepRows
      .where((step) => step['run'] == 'dart run tool/verify.dart')
      .length;
  final flutterSetup = stepRows.where(
    (step) =>
        step['uses'] == 'subosito/flutter-action@v2' &&
        step['with'] is YamlMap &&
        (step['with'] as YamlMap)['flutter-version'] == '3.38.5',
  );
  final exampleDependencyStep = stepRows.where(
    (step) =>
        step['run'] == 'flutter pub get' &&
        step['working-directory'] == 'example',
  );
  if (aggregateRuns != 1 ||
      flutterSetup.length != 1 ||
      exampleDependencyStep.length != 1) {
    errors.add(
      'Workflow must map every runner to one pinned aggregate verification '
      'command and the example dependency setup.',
    );
  }
  final platformRows = <String, YamlMap>{
    for (final raw in matrix['platforms'] as YamlList)
      if (raw is YamlMap && raw['id'] is String) raw['id'] as String: raw,
  };
  for (final id in const <String>{'macos-arm64', 'linux-x64', 'windows-x64'}) {
    if (platformRows[id]?['ci_configuration'] != 'syntax-validated-only') {
      errors.add('$id CI configuration must match the configured workflow.');
    }
  }
}

List<String> validateBoundedWebPlatformClaims(YamlMap matrix) {
  final errors = <String>[];
  final metadata = matrix['metadata'];
  if (metadata is! YamlMap ||
      metadata['claim_boundary'] != webButtonClaimBoundary) {
    errors.add(
      'Platform claim boundary must preserve the BLabButton-only browser '
      'evidence limitations.',
    );
  }
  final rawPlatforms = matrix['platforms'];
  if (rawPlatforms is! YamlList) {
    return [...errors, 'Platform rows are missing.'];
  }
  final rows = rawPlatforms.whereType<YamlMap>().toList();
  final webRows = rows.where((row) => row['id'] == 'web').toList();
  if (webRows.length != 1) {
    return [...errors, 'Platform contract must contain exactly one web row.'];
  }
  final web = webRows.single;
  if (web['package_support'] != 'unverified' ||
      web['local_evidence'] != 'component-scoped-executed' ||
      web['ci_configuration'] != 'not-configured') {
    errors.add(
      'Web evidence must remain component-scoped and cannot become a public '
      'package-support or CI claim.',
    );
  }
  final limitations = web['limitations'];
  if (limitations is! String ||
      !limitations.contains('Only the BLabButton browser widget suite') ||
      !limitations.contains('No full-package web test') ||
      !limitations.contains('public web support is claimed')) {
    errors.add(
      'Web platform limitations must deny full-package and public-support '
      'claims.',
    );
  }
  final evidence = web['browser_widget_evidence'];
  if (evidence is! YamlMap) {
    errors.add('BLabButton browser widget evidence is missing.');
    return errors;
  }
  const exactEvidence = <String, Object>{
    'component': 'BLabButton',
    'scope': 'single-component-browser-widget-suite-only',
    'command': webButtonEvidenceCommand,
    'exit_code': 0,
    'tests_passed': 61,
    'tests_failed': 0,
    'browser': 'Chrome',
    'browser_version': '150.0.7871.187',
    'flutter': '3.38.5',
    'dart': '3.10.4',
    'host_os': 'macos',
    'host_arch': 'arm64',
    'executed_on': '2026-07-28',
  };
  for (final entry in exactEvidence.entries) {
    if (evidence[entry.key] != entry.value) {
      errors.add('BLabButton browser widget evidence drifted at ${entry.key}.');
    }
  }
  final rawEvidenceLimitations = evidence['limitations'];
  final observedLimitations = rawEvidenceLimitations is YamlList
      ? rawEvidenceLimitations.whereType<String>().toSet()
      : <String>{};
  if (rawEvidenceLimitations is! YamlList ||
      rawEvidenceLimitations.length != webButtonEvidenceLimitations.length ||
      !_sameSet(observedLimitations, webButtonEvidenceLimitations)) {
    errors.add(
      'BLabButton browser evidence must preserve every bounded limitation.',
    );
  }
  if (rows.any(
    (row) =>
        row['id'] != 'web' &&
        (row.containsKey('browser_widget_evidence') ||
            row['local_evidence'] == 'component-scoped-executed'),
  )) {
    errors.add('Browser widget evidence may exist only on the web row.');
  }
  return errors;
}

void _validateConsumers(YamlMap manifest, List<String> errors) {
  final consumers = manifest['consumers'];
  if (consumers is! YamlList) return;
  final direct = consumers
      .whereType<YamlMap>()
      .where((entry) => entry['direct_consumer'] == true)
      .toList();
  if (direct.length != 1 || direct.single['id'] != 'baroguni-app') {
    errors.add(
      'Representative consumer manifest must record exactly one confirmed '
      'direct consumer candidate: baroguni-app.',
    );
  }
  final missingSecond = consumers.whereType<YamlMap>().where(
    (entry) =>
        entry['id'] == 'second-direct-flutter-consumer' &&
        entry['custody'] == 'missing' &&
        entry['smoke']['status'] == 'not-applicable-missing-consumer',
  );
  if (missingSecond.length != 1) {
    errors.add(
      'Representative consumer manifest must preserve the missing second '
      'direct consumer boundary.',
    );
  }
}

void _validateCustody(Directory root, YamlMap manifest, List<String> errors) {
  final owned = (manifest['owned_files'] as YamlList)
      .whereType<String>()
      .toList();
  final shared = (manifest['shared_delivery_files'] as YamlList)
      .whereType<String>()
      .toList();
  final excluded = (manifest['excluded_paths'] as YamlList)
      .whereType<String>()
      .toList();
  final declared = <String>{...owned, ...shared};
  if (owned.isEmpty || shared.isEmpty || excluded.isEmpty) {
    errors.add('Phase 4 custody file and exclusion sets must be non-empty.');
  }
  if (declared.length != owned.length + shared.length) {
    errors.add('Phase 4 custody paths must be unique across owned and shared.');
  }
  for (final path in declared) {
    if (!File('${root.path}/$path').existsSync()) {
      errors.add('Phase 4 custody file is missing: $path');
    }
    if (path == '.codex' ||
        path.startsWith('.codex/') ||
        path == 'DESIGN.md' ||
        path.startsWith('lib/')) {
      errors.add('Phase 4 custody includes forbidden path: $path');
    }
  }
  for (final requiredExclusion in const <String>{
    '.codex/',
    'DESIGN.md',
    'contracts/blab.design.yaml',
    'contracts/components/state-applicability.yaml',
    'contracts/tokens/',
    'docs/BLDS_PHASE_0_BASELINE.md',
    'docs/BLDS_PHASE_1_STATUS.md',
    'docs/BLDS_PHASE_2_STATUS.md',
    'docs/BLDS_PHASE_3_',
    'generated/',
    'lib/',
  }) {
    if (!excluded.contains(requiredExclusion)) {
      errors.add('Phase 4 custody must explicitly exclude $requiredExclusion.');
    }
  }
  final claims = manifest['claims'] as YamlMap;
  if ((claims['package_runtime_files_changed_by_phase4'] as YamlList)
          .isNotEmpty ||
      (claims['public_api_files_changed_by_phase4'] as YamlList).isNotEmpty) {
    errors.add(
      'Phase 4 no-runtime/API claim must remain scoped to an empty custody '
      'change set.',
    );
  }
  final agents = File('${root.path}/AGENTS.md');
  if (!agents.existsSync()) {
    errors.add('Project AGENTS.md safe harness is missing.');
  } else {
    final source = agents.readAsStringSync();
    for (final required in const <String>[
      'engineering-team > engineering-frontend > '
          'engineering-design-system-frontend',
      '3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4',
      '.codex/',
      'dart run tool/verify.dart',
      'never grants task authority',
    ]) {
      if (!source.contains(required)) {
        errors.add('Project AGENTS.md misses safe harness contract: $required');
      }
    }
  }
  final ignore = File('${root.path}/.gitignore').readAsStringSync().split('\n');
  for (final required in const <String>{'.codex/', '/example/build/'}) {
    if (!ignore.contains(required)) {
      errors.add('.gitignore must exclude $required from delivery.');
    }
  }
}

void _validateTargetDeliveryContract(YamlMap contract, List<String> errors) {
  final required = contract['required_contract'] as YamlMap;
  final readiness = contract['readiness'] as YamlMap;
  const unresolved = <String>{
    'target_version',
    'target_version_source',
    'expected_base_branch',
    'expected_head_branch',
    'pull_request',
    'promotion_path',
    'delivery_authority',
  };
  if (unresolved.any((field) => required[field] != null) ||
      readiness['git_delivery'] != 'blocked' ||
      readiness['local_evidence_verification'] != 'allowed' ||
      readiness['decision'] != 'REQUEST_CHANGES' ||
      (readiness['blockers'] as YamlList).length < 4) {
    errors.add(
      'Target Delivery Contract must remain honestly blocked without '
      'blocking local evidence verification.',
    );
  }
}

void _validateVisualBaselines(
  Directory root,
  YamlMap manifest,
  YamlMap designApproval,
  List<String> errors,
) {
  const expectedFamilies = <String>{
    'button',
    'text-field',
    'segmented-control',
    'tab-bar',
    'bottom-bar',
    'pressable-wrapper',
    'card',
    'snackbar',
    'keyboard-accessory-bar',
  };
  const expectedBaselines = <String>{
    'phase4-light',
    'phase4-dark',
    'phase4-high-contrast-light',
    'phase4-high-contrast-dark',
    'phase4-text-scale-2',
    'phase4-ko-kr',
    'phase4-expansion-40',
    'phase4-ar-rtl',
    'phase4-reduced-motion',
    'phase4-narrow',
  };
  errors.addAll(
    validateVisualBaselineApprovalBinding(manifest, designApproval),
  );
  final families = (manifest['required_component_families'] as YamlList)
      .whereType<String>()
      .toSet();
  if (!_sameSet(families, expectedFamilies)) {
    errors.add(
      'Visual baselines must require exactly all nine public component '
      'families.',
    );
  }
  final exclusions = (manifest['claim_boundary']['excludes'] as YamlList)
      .whereType<String>()
      .toList();
  if (!exclusions.contains('accessibility conformance')) {
    errors.add(
      'Visual baseline claim boundary must exclude accessibility conformance.',
    );
  }
  final metadata = manifest['metadata'] as YamlMap;
  const baselineApprovalMetadata = <String, String>{
    'status': 'design-approved-local-baselines',
    'baseline_design_approval': 'design-approved-local',
    'baseline_reviewed_on': '2026-07-28',
    'baseline_reviewer_role': 'byungskerlab-design-team',
    'baseline_review_evidence_ref':
        'design-final-gate-handoff:button_contrast_standard_goldens:2026-07-28',
    'baseline_approval_scope': 'local-reproducibility-and-fixture-review-only',
  };
  for (final entry in baselineApprovalMetadata.entries) {
    if (metadata[entry.key] != entry.value) {
      errors.add('Visual baseline ${entry.key} must remain ${entry.value}.');
    }
  }
  final residuals = manifest['known_residuals'] as YamlList;
  if (residuals.whereType<YamlMap>().any(
    (entry) =>
        entry['id'] ==
        'button-standard-primary-and-destructive-foreground-contrast',
  )) {
    errors.add(
      'Visual baseline contract must not retain the resolved Button foreground '
      'contrast residual.',
    );
  }
  final environment = manifest['capture_environment'] as YamlMap;
  for (final path in <String>[
    for (final value in environment['test_suites'] as YamlList)
      if (value is String) value,
    environment['shared_harness'] as String,
  ]) {
    if (!File('${root.path}/$path').existsSync()) {
      errors.add('Visual evidence source is missing: $path');
    }
  }
  final harness = File(
    '${root.path}/${environment['shared_harness']}',
  ).readAsStringSync();
  for (final evidence in const <String>[
    'BLabSnackbar.showManaged(',
    'persist: true',
    '_expectAllPublicFamiliesFramed',
    '_expectSnackbarScenarioEnvironment',
    'builder: (context, child)',
    'supportedLocales: <Locale>[scenario.locale]',
    'Localizations.localeOf(contentContext)',
    'Directionality.of(contentContext)',
  ]) {
    if (!harness.contains(evidence)) {
      errors.add('Golden harness is missing required evidence: $evidence');
    }
  }
  final matrix = manifest['capture_matrix'] as YamlMap;
  if (matrix['expansion_claim'] !=
      'rune-count-only synthetic stress; no 40 percent rendered-width claim') {
    errors.add('Visual baseline expansion claim must remain rune-count-only.');
  }
  final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
  if (pubspec.contains('test/assets/fonts')) {
    errors.add('Test fixture fonts must not be declared as runtime assets.');
  }
  final notice = File('${root.path}/test/assets/fonts/THIRD_PARTY_NOTICES.md');
  if (!notice.existsSync()) {
    errors.add('Test font third-party notice is missing.');
  }
  final fontIds = <String>{};
  for (final raw in manifest['font_fixtures'] as YamlList) {
    if (raw is! YamlMap) continue;
    final id = raw['id'] as String;
    final path = raw['path'] as String;
    final licensePath = raw['license_path'] as String;
    final expectedHash = raw['sha256'] as String;
    if (!fontIds.add(id)) {
      errors.add('Duplicate font fixture id: $id');
    }
    for (final requiredPath in <String>[path, licensePath]) {
      if (!File('${root.path}/$requiredPath').existsSync()) {
        errors.add('$id fixture evidence is missing: $requiredPath');
      }
    }
    final fixture = File('${root.path}/$path');
    if (fixture.existsSync()) {
      final actualHash = sha256.convert(fixture.readAsBytesSync()).toString();
      if (actualHash != expectedHash) {
        errors.add('$id font hash drift: $actualHash != $expectedHash');
      }
      if (notice.existsSync() &&
          !notice.readAsStringSync().contains(expectedHash)) {
        errors.add('$id hash is missing from the third-party notice.');
      }
    }
  }
  for (final requiredFont in const <String>{
    'noto-sans-kr-variable',
    'noto-sans-arabic-variable',
    'material-icons-test-fixture',
    'cupertino-icons-test-fixture',
  }) {
    if (!fontIds.contains(requiredFont)) {
      errors.add('Visual baseline contract misses font fixture $requiredFont.');
    }
  }
  final baselines = manifest['baselines'];
  if (baselines is! YamlList || baselines.isEmpty) {
    errors.add('$visualBaselinesPath must contain local baselines.');
    return;
  }
  final ids = <String>{};
  for (final raw in baselines) {
    if (raw is! YamlMap) continue;
    final id = raw['id'];
    final status = raw['approval_status'];
    final path = raw['path'];
    final expectedHash = raw['sha256'];
    final width = raw['width'];
    final height = raw['height'];
    if (id is! String || !ids.add(id)) {
      errors.add('Visual baseline ids must be unique strings.');
    }
    if (status != 'design-approved-local') {
      errors.add('$id must remain design-approved-local.');
    }
    if (path is! String ||
        expectedHash is! String ||
        width is! int ||
        height is! int) {
      errors.add('$id has incomplete path, hash, or dimensions.');
      continue;
    }
    final image = File('${root.path}/$path');
    if (!image.existsSync()) {
      errors.add('$id image is missing: $path');
      continue;
    }
    final bytes = image.readAsBytesSync();
    final actualHash = sha256.convert(bytes).toString();
    if (actualHash != expectedHash) {
      errors.add('$id hash drift: $actualHash != $expectedHash');
    }
    final dimensions = _pngDimensions(bytes);
    if (dimensions == null ||
        dimensions.$1 != width ||
        dimensions.$2 != height) {
      errors.add('$id PNG dimensions do not match $width x $height.');
    }
  }
  if (!_sameSet(ids, expectedBaselines)) {
    errors.add('Visual baseline ids do not match the required set.');
  }
}

List<String> validateVisualBaselineApprovalBinding(
  YamlMap manifest,
  YamlMap approval,
) {
  final errors = <String>[];
  final manifestMetadata = manifest['metadata'] as YamlMap;
  final approvalMetadata = approval['metadata'] as YamlMap;
  const metadataBindings = <String, String>{
    'baseline_reviewed_on': 'reviewed_on',
    'baseline_reviewer_role': 'reviewer_role',
    'baseline_review_evidence_ref': 'evidence_ref',
    'baseline_approval_scope': 'approval_scope',
  };
  for (final binding in metadataBindings.entries) {
    if (manifestMetadata[binding.key] != approvalMetadata[binding.value]) {
      errors.add(
        'Visual baseline approval is stale: ${binding.key} does not match '
        'the durable Design approval.',
      );
    }
  }
  if (manifestMetadata['baseline_approval_artifact'] !=
      phase4DesignApprovalPath) {
    errors.add(
      'Visual baseline manifest must reference the durable Design approval.',
    );
  }

  final approved = <String, String>{};
  for (final raw in (approval['baselines'] as YamlList).whereType<YamlMap>()) {
    final path = raw['path'];
    final digest = raw['sha256'];
    if (path is! String || digest is! String) continue;
    if (approved.containsKey(path)) {
      errors.add('Durable Design approval repeats baseline path $path.');
    }
    approved[path] = digest;
  }
  final declared = <String, String>{};
  for (final raw in (manifest['baselines'] as YamlList).whereType<YamlMap>()) {
    final path = raw['path'];
    final digest = raw['sha256'];
    if (path is! String || digest is! String) continue;
    if (declared.containsKey(path)) {
      errors.add('Visual baseline manifest repeats baseline path $path.');
    }
    declared[path] = digest;
  }
  if (!_sameSet(approved.keys.toSet(), declared.keys.toSet())) {
    errors.add(
      'Durable Design approval paths do not match the visual baseline set.',
    );
  }
  for (final entry in declared.entries) {
    if (approved[entry.key] != entry.value) {
      errors.add(
        'Visual baseline ${entry.key} hash is not bound by the durable '
        'Design approval.',
      );
    }
  }
  return errors;
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

(int, int)? _pngDimensions(List<int> bytes) {
  if (bytes.length < 24 ||
      bytes[0] != 0x89 ||
      bytes[1] != 0x50 ||
      bytes[2] != 0x4e ||
      bytes[3] != 0x47) {
    return null;
  }
  int read32(int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
  return (read32(16), read32(20));
}

List<String> _sorted(Iterable<String> values) => values.toList()..sort();

class _ComponentEvidence {
  const _ComponentEvidence({
    required this.publicType,
    required this.implementedStates,
    required this.notApplicableStates,
  });

  final String publicType;
  final Set<String> implementedStates;
  final Set<String> notApplicableStates;
}
