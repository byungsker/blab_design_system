import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import 'json_schema_validation.dart';
import 'phase5_baseline_validation.dart';
import 'phase5_compatibility.dart';

const phase5ReadinessPath = 'contracts/release/phase5-readiness.yaml';
const phase5PackageDryRunPath = 'contracts/release/package-dry-run.yaml';
const phase5PackageCompositionPath =
    'contracts/release/package-composition-candidate.yaml';
const phase5RightsPath = 'contracts/legal/rights-provenance.yaml';
const phase5OriginMapPath = 'contracts/legal/file-origin-map.yaml';
const phase5SpdxPath = 'contracts/sbom/blab-design-system.spdx.json';
const phase5CycloneDxPath = 'contracts/sbom/blab-design-system.cdx.json';
const activeTargetDeliveryPath =
    'contracts/delivery/blab-design-system-0.2.0.yaml';

const _schemaPairs = <(String, String)>[
  (
    phase5BaselineAdmissionPath,
    'contracts/schema/blab.compatibility-baseline-admission.schema.json',
  ),
  (
    phase5CompatibilityPolicyPath,
    'contracts/schema/blab.compatibility-policy.schema.json',
  ),
  (
    phase5MigrationRegistryPath,
    'contracts/schema/blab.migration-registry.schema.json',
  ),
  (phase5RightsPath, 'contracts/schema/blab.rights-provenance.schema.json'),
  (phase5ReadinessPath, 'contracts/schema/blab.phase5-readiness.schema.json'),
  (
    activeTargetDeliveryPath,
    'contracts/schema/blab.active-target-delivery-contract.schema.json',
  ),
  (
    phase5PackageDryRunPath,
    'contracts/schema/blab.package-dry-run.schema.json',
  ),
  (
    phase5PackageCompositionPath,
    'contracts/schema/blab.package-composition-candidate.schema.json',
  ),
  (phase5OriginMapPath, 'contracts/schema/blab.file-origin-map.schema.json'),
];

const requiredOpenPhase5Blockers = <String>{
  'copyright-holder-and-mit-notice-authority',
  'baro-app-transfer-or-relicense-authority',
  'contributor-aliases-and-restrictions',
  'publication-markets-channels-jurisdictions-and-package-composition',
  'production-font-strategy',
  'non-derivation-asset-and-figma-origin-attestations',
  'final-release-authority',
  'remote-ci',
  'two-clean-pinned-direct-flutter-consumers',
};

const requiredResolvedPhase5Gates = <String>{
  'canonical-repository-owner-and-remote',
  'exact-target-delivery-contract',
};

List<String> validatePhase5Readiness(Directory root) {
  final errors = <String>[];
  for (final pair in _schemaPairs) {
    _validateSchemaPair(root, pair.$1, pair.$2, errors);
  }
  _validateDeprecatedSupport(root, errors);
  final report = classifyRepositoryCompatibility(root);
  errors.addAll(report.violations);
  _validateMigrationRegistry(root, errors);
  _validateRights(root, errors);
  _validatePackageCompositionCandidate(root, errors);
  _validateReadinessBoundary(root, errors);
  _validateActiveTargetDelivery(root, errors);
  _validateSboms(root, errors);
  _validatePackageDryRun(root, errors);
  _validateNotices(root, errors);
  _validateUnsignedProvenanceClaims(root, errors);
  _validateUnknownLicenseOwnershipClaims(root, errors);
  return errors;
}

void _validateActiveTargetDelivery(Directory root, List<String> errors) {
  final file = File('${root.path}/$activeTargetDeliveryPath');
  if (!file.existsSync()) {
    errors.add('$activeTargetDeliveryPath is missing.');
    return;
  }
  final contract = _loadYamlMap(file);
  final metadata = _map(contract['metadata']);
  final delivery = _map(contract['delivery']);
  final pullRequest = _map(contract['pull_request']);
  final requiredMetadata = _map(pullRequest['required_metadata']);
  final authority = _map(contract['authority']);
  final gates = _map(contract['gates']);
  final promotion = _map(gates['promotion']);
  final legacyTag = _map(contract['legacy_tag']);

  if (metadata['contract_id'] != 'BLDS-TDC-BLAB-DESIGN-SYSTEM-0.2.0' ||
      metadata['status'] != 'owner-approved-active' ||
      metadata['accepted_on'] != '2026-07-28' ||
      metadata['owner'] != 'byungsker' ||
      metadata['authoritative_source'] !=
          'docs/BLDS_TARGET_DELIVERY_PROPOSAL.md') {
    errors.add('Active Target Delivery metadata is not owner-approved.');
  }
  const head =
      'codex/feature/blab-design-system/0.2.0/astryx-capability-adoption';
  if (delivery['delivery_unit'] != 'blab-design-system' ||
      delivery['delivery_profile'] != 'package-or-local' ||
      delivery['target_version'] != '0.2.0' ||
      delivery['target_version_source'] !=
          'docs/BLDS_TARGET_DELIVERY_PROPOSAL.md#owner-acceptance-record' ||
      delivery['expected_base_branch'] != 'main' ||
      delivery['expected_base_sha'] !=
          '9ac903c448685c31d37cbaf4340990e7c0e8226c' ||
      delivery['expected_head_branch'] != head ||
      delivery['protected_design_restoration_sha256'] !=
          '3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4' ||
      delivery['protected_design_restoration_source'] !=
          'byungsker follow-up approval in the active Codex thread on 2026-07-28') {
    errors.add('Active Target Delivery values are inconsistent.');
  }
  if (pullRequest['base'] != 'main' ||
      pullRequest['head'] != head ||
      pullRequest['draft'] != true ||
      requiredMetadata['Target-Delivery-Unit'] != 'blab-design-system' ||
      requiredMetadata['Target-Version'] != '0.2.0' ||
      requiredMetadata['Delivery-Profile'] != 'package-or-local' ||
      requiredMetadata['Promotion-Source-SHA'] !=
          'not-applicable-normal-work-pr') {
    errors.add('Active Target Delivery pull-request metadata is inconsistent.');
  }
  for (final key in const [
    'branch',
    'isolated_worktree',
    'commit',
    'push',
    'draft_pull_request',
    'protected_design_restoration',
  ]) {
    if (authority[key] != true) {
      errors.add('Active Target Delivery authority is missing: $key.');
    }
  }
  for (final key in const [
    'github_approval',
    'merge',
    'tag',
    'release',
    'publication',
    'deployment',
    'consumer_mutation',
  ]) {
    if (authority[key] != false) {
      errors.add('Active Target Delivery authority is over-broad: $key.');
    }
  }
  if (promotion['status'] != 'blocked') {
    errors.add('Active Target Delivery promotion must remain blocked.');
  }
  if (legacyTag['tag'] != 'v0.1.0' ||
      legacyTag['observed_commit'] !=
          '54499482a15ebb40ffdfd531c9416b07f7282bac' ||
      legacyTag['observed_manifest_version'] != '0.0.1' ||
      legacyTag['disposition'] !=
          'immutable inconsistent historical tag; never move, reuse, or treat as target-version authority') {
    errors.add('Legacy v0.1.0 disposition is inconsistent.');
  }
  final designFile = File('${root.path}/DESIGN.md');
  final designDigest = designFile.existsSync()
      ? sha256.convert(designFile.readAsBytesSync()).toString()
      : null;
  if (designDigest != delivery['protected_design_restoration_sha256']) {
    errors.add('Protected DESIGN.md does not match the approved restoration.');
  }
}

