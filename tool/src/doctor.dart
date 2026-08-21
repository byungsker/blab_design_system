import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import 'contract_validation.dart';
import 'phase4_evidence_validation.dart';
import 'phase5_readiness_validation.dart';
import 'public_api_compatibility.dart';
import 'token_generation.dart';

const doctorEnvelopeSchema = 'blab.doctor-envelope/v1';
const doctorReportSchema = 'blab.doctor/v1';
const doctorToolVersion = '0.1.0';
const protectedDesignChecksum =
    '3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4';

enum DoctorSeverity { pass, warning, failure, information }

enum DoctorStatus { pass, warning, failure }

class DoctorCheck {
  const DoctorCheck({
    required this.id,
    required this.severity,
    required this.message,
  });

  final String id;
  final DoctorSeverity severity;
  final String message;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'severity': severity.name,
    'message': message,
  };
}

class DoctorReport {
  DoctorReport({required List<DoctorCheck> checks})
    : checks = List<DoctorCheck>.unmodifiable(
        [...checks]..sort((left, right) => left.id.compareTo(right.id)),
      );

  final List<DoctorCheck> checks;

  DoctorStatus get status {
    if (checks.any((check) => check.severity == DoctorSeverity.failure)) {
      return DoctorStatus.failure;
    }
    if (checks.any((check) => check.severity == DoctorSeverity.warning)) {
      return DoctorStatus.warning;
    }
    return DoctorStatus.pass;
  }

  int get exitCode => status == DoctorStatus.failure ? 1 : 0;

  Map<String, int> get summary => <String, int>{
    for (final severity in DoctorSeverity.values)
      severity.name: checks.where((check) => check.severity == severity).length,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': doctorReportSchema,
    'status': status.name,
    'exit_code': exitCode,
    'summary': summary,
    'checks': checks.map((check) => check.toJson()).toList(),
  };
}

class DoctorError {
  const DoctorError({required this.code, required this.message});

  final String code;
  final String message;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code,
    'message': message,
  };
}

class DoctorEnvelope {
  const DoctorEnvelope._({
    required this.ok,
    required this.result,
    required this.error,
  });

  factory DoctorEnvelope.success(DoctorReport report) {
    return DoctorEnvelope._(ok: true, result: report, error: null);
  }

  factory DoctorEnvelope.failure(String code, String message) {
    return DoctorEnvelope._(
      ok: false,
      result: null,
      error: DoctorError(code: code, message: message),
    );
  }

  final bool ok;
  final DoctorReport? result;
  final DoctorError? error;

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': doctorEnvelopeSchema,
    'tool_version': doctorToolVersion,
    'ok': ok,
    'result': result?.toJson(),
    'error': error?.toJson(),
  };
}