List<String> validateMigrationRegistryOnly(Directory root) {
  final errors = <String>[];
  _validateMigrationRegistry(root, errors);
  return errors;
}

List<String> validatePackageDryRunOnly(Directory root) {
  final errors = <String>[];
  _validatePackageDryRun(root, errors);
  return errors;
}

List<String> validateDeprecatedSupportOnly(Directory root) {
  final errors = <String>[];
  _validateDeprecatedSupport(root, errors);
  return errors;
}

List<String> validateRightsOnly(Directory root) {
  final errors = <String>[];
  _validateRights(root, errors);
  return errors;
}

List<String> validateRemoteCssImportsOnly(Directory root) {
  final errors = <String>[];
  final rightsFile = File('${root.path}/$phase5RightsPath');
  if (!rightsFile.existsSync()) {
    return ['$phase5RightsPath is missing.'];
  }
  final rights = _loadYamlMap(rightsFile);
  _validateRemoteCssImports(root, _map(rights['remote_fonts']), errors);
  return errors;
}

List<String> validateUnsignedProvenanceClaimsOnly(Directory root) {
  final errors = <String>[];
  _validateUnsignedProvenanceClaims(root, errors);
  return errors;
}

List<String> validateUnknownLicenseOwnershipClaimsOnly(Directory root) {
  final errors = <String>[];
  _validateUnknownLicenseOwnershipClaims(root, errors);
  return errors;
}

MigrationRehearsalResult rehearsePhase5Migration(Directory root) {
  final errors = <String>[];
  final registryFile = File('${root.path}/$phase5MigrationRegistryPath');
  if (!registryFile.existsSync()) {
    return MigrationRehearsalResult(errors: const ['Registry is missing.']);
  }
  final registry = _loadYamlMap(registryFile);
  final before = <String, String>{};
  final rehearsal = _map(registry['rehearsal']);
  final inputs = rehearsal['inputs'];
  if (inputs is! YamlList) {
    return MigrationRehearsalResult(
      errors: const ['Migration rehearsal inputs are missing.'],
    );
  }
  final temp = Directory.systemTemp.createTempSync('blds-phase5-rehearsal-');
  try {
    for (final raw in inputs.whereType<YamlMap>()) {
      final path = raw['path'];
      final expected = raw['sha256'];
      if (path is! String || expected is! String) continue;
      final source = _safeRepositorySource(
        root,
        path,
        'migration input',
        errors,
      );
      if (source == null) continue;
      if (expected == 'computed-by-validator') {
        if (!source.existsSync()) {
          errors.add('Migration rehearsal input is missing: $path.');
        }
        continue;
      }
      if (!source.existsSync()) {
        errors.add('Migration rehearsal input is missing: $path.');
        continue;
      }
      final sourceHash = _sha256(source);
      before[path] = sourceHash;
      if (sourceHash != expected) {
        errors.add('Stale migration rehearsal identity: $path.');
        continue;
      }
      final copy = _safeDisposableDestination(temp, 'current', path, errors);
      if (copy == null) continue;
      source.copySync(copy.path);
      if (_sha256(copy) != sourceHash) {
        errors.add('Disposable migration copy mismatch: $path.');
      }
    }

    final rollback = _map(registry['rollback']);
    final artifacts = rollback['artifacts'];
    if (artifacts is! YamlList) {
      errors.add('Rollback artifacts are missing.');
    } else {
      for (final raw in artifacts.whereType<YamlMap>()) {
        final path = raw['path'];
        final expected = raw['sha256'];
        if (path is! String || expected is! String) continue;
        final source = _safeRepositorySource(
          root,
          path,
          'rollback artifact',
          errors,
        );
        if (source == null) continue;
        if (!source.existsSync() || _sha256(source) != expected) {
          errors.add('Rollback artifact identity mismatch: $path.');
          continue;
        }
        final copy = _safeDisposableDestination(temp, 'rollback', path, errors);
        if (copy == null) continue;
        source.copySync(copy.path);
        if (_sha256(copy) != expected) {
          errors.add('Disposable rollback copy mismatch: $path.');
        }
      }
    }

    for (final entry in before.entries) {
      final source = _safeRepositorySource(
        root,
        entry.key,
        'migration input',
        errors,
      );
      if (source == null) continue;
      if (!source.existsSync() || _sha256(source) != entry.value) {
        errors.add('Source artifact changed during rehearsal: ${entry.key}.');
      }
    }
  } finally {
    temp.deleteSync(recursive: true);
    if (temp.existsSync()) {
      errors.add('Disposable migration rehearsal cleanup failed.');
    }
  }
  return MigrationRehearsalResult(errors: errors);
}

class MigrationRehearsalResult {
  MigrationRehearsalResult({required List<String> errors})
    : errors = List.unmodifiable([...errors]..sort());

  final List<String> errors;
  bool get passes => errors.isEmpty;
}

void _validateDeprecatedSupport(Directory root, List<String> errors) {
  final file = File('${root.path}/$phase5CompatibilityPolicyPath');
  if (!file.existsSync()) {
    errors.add('$phase5CompatibilityPolicyPath is missing.');
    return;
  }
  final policy = _loadYamlMap(file);
  final deprecated = _map(_map(policy['classifications'])['deprecated']);
  if (deprecated['support_status'] != 'not-supported-in-phase5-classifier' ||
      deprecated['result_status'] != 'unknown-not-detected' ||
      deprecated['limitation'] is! String ||
      (deprecated['limitation'] as String).isEmpty) {
    errors.add(
      'Deprecated classification must remain typed unknown and unsupported '
      'until a deterministic detector exists.',
    );
  }
  final docs = Directory('${root.path}/docs');
  final governedMarkdown = <File>[
    File('${root.path}/README.md'),
    File('${root.path}/CHANGELOG.md'),
    if (docs.existsSync())
      ...docs
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.md')),
  ];
  final forbiddenClaims = <RegExp>[
    RegExp(r'\b0\s+deprecated\b', caseSensitive: false),
    RegExp(
      r'\b(?:no|zero)\s+deprecated(?:\s+(?:change|changes|entries))?\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\bdeprecated\b.{0,40}\b(?:count|changes?|entries?)\s*'
      r'(?:=|:|are|is)\s*(?:0|zero|none)\b',
      caseSensitive: false,
      dotAll: true,
    ),
  ];
  for (final document in governedMarkdown.where((file) => file.existsSync())) {
    final source = document.readAsStringSync();
    if (forbiddenClaims.any((pattern) => pattern.hasMatch(source))) {
      final relative = document.path
          .substring(root.path.length + 1)
          .replaceAll('\\', '/');
      errors.add(
        'Deprecated documentation must use typed unknown/unsupported, not '
        'numeric or absence claims: $relative.',
      );
    }
  }
}

void _validateMigrationRegistry(Directory root, List<String> errors) {
  final file = File('${root.path}/$phase5MigrationRegistryPath');
  if (!file.existsSync()) {
    errors.add('$phase5MigrationRegistryPath is missing.');
    return;
  }
  final registry = _loadYamlMap(file);
  final codemod = _map(registry['codemod']);
  final migrations = registry['migrations'];
  if (codemod['status'] != 'not-applicable' || migrations is! YamlList) {
    errors.add('Codemod status and migration registry shape are invalid.');
  } else {
    final migrationEntries = migrations.whereType<YamlMap>().toList();
    if (migrationEntries.length != migrations.length ||
        migrationEntries.any((entry) => entry['codemod_required'] != false)) {
      errors.add(
        'Codemod may be not-applicable only when every registered change '
        'explicitly requires no codemod.',
      );
    }
  }
  final rehearsal = _map(registry['rehearsal']);
  if (rehearsal['repository_source_access'] !=
          'read-only-normalized-contained-real-files' ||
      rehearsal['consumer_source_access'] != 'forbidden' ||
      rehearsal['consumer_source_mutation'] != 'forbidden' ||
      rehearsal['source_checkout_execution'] != 'forbidden' ||
      rehearsal['disposable_destination_containment'] !=
          'canonical-system-temp-subdirectory' ||
      rehearsal['cleanup'] != 'required-and-verified') {
    errors.add('Migration rehearsal must forbid consumer source mutation.');
  }
  final inputs = rehearsal['inputs'];
  if (inputs is YamlList) {
    for (final raw in inputs.whereType<YamlMap>()) {
      final path = raw['path'];
      final expected = raw['sha256'];
      if (path is! String || expected is! String) continue;
      final input = _safeRepositorySource(
        root,
        path,
        'migration input',
        errors,
      );
      if (input == null) continue;
      if (expected == 'computed-by-validator') {
        if (!input.existsSync()) {
          errors.add('Migration rehearsal input is missing: $path.');
        }
        continue;
      }
      if (!input.existsSync() || _sha256(input) != expected) {
        errors.add('Stale migration rehearsal identity: $path.');
      }
    }
  }
  final rollback = _map(registry['rollback']);
  if (rollback['repository_source_access'] !=
          'read-only-normalized-contained-real-files' ||
      rollback['disposable_destination_containment'] !=
          'canonical-system-temp-subdirectory') {
    errors.add('Rollback must preserve read-only contained source access.');
  }
  final artifacts = rollback['artifacts'];
  if (artifacts is YamlList) {
    for (final raw in artifacts.whereType<YamlMap>()) {
      final path = raw['path'];
      final expected = raw['sha256'];
      if (path is! String || expected is! String) continue;
      final artifact = _safeRepositorySource(
        root,
        path,
        'rollback artifact',
        errors,
      );
      if (artifact == null) continue;
      if (!artifact.existsSync() || _sha256(artifact) != expected) {
        errors.add('Rollback artifact identity mismatch: $path.');
      }
    }
  }
}