Future<DoctorEnvelope> buildDoctorEnvelope(Directory repositoryRoot) async {
  try {
    final checks = <DoctorCheck>[];
    final inspection = inspectBlabContract(repositoryRoot);
    final contractErrors = [...inspection.errors]..sort();
    checks.add(
      DoctorCheck(
        id: 'contract-validation',
        severity: contractErrors.isEmpty
            ? DoctorSeverity.pass
            : DoctorSeverity.failure,
        message: contractErrors.isEmpty
            ? 'The repository-owned design contract is structurally valid.'
            : _validationFailureMessage(contractErrors.length),
      ),
    );

    if (contractErrors.isEmpty) {
      final expected = buildGeneratedTokenOutputs(
        repositoryRoot,
        inspection: inspection,
      );
      final drift = findGeneratedTokenDrift(repositoryRoot, expected)..sort();
      checks.add(
        DoctorCheck(
          id: 'generation-drift',
          severity: drift.isEmpty
              ? DoctorSeverity.pass
              : DoctorSeverity.failure,
          message: drift.isEmpty
              ? 'All deterministic generated outputs match their sources.'
              : '${drift.length} generated output(s) differ or are missing.',
        ),
      );
    } else {
      checks.add(
        const DoctorCheck(
          id: 'generation-drift',
          severity: DoctorSeverity.failure,
          message:
              'Generation drift cannot be evaluated until the contract is '
              'valid.',
        ),
      );
    }

    checks.add(_apiSnapshotCheck(repositoryRoot));
    checks.add(_protectedDesignCheck(repositoryRoot));
    checks.add(_phase4EvidenceCheck(repositoryRoot));
    checks.add(_phase5LocalPreparationCheck(repositoryRoot));
    checks.add(_phase5ExitCheck(repositoryRoot));

    final contract = _loadOptionalYaml(
      File('${repositoryRoot.path}/$contractPath'),
    );
    checks
      ..add(_manifestProvenanceCheck(repositoryRoot, contract))
      ..add(_assetLedgerCheck(contract))
      ..add(_releaseAuthorityCheck(contract))
      ..add(_remoteCustodyCheck(contract))
      ..add(
        const DoctorCheck(
          id: 'phase-boundary',
          severity: DoctorSeverity.information,
          message:
              'Phase 1 is implemented locally and remains subject to final '
              'independent verification. Phase 2 is the shared interaction '
              'and accessibility foundation; Phase 3 remediates the nine '
              'existing public component families sequentially; Phase 4 has '
              'local story, candidate-golden, platform-matrix, and consumer '
              'preflight infrastructure with approval and external execution '
              'still pending; Phase 5 local compatibility, migration, rights, '
              'and release-readiness preparation is implemented while its '
              'exit, delivery, and publication remain blocked. Diagnostics '
              'do not establish visual, '
              'accessibility, platform, consumer, or locale conformance.',
        ),
      );

    return DoctorEnvelope.success(DoctorReport(checks: checks));
  } on Object {
    return DoctorEnvelope.failure(
      'doctor-internal-error',
      'BLDS doctor could not complete the local read-only checks.',
    );
  }
}

DoctorCheck _phase5LocalPreparationCheck(Directory repositoryRoot) {
  try {
    final errors = validatePhase5Readiness(repositoryRoot);
    return DoctorCheck(
      id: 'phase5-local-preparation',
      severity: errors.isEmpty ? DoctorSeverity.pass : DoctorSeverity.failure,
      message: errors.isEmpty
          ? 'Phase 5 local compatibility, migration, rollback, rights, and '
                'inventory preparation is structurally valid.'
          : '${errors.length} Phase 5 local-preparation error(s) must be '
                'resolved.',
    );
  } on Object {
    return const DoctorCheck(
      id: 'phase5-local-preparation',
      severity: DoctorSeverity.failure,
      message: 'Phase 5 local preparation could not be inspected safely.',
    );
  }
}

DoctorCheck _phase5ExitCheck(Directory repositoryRoot) {
  final readiness = _loadOptionalYaml(
    File('${repositoryRoot.path}/$phase5ReadinessPath'),
  );
  final exit = readiness == null
      ? null
      : _nestedValue(readiness, <String>['exit', 'phase5_complete']);
  final delivery = readiness == null
      ? null
      : _nestedValue(readiness, <String>['exit', 'delivery_ready']);
  final publication = readiness == null
      ? null
      : _nestedValue(readiness, <String>['exit', 'publication_ready']);
  final safelyBlocked =
      exit == false && delivery == false && publication == false;
  return DoctorCheck(
    id: 'phase5-exit',
    severity: safelyBlocked ? DoctorSeverity.warning : DoctorSeverity.failure,
    message: safelyBlocked
        ? 'Phase 5 exit, delivery, and publication remain blocked by the '
              'recorded TDC, rights, CI, consumer, and human-authority gates.'
        : 'Phase 5 exit boundary is missing or was unsafely opened.',
  );
}