void _validateRights(Directory root, List<String> errors) {
  final file = File('${root.path}/$phase5RightsPath');
  if (!file.existsSync()) {
    errors.add('$phase5RightsPath is missing.');
    return;
  }
  final rights = _loadYamlMap(file);
  final projectLicense = _map(rights['project_license']);
  if (projectLicense['release_or_publication_authorized'] != false ||
      projectLicense['copyright_holder_identity_status'] !=
          'unknown-requires-human-authority' ||
      projectLicense['notice_authority_status'] !=
          'unknown-requires-human-authority') {
    errors.add('Rights contract must preserve unresolved human authority.');
  }
  final assets = _map(rights['phase4_test_assets'])['entries'];
  if (assets is! YamlList || assets.length != 4) {
    errors.add('Rights evidence must inventory four Phase 4 test assets.');
  } else {
    for (final raw in assets.whereType<YamlMap>()) {
      final path = raw['path'];
      final expected = raw['sha256'];
      final licensePath = raw['license_path'];
      if (path is! String ||
          expected is! String ||
          licensePath is! String ||
          !File('${root.path}/$licensePath').existsSync()) {
        errors.add('Rights evidence is missing for a Phase 4 test asset.');
        continue;
      }
      final asset = File('${root.path}/$path');
      if (!asset.existsSync() || _sha256(asset) != expected) {
        errors.add('Rights evidence identity mismatch: $path.');
      }
    }
  }
  final remoteFonts = _map(rights['remote_fonts']);
  if (remoteFonts['activation_authorized'] != false ||
      remoteFonts['production_strategy_status'] !=
          'unknown-requires-design-legal-product-decision') {
    errors.add('Remote-font authority boundary was weakened.');
  }
  _validateRemoteCssImports(root, remoteFonts, errors);
  _validateRemoteFontPrivacy(remoteFonts, errors);
  final templateIds = <String>{};
  final templates = _map(rights['human_attestations'])['templates'];
  if (templates is! YamlList || templates.length != 2) {
    errors.add('Two unsigned human attestation templates are required.');
  } else {
    for (final raw in templates.whereType<YamlMap>()) {
      final id = raw['id'];
      final path = raw['path'];
      if (id is! String || !templateIds.add(id)) {
        errors.add('Human approval or attestation id reuse is forbidden.');
      }
      if (path is! String || !File('${root.path}/$path').existsSync()) {
        errors.add('Human attestation template evidence is missing.');
        continue;
      }
      final template = _loadYamlMap(File('${root.path}/$path'));
      final attestation = _map(template['attestation']);
      if (attestation['id'] != id || attestation['status'] != 'unsigned') {
        errors.add(
          'Human attestation template must remain unsigned and scoped.',
        );
      }
    }
  }
  final astryxPath = _map(rights['astryx'])['evidence_packet'];
  if (astryxPath is! String || !File('${root.path}/$astryxPath').existsSync()) {
    errors.add('Astryx evidence packet is missing.');
  }
}

void _validateRemoteFontPrivacy(YamlMap remoteFonts, List<String> errors) {
  if (remoteFonts['privacy_assessment_status'] !=
          'hypotheses-only-activation-blocked' ||
      remoteFonts['jurisdictions'] != 'unknown' ||
      remoteFonts['terms_retrieval_status'] != 'not-retrieved' ||
      remoteFonts['terms_effective_dates'] != 'unknown') {
    errors.add('Remote-font privacy assessment must remain hypotheses-only.');
  }
  final entries = remoteFonts['entries'];
  if (entries is! YamlList || entries.length != 2) {
    errors.add('Remote-font privacy lifecycle must cover two provider paths.');
    return;
  }
  for (final raw in entries.whereType<YamlMap>()) {
    final privacy = raw['privacy_lifecycle'];
    if (privacy is! YamlMap) {
      errors.add('Remote-font privacy lifecycle is missing.');
      continue;
    }
    final data = privacy['data_elements'];
    if (data is! YamlMap ||
        !const {
          'ip_address',
          'requested_url',
          'user_agent_and_os',
          'referrer',
        }.every(data.containsKey)) {
      errors.add('Remote-font privacy data-element inventory is incomplete.');
    }
    for (final key in const [
      'provider_role_hypothesis',
      'controller_processor_hypothesis',
      'processing_locations_and_transfers',
      'retention',
      'deletion',
      'data_subject_rights',
      'lawful_basis_hypothesis',
      'consent_hypothesis',
      'notice_hypothesis',
      'terms_retrieval_status',
      'terms_effective_date',
      'jurisdictions',
    ]) {
      if (privacy[key] is! String || (privacy[key] as String).isEmpty) {
        errors.add('Remote-font privacy lifecycle is missing $key.');
      }
    }
  }
}

void _validateRemoteCssImports(
  Directory root,
  YamlMap remoteFonts,
  List<String> errors,
) {
  final importPattern = RegExp(
    r'''@import\s+(?:url\(\s*)?["']?https?://''',
    caseSensitive: false,
  );
  final discovered = <String>{};
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.css')) continue;
    final relative = entity.path
        .substring(root.path.length + 1)
        .replaceAll('\\', '/');
    final firstSegment = relative.split('/').first;
    if (const {
      '.git',
      '.dart_tool',
      'build',
      '.codex',
    }.contains(firstSegment)) {
      continue;
    }
    if (importPattern.hasMatch(entity.readAsStringSync())) {
      discovered.add(relative);
    }
  }

  final inventory = remoteFonts['css_import_inventory'];
  if (inventory is! YamlList) {
    errors.add('Remote CSS import inventory is missing.');
    return;
  }
  final entries = <String, YamlMap>{};
  for (final raw in inventory.whereType<YamlMap>()) {
    final path = raw['path'];
    if (path is! String || entries.containsKey(path)) {
      errors.add('Remote CSS import inventory paths must be unique strings.');
      continue;
    }
    entries[path] = raw;
  }
  for (final path in discovered.difference(entries.keys.toSet())) {
    errors.add('Remote CSS import inventory is missing path: $path.');
  }
  for (final path in entries.keys.toSet().difference(discovered)) {
    errors.add('Remote CSS import inventory has stale path: $path.');
  }

  final archiveFile = File(
    '${root.path}/contracts/release/package-dry-run-inventory.json',
  );
  if (!archiveFile.existsSync()) {
    errors.add('Package dry-run inventory is missing for CSS disposition.');
    return;
  }
  final archive = _jsonMap(jsonDecode(archiveFile.readAsStringSync()));
  final rawFiles = archive['files'];
  if (rawFiles is! List || rawFiles.any((entry) => entry is! String)) {
    errors.add('Package dry-run inventory files are invalid for CSS.');
    return;
  }
  final packagePaths = rawFiles.cast<String>().toSet();
  for (final entry in entries.entries) {
    final path = entry.key;
    final record = entry.value;
    final packaged = packagePaths.contains(path);
    final expectedDisposition = packaged
        ? 'included-current-dry-run'
        : 'excluded-current-dry-run';
    final isCompatibilityBaseline = path.startsWith(
      'contracts/compatibility/baselines/',
    );
    if (record['packaged_in_current_dry_run'] != packaged ||
        record['package_archive'] != expectedDisposition ||
        record['immutable_compatibility_baseline'] != isCompatibilityBaseline ||
        record['runtime_asset'] != false ||
        record['activation_authorized'] != false ||
        record['activation_condition'] !=
            'remote-requests-only-if-consumer-explicitly-loads-this-css' ||
        record['exact_release_composition_approved'] != false) {
      errors.add('Remote CSS import disposition or authority mismatch: $path.');
    }
  }
}

void _validateReadinessBoundary(Directory root, List<String> errors) {
  final readiness = _loadYamlMap(File('${root.path}/$phase5ReadinessPath'));
  final metadata = _map(readiness['metadata']);
  final exit = _map(readiness['exit']);
  final authority = _map(readiness['authority']);
  if (metadata['status'] != 'local-preparation-implemented-exit-blocked' ||
      metadata['package_version'] != '0.2.0' ||
      metadata['package_state'] != 'local-unreleased' ||
      metadata['release_target'] != '0.2.0-repository-only') {
    errors.add(
      'Phase 5 must remain bounded local preparation for package 0.2.0 '
      'local-unreleased.',
    );
  }
  if (exit['phase5_complete'] != false ||
      exit['delivery_ready'] != false ||
      exit['publication_ready'] != false ||
      exit['decision'] != 'REQUEST_CHANGES' ||
      exit['tdc'] != 'blocked' ||
      exit['two_consumer_exit'] != 'unmet') {
    errors.add('Phase 5 exit must remain false and blocked.');
  }
  final opencs = _map(exit['opencs']);
  if (opencs['direct_flutter_consumer'] != false ||
      opencs['counts_toward_two_consumer_exit'] != false) {
    errors.add('OpenCS must not count as a direct Flutter consumer.');
  }
  if (authority.values.any((value) => value != false)) {
    errors.add('Phase 5 authority flags must remain false.');
  }
  final blockerIds = <String>{
    for (final raw in (readiness['blockers'] as YamlList).whereType<YamlMap>())
      if (raw['id'] is String) raw['id'] as String,
  };
  if (blockerIds.length != requiredOpenPhase5Blockers.length ||
      !blockerIds.containsAll(requiredOpenPhase5Blockers)) {
    errors.add('Phase 5 blocker set is incomplete or duplicated.');
  }
  final resolvedGateIds = <String>{
    for (final raw
        in (readiness['resolved_gates'] as YamlList).whereType<YamlMap>())
      if (raw['id'] is String) raw['id'] as String,
  };
  if (resolvedGateIds.length != requiredResolvedPhase5Gates.length ||
      !resolvedGateIds.containsAll(requiredResolvedPhase5Gates) ||
      blockerIds.any(resolvedGateIds.contains)) {
    errors.add('Phase 5 resolved-gate set is incomplete, duplicated, or open.');
  }
  final tdc = _loadYamlMap(
    File('${root.path}/contracts/delivery/phase4-target-delivery.yaml'),
  );
  if (_map(tdc['readiness'])['decision'] != 'REQUEST_CHANGES') {
    errors.add('Target Delivery Contract must remain REQUEST_CHANGES.');
  }

  final design = _loadYamlMap(File('${root.path}/contracts/blab.design.yaml'));
  final capabilities = _map(design['capabilities']);
  final phaseStatus = _map(capabilities['phase_status']);
  if (phaseStatus['phase-5'] != 'local-preparation-implemented-exit-blocked') {
    errors.add('Canonical Phase 5 status is not bounded local preparation.');
  }
  final entries = capabilities['entries'];
  final migrationAndRelease = entries is YamlList
      ? entries.whereType<YamlMap>().where(
          (entry) => entry['id'] == 'migration-and-release',
        )
      : const Iterable<YamlMap>.empty();
  if (migrationAndRelease.length != 1 ||
      migrationAndRelease.single['status'] !=
          'local-preparation-implemented-exit-blocked') {
    errors.add(
      'Canonical migration-and-release status is missing or overclaims.',
    );
  }
}