DoctorCheck _phase4EvidenceCheck(Directory repositoryRoot) {
  try {
    final errors = validatePhase4Evidence(repositoryRoot);
    return DoctorCheck(
      id: 'phase4-evidence',
      severity: errors.isEmpty ? DoctorSeverity.pass : DoctorSeverity.failure,
      message: errors.isEmpty
          ? 'Phase 4 Design-approved local baseline evidence is structurally '
                'reproducible; independent Quality review, remote platform '
                'runs, and consumer smoke remain pending. This does not '
                'establish accessibility or visual conformance.'
          : '${errors.length} Phase 4 evidence contract error(s) must be '
                'resolved.',
    );
  } on Object {
    return const DoctorCheck(
      id: 'phase4-evidence',
      severity: DoctorSeverity.failure,
      message: 'Phase 4 local baseline evidence could not be inspected safely.',
    );
  }
}

DoctorCheck _apiSnapshotCheck(Directory repositoryRoot) {
  final snapshot = File('${repositoryRoot.path}/$publicApiSnapshotPath');
  if (!snapshot.existsSync()) {
    return const DoctorCheck(
      id: 'api-snapshot',
      severity: DoctorSeverity.failure,
      message: 'The checked-in public API snapshot is missing.',
    );
  }
  try {
    final checkedIn = snapshot.readAsStringSync();
    final expectedInput = publicApiSnapshotInputChecksum(checkedIn);
    final currentInput = buildPublicApiInputChecksum(repositoryRoot);
    final matches =
        expectedInput == currentInput &&
        publicApiSnapshotBodyChecksumMatches(checkedIn);
    return DoctorCheck(
      id: 'api-snapshot',
      severity: matches ? DoctorSeverity.pass : DoctorSeverity.failure,
      message: matches
          ? 'The analyzer-backed public API snapshot input and body '
                'checksums match.'
          : 'The public API input or checked-in analyzer snapshot body '
                'differs.',
    );
  } on Object {
    return const DoctorCheck(
      id: 'api-snapshot',
      severity: DoctorSeverity.failure,
      message: 'The analyzer-backed public API snapshot could not be checked.',
    );
  }
}

DoctorCheck _protectedDesignCheck(Directory repositoryRoot) {
  final file = File('${repositoryRoot.path}/DESIGN.md');
  final matches =
      file.existsSync() &&
      sha256.convert(file.readAsBytesSync()).toString() ==
          protectedDesignChecksum;
  return DoctorCheck(
    id: 'design-protection',
    severity: matches ? DoctorSeverity.pass : DoctorSeverity.failure,
    message: matches
        ? 'The protected legacy DESIGN.md checksum matches.'
        : 'The protected legacy DESIGN.md checksum differs or is missing.',
  );
}

DoctorCheck _manifestProvenanceCheck(
  Directory repositoryRoot,
  YamlMap? contract,
) {
  if (contract == null) {
    return const DoctorCheck(
      id: 'manifest-provenance',
      severity: DoctorSeverity.failure,
      message: 'Contract provenance manifests could not be inspected.',
    );
  }
  final refs = <String, String>{
    'component states':
        _nestedString(contract, <String>[
          'accessibility',
          'component_state_manifest_ref',
        ]) ??
        '',
    'visual baselines':
        _nestedString(contract, <String>[
          'accessibility',
          'visual_baseline_manifest_ref',
        ]) ??
        '',
    'glossary':
        _nestedString(contract, <String>['localization', 'glossary_ref']) ?? '',
  };
  final missing = <String>[];
  for (final entry in refs.entries) {
    final path = entry.value;
    if (path.isEmpty ||
        path.startsWith('/') ||
        path.split(RegExp(r'[/\\]')).contains('..') ||
        !File('${repositoryRoot.path}/$path').existsSync()) {
      missing.add(entry.key);
    }
  }
  return DoctorCheck(
    id: 'manifest-provenance',
    severity: missing.isEmpty ? DoctorSeverity.pass : DoctorSeverity.failure,
    message: missing.isEmpty
        ? 'State, visual-baseline, and glossary provenance is repository-owned.'
        : 'Missing or unsafe provenance manifest(s): ${missing.join(', ')}.',
  );
}

DoctorCheck _assetLedgerCheck(YamlMap? contract) {
  final status = contract == null
      ? null
      : _nestedString(contract, <String>['assets_and_fonts', 'ledger_status']);
  return DoctorCheck(
    id: 'remote-font-assets',
    severity: status == 'unresolved'
        ? DoctorSeverity.warning
        : DoctorSeverity.pass,
    message: status == 'unresolved'
        ? 'Remote font and asset activation remains unresolved.'
        : 'No unresolved remote font or asset ledger state is recorded.',
  );
}

DoctorCheck _releaseAuthorityCheck(YamlMap? contract) {
  final authorized = contract == null
      ? null
      : _nestedValue(contract, <String>[
          'license',
          'release_or_publication_authorized',
        ]);
  return DoctorCheck(
    id: 'release-authority',
    severity: authorized == true ? DoctorSeverity.pass : DoctorSeverity.warning,
    message: authorized == true
        ? 'The contract records release or publication authority.'
        : 'Release and publication authority is not granted by this contract.',
  );
}

DoctorCheck _remoteCustodyCheck(YamlMap? contract) {
  final status = contract == null
      ? null
      : _nestedString(contract, <String>[
          'provenance',
          'consumer_remote_custody',
          'status',
        ]);
  return DoctorCheck(
    id: 'repository-custody',
    severity: status == 'unresolved'
        ? DoctorSeverity.warning
        : DoctorSeverity.pass,
    message: status == 'unresolved'
        ? 'Repository custody remains unresolved in local evidence.'
        : 'Repository custody is recorded as resolved by local evidence.',
  );
}

YamlMap? _loadOptionalYaml(File file) {
  try {
    final document = loadYaml(file.readAsStringSync());
    return document is YamlMap ? document : null;
  } on Object {
    return null;
  }
}

Object? _nestedValue(Map<Object?, Object?> root, List<String> segments) {
  Object? value = root;
  for (final segment in segments) {
    if (value is! Map || !value.containsKey(segment)) {
      return null;
    }
    value = value[segment];
  }
  return value;
}

String? _nestedString(Map<Object?, Object?> root, List<String> segments) {
  final value = _nestedValue(root, segments);
  return value is String ? value : null;
}

String _validationFailureMessage(int errorCount) {
  return '$errorCount contract validation error(s) found.';
}

int doctorExitCode(DoctorEnvelope envelope) {
  return envelope.result?.exitCode ?? 1;
}

String renderDoctorJson(DoctorEnvelope envelope) {
  return '${const JsonEncoder.withIndent('  ').convert(envelope.toJson())}\n';
}

String renderDoctorHuman(DoctorEnvelope envelope) {
  final buffer = StringBuffer()..writeln('BLDS doctor $doctorToolVersion');
  final report = envelope.result;
  if (report == null) {
    buffer
      ..writeln('status: failure (exit 1)')
      ..writeln(
        '[FAILURE] ${envelope.error?.code ?? 'unknown-error'}: '
        '${envelope.error?.message ?? 'The check did not return a result.'}',
      );
    return buffer.toString();
  }
  buffer.writeln('status: ${report.status.name} (exit ${report.exitCode})');
  for (final check in report.checks) {
    buffer.writeln(
      '[${check.severity.name.toUpperCase()}] ${check.id}: ${check.message}',
    );
  }
  buffer.writeln(
    'summary: pass=${report.summary['pass']}, '
    'warning=${report.summary['warning']}, '
    'failure=${report.summary['failure']}, '
    'information=${report.summary['information']}',
  );
  return buffer.toString();
}