void _validateSboms(Directory root, List<String> errors) {
  for (final path in const [phase5SpdxPath, phase5CycloneDxPath]) {
    final file = File('${root.path}/$path');
    if (!file.existsSync()) {
      errors.add('$path is missing.');
      continue;
    }
    final document = jsonDecode(file.readAsStringSync());
    final map = _jsonMap(document);
    final entries = path == phase5SpdxPath
        ? map['packages']
        : map['components'];
    if (entries is! List || entries.length < 2) {
      errors.add('$path has no dependency inventory.');
    }
  }
}

void _validatePackageDryRun(Directory root, List<String> errors) {
  final contractFile = File('${root.path}/$phase5PackageDryRunPath');
  final contract = _loadYamlMap(contractFile);
  final metadata = _map(contract['metadata']);
  final archive = _map(contract['archive']);
  final boundary = _map(contract['boundary']);
  final inventoryPath = archive['inventory'];
  if (inventoryPath is! String) {
    errors.add('Package dry-run inventory path is missing.');
    return;
  }
  final inventoryFile = File('${root.path}/$inventoryPath');
  if (!inventoryFile.existsSync()) {
    errors.add('Package dry-run inventory is missing: $inventoryPath.');
    return;
  }
  final inventory = _jsonMap(jsonDecode(inventoryFile.readAsStringSync()));
  final readinessFile = File('${root.path}/$phase5ReadinessPath');
  if (!readinessFile.existsSync()) {
    errors.add('Phase 5 readiness summary is missing.');
  } else {
    final readiness = _loadYamlMap(readinessFile);
    final localPreparation = _map(readiness['local_preparation']);
    final compressedSize = inventory['compressed_archive_size'];
    final fileCount = inventory['file_count'];
    if (compressedSize is! String || fileCount is! int) {
      errors.add('Canonical package inventory size or file count is invalid.');
    } else {
      final rawWarnings = inventory['warning_ids'];
      final warningSlug =
          rawWarnings is List && rawWarnings.contains('dirty-git-state')
          ? 'dirty-git-warning'
          : 'clean-git';
      final expectedSummary =
          '$fileCount-files-deterministic-digests-'
          '$warningSlug-no-publication';
      if (localPreparation['package_dry_run'] != expectedSummary) {
        errors.add(
          'Phase 5 readiness package summary disagrees with canonical '
          'package inventory.',
        );
      }
    }
  }
  if (metadata['command'] != 'flutter pub publish --dry-run' ||
      metadata['publication_performed'] != false ||
      inventory['publication_performed'] != false ||
      boundary['registry_mutation'] != false ||
      boundary['release_ready'] != false ||
      boundary['publication_ready'] != false) {
    errors.add('Package dry-run authority boundary was weakened.');
  }
  if (inventory['compressed_archive_size_scope'] !=
          'informational-platform-dependent-local-observation' ||
      archive['compressed_size_scope'] !=
          inventory['compressed_archive_size_scope']) {
    errors.add(
      'Compressed package size must remain a platform-dependent local '
      'observation.',
    );
  }
  if (metadata['exit_code'] != inventory['exit_code'] ||
      archive['archive_name'] != inventory['archive_name'] ||
      archive['file_count'] != inventory['file_count'] ||
      archive['compressed_size_reported'] !=
          inventory['compressed_archive_size'] ||
      archive['name_manifest_sha256'] != inventory['name_manifest_sha256'] ||
      archive['content_manifest_sha256'] !=
          inventory['content_manifest_sha256']) {
    errors.add('Package dry-run contract and archive inventory disagree.');
  }
  for (final key in const [
    'archive_name',
    'name_manifest_sha256',
    'content_manifest_sha256',
  ]) {
    final value = inventory[key];
    if (value is! String || value.isEmpty) {
      errors.add('Package dry-run inventory is missing $key.');
    }
  }
  final warnings = inventory['warning_ids'];
  if (warnings is! List ||
      warnings.any((warning) => warning != 'dirty-git-state') ||
      warnings.length > 1) {
    errors.add(
      'Package dry-run warnings must be empty or contain only dirty-git-state.',
    );
  }
  final files = inventory['files'];
  if (files is! List || files.any((entry) => entry is! String)) {
    errors.add('Package dry-run archive file inventory is invalid.');
    return;
  }
  final paths = files.cast<String>().toSet();
  for (final required in const {
    'LICENSE',
    'README.md',
    'THIRD_PARTY_NOTICES.md',
    'contracts/compatibility/policy.yaml',
    'doc/README.md',
    'lib/blab_design_system.dart',
  }) {
    if (!paths.contains(required)) {
      errors.add(
        'Package dry-run archive is missing required file: $required.',
      );
    }
  }
  for (final path in paths) {
    if (path.startsWith('test/assets/') ||
        path.startsWith('test/goldens/') ||
        path.startsWith('generated/') ||
        path.startsWith('api/') ||
        path.startsWith('.codex/') ||
        path.contains('/build/')) {
      errors.add('Package dry-run archive contains excluded path: $path.');
    }
  }
}