List<String> validateDoctorEnvelope(Object? rawEnvelope) {
  final errors = <String>[];
  if (rawEnvelope is! Map) {
    return <String>['Doctor envelope must be a JSON object.'];
  }
  if (rawEnvelope['schema'] != doctorEnvelopeSchema) {
    errors.add('Doctor envelope schema is invalid.');
  }
  if (rawEnvelope['tool_version'] != doctorToolVersion) {
    errors.add('Doctor tool version is invalid.');
  }
  if (rawEnvelope['ok'] is! bool) {
    errors.add('Doctor envelope ok must be a boolean.');
  }
  final result = rawEnvelope['result'];
  final error = rawEnvelope['error'];
  if ((result == null) == (error == null)) {
    errors.add('Doctor envelope must contain exactly one result or error.');
  }
  if (rawEnvelope['ok'] == true && (result == null || error != null)) {
    errors.add('Successful doctor envelopes must contain only a result.');
  }
  if (rawEnvelope['ok'] == false && (error == null || result != null)) {
    errors.add('Failed doctor envelopes must contain only an error.');
  }
  if (result != null) {
    _validateDoctorResult(result, errors);
  }
  if (error != null) {
    _validateDoctorError(error, errors);
  }
  return errors;
}

void _validateDoctorResult(Object? rawResult, List<String> errors) {
  if (rawResult is! Map) {
    errors.add('Doctor result must be a JSON object.');
    return;
  }
  if (rawResult['schema'] != doctorReportSchema) {
    errors.add('Doctor report schema is invalid.');
  }
  const statuses = <String>{'pass', 'warning', 'failure'};
  final status = rawResult['status'];
  if (status is! String || !statuses.contains(status)) {
    errors.add('Doctor status is invalid.');
  }
  final exitCode = rawResult['exit_code'];
  if (exitCode != 0 && exitCode != 1) {
    errors.add('Doctor exit_code must be 0 or 1.');
  }
  final checks = rawResult['checks'];
  final observedCounts = <String, int>{
    for (final severity in DoctorSeverity.values) severity.name: 0,
  };
  final ids = <String>[];
  if (checks is! List) {
    errors.add('Doctor checks must be a list.');
  } else {
    for (final check in checks) {
      if (check is! Map) {
        errors.add('Every doctor check must be a JSON object.');
        continue;
      }
      final id = check['id'];
      if (id is! String ||
          !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id)) {
        errors.add('Doctor check id is invalid.');
      } else {
        ids.add(id);
      }
      final severity = check['severity'];
      if (severity is! String || !observedCounts.containsKey(severity)) {
        errors.add('Doctor check severity is invalid.');
      } else {
        observedCounts[severity] = observedCounts[severity]! + 1;
      }
      if (check['message'] is! String || (check['message'] as String).isEmpty) {
        errors.add('Doctor check message must be a non-empty string.');
      }
    }
  }
  if (ids.toSet().length != ids.length) {
    errors.add('Doctor check ids must be unique.');
  }
  final sortedIds = [...ids]..sort();
  if (!_sameStrings(ids, sortedIds)) {
    errors.add('Doctor checks must be ordered lexicographically by id.');
  }
  final summary = rawResult['summary'];
  if (summary is! Map) {
    errors.add('Doctor summary must be a JSON object.');
  } else {
    for (final entry in observedCounts.entries) {
      if (summary[entry.key] != entry.value) {
        errors.add('Doctor summary ${entry.key} must equal ${entry.value}.');
      }
    }
  }
  final derivedStatus = observedCounts['failure']! > 0
      ? 'failure'
      : observedCounts['warning']! > 0
      ? 'warning'
      : 'pass';
  if (status != derivedStatus) {
    errors.add('Doctor status must equal derived status $derivedStatus.');
  }
  final derivedExitCode = derivedStatus == 'failure' ? 1 : 0;
  if (exitCode != derivedExitCode) {
    errors.add('Doctor exit_code must equal $derivedExitCode.');
  }
}

void _validateDoctorError(Object? rawError, List<String> errors) {
  if (rawError is! Map) {
    errors.add('Doctor error must be a JSON object.');
    return;
  }
  final code = rawError['code'];
  if (code is! String ||
      !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(code)) {
    errors.add('Doctor error code is invalid.');
  }
  if (rawError['message'] is! String ||
      (rawError['message'] as String).isEmpty) {
    errors.add('Doctor error message must be a non-empty string.');
  }
}

bool _sameStrings(List<String> left, List<String> right) {
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