void _validatePackageCompositionCandidate(Directory root, List<String> errors) {
  final candidate = _loadYamlMap(
    File('${root.path}/$phase5PackageCompositionPath'),
  );
  final metadata = _map(candidate['metadata']);
  final dependency = _map(candidate['dependency_license_boundary']);
  final boundary = _map(candidate['decision_boundary']);
  if (metadata['status'] != 'candidate-human-unapproved' ||
      metadata['human_approved'] != false ||
      metadata['exact_release_composition_approved'] != false ||
      metadata['release_authorized'] != false ||
      metadata['publication_authorized'] != false ||
      dependency['resolved_dependency_count'] != 37 ||
      dependency['dependency_license_status'] != 'NOASSERTION' ||
      dependency['clearance_claimed'] != false ||
      boundary.values.any((value) => value != true && value != false) ||
      boundary['candidate_only'] != true ||
      boundary['composition_changes_require_human_approval'] != true ||
      boundary['target_delivery_contract_required'] != true ||
      boundary['clean_authoritative_source_required'] != true ||
      boundary['publication_performed'] != false) {
    errors.add(
      'Package composition must remain candidate and human-unapproved.',
    );
  }
}

void _validateUnsignedProvenanceClaims(Directory root, List<String> errors) {
  final files = <File>[
    File('${root.path}/contracts/blab.design.yaml'),
    File('${root.path}/contracts/schema/blab.design.schema.yaml'),
    File('${root.path}/contracts/legal/astryx-0.1.3-evidence.yaml'),
    File('${root.path}/README.md'),
    File('${root.path}/THIRD_PARTY_NOTICES.md'),
    ...Directory('${root.path}/docs')
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.md')),
  ];
  final forbidden = <RegExp>[
    RegExp('implementation-owner-attested-no-source-copy'),
    RegExp(r'copied_source_or_assets:\s*false'),
    RegExp(r'values_or_identity_adopted:\s*false'),
    RegExp(
      r'\battest(?:s|ed|ation)?\b.{0,240}\bdid\s+not\s+'
      r'(?:copy|adopt)\b.{0,120}\bastryx\b',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'\bdid\s+not\s+(?:copy|adopt)\b.{0,120}\bastryx\b',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'\bno\s+astryx\b.{0,220}\b(copied|adopted|distributed|used)\b',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'\bastryx\b.{0,220}\b(?:was|were)?\s*not\s+'
      r'(?:copied|adopted|derived|used)\b',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'\b(?:created|developed|implemented|written)\b.{0,120}\bwithout\s+'
      r'astryx\b',
      caseSensitive: false,
      dotAll: true,
    ),
  ];
  for (final file in files) {
    final source = file.readAsStringSync();
    if (forbidden.any((pattern) => pattern.hasMatch(source))) {
      final relative = file.path
          .substring(root.path.length + 1)
          .replaceAll('\\', '/');
      errors.add('Categorical unsigned provenance claim remains: $relative.');
    }
  }
}

void _validateUnknownLicenseOwnershipClaims(
  Directory root,
  List<String> errors,
) {
  final rightsFile = File('${root.path}/$phase5RightsPath');
  if (!rightsFile.existsSync()) {
    return;
  }
  final projectLicense = _map(_loadYamlMap(rightsFile)['project_license']);
  final authorityUnknown =
      projectLicense['copyright_holder_identity_status'] ==
          'unknown-requires-human-authority' ||
      projectLicense['notice_authority_status'] ==
          'unknown-requires-human-authority';
  if (!authorityUnknown) {
    return;
  }

  final docs = Directory('${root.path}/docs');
  final files = <File>[
    File('${root.path}/README.md'),
    if (docs.existsSync())
      ...docs
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('_STATUS.md') &&
                file.path.contains('BLDS_PHASE_3_'),
          ),
  ];
  final forbidden = <RegExp>[
    RegExp(
      r'\bblds-owned\s+(?:source|changes)\b.{0,180}\bmit\b',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'\bmit\b.{0,100}\b(?:for|covers?)\s+blds-owned\s+'
      r'(?:source|changes)\b',
      caseSensitive: false,
      dotAll: true,
    ),
  ];
  for (final file in files.where((candidate) => candidate.existsSync())) {
    final source = file.readAsStringSync();
    if (forbidden.any((pattern) => pattern.hasMatch(source))) {
      final relative = file.path
          .substring(root.path.length + 1)
          .replaceAll('\\', '/');
      errors.add(
        'Categorical MIT ownership claim remains while project license '
        'authority is unresolved: $relative.',
      );
    }
  }
}

void _validateNotices(Directory root, List<String> errors) {
  final notice = File('${root.path}/THIRD_PARTY_NOTICES.md');
  if (!notice.existsSync()) {
    errors.add('THIRD_PARTY_NOTICES.md is missing.');
    return;
  }
  final text = notice.readAsStringSync();
  for (final required in const [
    'Noto Sans KR',
    'Material Icons',
    'Cupertino Icons',
    'Pretendard',
    'Google Fonts',
    'Astryx 0.1.3',
  ]) {
    if (!text.contains(required)) {
      errors.add('THIRD_PARTY_NOTICES.md is missing $required.');
    }
  }
}

void _validateSchemaPair(
  Directory root,
  String documentPath,
  String schemaPath,
  List<String> errors,
) {
  final documentFile = File('${root.path}/$documentPath');
  final schemaFile = File('${root.path}/$schemaPath');
  if (!documentFile.existsSync() || !schemaFile.existsSync()) {
    errors.add('Schema pair is missing: $documentPath / $schemaPath.');
    return;
  }
  try {
    final document = loadYaml(documentFile.readAsStringSync());
    final schema = jsonDecode(schemaFile.readAsStringSync());
    for (final error in validateJsonAgainstSchema(document, schema)) {
      errors.add('$documentPath $error');
    }
  } on Object catch (error) {
    errors.add('Schema validation failed for $documentPath: $error');
  }
}

File? _safeRepositorySource(
  Directory root,
  String path,
  String role,
  List<String> errors,
) {
  final problem = _repositoryRelativePathProblem(path);
  if (problem != null) {
    errors.add('Unsafe $role path rejected: $path ($problem).');
    return null;
  }
  final canonicalRoot = root.resolveSymbolicLinksSync();
  var cursor = canonicalRoot;
  final segments = path.split('/');
  for (var index = 0; index < segments.length; index += 1) {
    cursor = '$cursor${Platform.pathSeparator}${segments[index]}';
    final type = FileSystemEntity.typeSync(cursor, followLinks: false);
    if (type == FileSystemEntityType.link) {
      errors.add(
        index == segments.length - 1
            ? 'Unsafe $role source symlink rejected: $path.'
            : 'Unsafe $role parent symlink rejected: $path.',
      );
      return null;
    }
    if (index < segments.length - 1 &&
        type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.directory) {
      errors.add('Unsafe $role non-directory parent rejected: $path.');
      return null;
    }
  }
  final source = File(cursor);
  if (source.existsSync()) {
    final canonicalSource = source.resolveSymbolicLinksSync();
    if (!_isContained(canonicalRoot, canonicalSource)) {
      errors.add('Unsafe $role canonical escape rejected: $path.');
      return null;
    }
  }
  return source;
}

File? _safeDisposableDestination(
  Directory temp,
  String lane,
  String path,
  List<String> errors,
) {
  final problem = _repositoryRelativePathProblem(path);
  if (problem != null) {
    errors.add('Unsafe disposable $lane path rejected: $path ($problem).');
    return null;
  }
  final canonicalTemp = temp.resolveSymbolicLinksSync();
  final base = Directory('$canonicalTemp${Platform.pathSeparator}$lane')
    ..createSync();
  final canonicalBase = base.resolveSymbolicLinksSync();
  if (!_isContained(canonicalTemp, canonicalBase)) {
    errors.add('Disposable $lane root escapes the rehearsal directory.');
    return null;
  }
  var cursor = canonicalBase;
  final segments = path.split('/');
  for (final segment in segments.take(segments.length - 1)) {
    cursor = '$cursor${Platform.pathSeparator}$segment';
    if (!_isContained(canonicalBase, cursor)) {
      errors.add('Disposable $lane parent escapes containment: $path.');
      return null;
    }
    final type = FileSystemEntity.typeSync(cursor, followLinks: false);
    if (type == FileSystemEntityType.link) {
      errors.add('Disposable $lane parent symlink rejected: $path.');
      return null;
    }
    if (type == FileSystemEntityType.notFound) {
      Directory(cursor).createSync();
    } else if (type != FileSystemEntityType.directory) {
      errors.add('Disposable $lane parent is not a directory: $path.');
      return null;
    }
    final canonicalParent = Directory(cursor).resolveSymbolicLinksSync();
    if (!_isContained(canonicalBase, canonicalParent)) {
      errors.add('Disposable $lane parent escapes containment: $path.');
      return null;
    }
  }
  final destination = File('$cursor${Platform.pathSeparator}${segments.last}');
  if (!_isContained(canonicalBase, destination.absolute.path)) {
    errors.add('Disposable $lane destination escapes containment: $path.');
    return null;
  }
  if (FileSystemEntity.typeSync(destination.path, followLinks: false) ==
      FileSystemEntityType.link) {
    errors.add('Disposable $lane destination symlink rejected: $path.');
    return null;
  }
  return destination;
}

String? _repositoryRelativePathProblem(String path) {
  if (path.isEmpty) return 'empty';
  if (path.contains('\\')) return 'backslash-or-UNC';
  if (path.startsWith('/') || path.startsWith('//')) return 'absolute-or-UNC';
  if (RegExp(r'^[A-Za-z]:').hasMatch(path)) return 'drive-qualified';
  if (path.endsWith('/') || path.contains('//')) return 'not-normalized';
  final segments = path.split('/');
  if (segments.any((segment) => segment.isEmpty || segment == '.')) {
    return 'not-normalized';
  }
  if (segments.contains('..')) return 'parent-traversal';
  return null;
}

bool _isContained(String canonicalRoot, String candidate) =>
    candidate == canonicalRoot ||
    candidate.startsWith('$canonicalRoot${Platform.pathSeparator}');

String _sha256(File file) => sha256.convert(file.readAsBytesSync()).toString();

YamlMap _loadYamlMap(File file) {
  final value = loadYaml(file.readAsStringSync());
  if (value is! YamlMap) {
    throw FormatException('${file.path} must contain a mapping.');
  }
  return value;
}

YamlMap _map(Object? value) =>
    value is YamlMap ? value : throw const FormatException('Expected mapping.');

Map<String, Object?> _jsonMap(Object? value) {
  if (value is! Map) throw const FormatException('Expected JSON object.');
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}
