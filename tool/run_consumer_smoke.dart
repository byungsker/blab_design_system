import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'src/phase4_evidence_validation.dart';

Future<void> main(List<String> arguments) async {
  final execute = arguments.contains('--execute');
  final asJson = arguments.contains('--json');
  final unknown = arguments.where(
    (argument) => argument != '--execute' && argument != '--json',
  );
  if (unknown.isNotEmpty) {
    stderr.writeln(
      'Usage: dart run tool/run_consumer_smoke.dart [--json] [--execute]',
    );
    exitCode = 64;
    return;
  }

  final validation = validatePhase4Evidence(Directory.current);
  if (validation.isNotEmpty) {
    _emit(
      asJson,
      _SmokeResult(
        status: 'failed',
        reason: 'phase4-evidence-invalid',
        detail: validation.join(' | '),
      ),
    );
    exitCode = 1;
    return;
  }

  final document =
      loadYaml(File(representativeConsumersPath).readAsStringSync()) as YamlMap;
  final consumer = (document['consumers'] as YamlList)
      .whereType<YamlMap>()
      .singleWhere((entry) => entry['id'] == 'baroguni-app');
  final localPath = consumer['local_path'] as String;
  final repository = Directory(localPath);
  if (!repository.existsSync()) {
    _emit(
      asJson,
      const _SmokeResult(
        status: 'skipped',
        reason: 'consumer-checkout-missing',
        detail: 'The configured local consumer checkout is unavailable.',
      ),
    );
    return;
  }

  final head = await _git(repository.path, const <String>['rev-parse', 'HEAD']);
  if (head.exitCode != 0) {
    _emit(
      asJson,
      const _SmokeResult(
        status: 'skipped',
        reason: 'consumer-git-unreadable',
        detail: 'The configured consumer checkout could not be inspected.',
      ),
    );
    return;
  }
  final expectedHead = consumer['commit'] as String;
  if ((head.stdout as String).trim() != expectedHead) {
    _emit(
      asJson,
      _SmokeResult(
        status: 'skipped',
        reason: 'consumer-head-mismatch',
        detail: 'Consumer HEAD does not match pinned commit $expectedHead.',
      ),
    );
    return;
  }
  final remote = await _git(repository.path, const <String>[
    'remote',
    'get-url',
    'origin',
  ]);
  if (remote.exitCode != 0 ||
      (remote.stdout as String).trim() != consumer['repository']) {
    _emit(
      asJson,
      const _SmokeResult(
        status: 'skipped',
        reason: 'consumer-repository-mismatch',
        detail:
            'Consumer origin does not match the authoritative repository pin.',
      ),
    );
    return;
  }

  final status = await _git(repository.path, const <String>[
    'status',
    '--porcelain=v1',
    '--untracked-files=all',
  ]);
  if (status.exitCode != 0 || (status.stdout as String).trim().isNotEmpty) {
    _emit(
      asJson,
      const _SmokeResult(
        status: 'skipped',
        reason: 'consumer-worktree-dirty',
        detail:
            'Consumer execution is refused because the source worktree is '
            'not clean. No archive or dependency command was run.',
      ),
    );
    return;
  }
  if (consumer['custody'] != 'confirmed') {
    _emit(
      asJson,
      const _SmokeResult(
        status: 'skipped',
        reason: 'consumer-custody-unverified',
        detail:
            'Consumer execution requires confirmed custody and task authority.',
      ),
    );
    return;
  }
  if (consumer['execution_authority'] != 'confirmed') {
    _emit(
      asJson,
      const _SmokeResult(
        status: 'skipped',
        reason: 'consumer-authority-unverified',
        detail:
            'Consumer execution requires task-specific execution authority.',
      ),
    );
    return;
  }
  if (!execute) {
    _emit(
      asJson,
      const _SmokeResult(
        status: 'skipped',
        reason: 'execution-not-requested',
        detail:
            'All read-only preconditions passed, but isolated execution '
            'requires --execute.',
      ),
    );
    return;
  }

  final result = await _executeIsolated(
    repository: repository,
    consumer: consumer,
  );
  _emit(asJson, result);
  if (result.status == 'failed') {
    exitCode = 1;
  }
}

Future<ProcessResult> _git(String workingDirectory, List<String> arguments) {
  return Process.run('git', arguments, workingDirectory: workingDirectory);
}

void _emit(bool asJson, _SmokeResult result) {
  if (asJson) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'schema': 'blab.consumer-smoke-result/v1',
        'status': result.status,
        'reason': result.reason,
        'detail': result.detail,
        'mutated_consumer': false,
        'executed_commands': result.executedCommands,
      }),
    );
    return;
  }
  stdout.writeln('${result.status}: ${result.reason} — ${result.detail}');
}

class _SmokeResult {
  const _SmokeResult({
    required this.status,
    required this.reason,
    required this.detail,
    this.executedCommands = const <String>[],
  });

  final String status;
  final String reason;
  final String detail;
  final List<String> executedCommands;
}

Future<_SmokeResult> _executeIsolated({
  required Directory repository,
  required YamlMap consumer,
}) async {
  final packagePath = consumer['package_path'] as String;
  if (!_isSafeRelativePackagePath(packagePath)) {
    return const _SmokeResult(
      status: 'failed',
      reason: 'unsafe-package-path',
      detail: 'The configured package path is not a contained relative path.',
    );
  }
  final fixture = Directory.systemTemp.createTempSync('blab-consumer-smoke-');
  final archive = File('${fixture.path}/consumer.tar');
  final checkout = Directory('${fixture.path}/checkout')..createSync();
  final executed = <String>[];
  try {
    final archiveResult = await _git(repository.path, <String>[
      'archive',
      '--format=tar',
      '--output=${archive.path}',
      consumer['commit'] as String,
    ]);
    if (archiveResult.exitCode != 0) {
      return const _SmokeResult(
        status: 'failed',
        reason: 'consumer-archive-failed',
        detail: 'The pinned committed consumer could not be archived.',
      );
    }
    final extract = await Process.run('tar', <String>[
      '-xf',
      archive.path,
      '-C',
      checkout.path,
    ]);
    if (extract.exitCode != 0) {
      return const _SmokeResult(
        status: 'failed',
        reason: 'consumer-archive-extract-failed',
        detail: 'The temporary consumer archive could not be extracted.',
      );
    }
    final boundary = inspectIsolatedConsumerPackage(
      checkout: checkout,
      packagePath: packagePath,
    );
    if (!boundary.isSafe) {
      return _SmokeResult(
        status: 'failed',
        reason: boundary.reason!,
        detail: boundary.detail!,
      );
    }
    final isolatedPackage = boundary.packageDirectory!;
    boundary.overrideFile!.writeAsStringSync(
      'dependency_overrides:\n'
      '  blab_design_system:\n'
      '    path: ${Directory.current.absolute.path}\n',
      flush: true,
    );
    for (final command
        in (consumer['smoke']['commands'] as YamlList).whereType<String>()) {
      final invocation = _allowedInvocation(command);
      if (invocation == null) {
        return _SmokeResult(
          status: 'failed',
          reason: 'consumer-command-not-allowlisted',
          detail: 'Refused non-allowlisted command: $command',
          executedCommands: executed,
        );
      }
      final commandResult = await Process.run(
        invocation.$1,
        invocation.$2,
        workingDirectory: isolatedPackage.path,
      );
      executed.add(command);
      if (commandResult.exitCode != 0) {
        return _SmokeResult(
          status: 'failed',
          reason: 'consumer-command-failed',
          detail: '$command failed in the disposable archive.',
          executedCommands: executed,
        );
      }
    }
    return _SmokeResult(
      status: 'passed',
      reason: 'isolated-smoke-complete',
      detail: 'All allowlisted commands passed in a disposable pinned archive.',
      executedCommands: executed,
    );
  } finally {
    fixture.deleteSync(recursive: true);
  }
}

ConsumerPackageBoundary inspectIsolatedConsumerPackage({
  required Directory checkout,
  required String packagePath,
}) {
  if (!_isSafeRelativePackagePath(packagePath)) {
    return const ConsumerPackageBoundary.unsafe(
      reason: 'unsafe-package-path',
      detail: 'The configured package path is not a contained relative path.',
    );
  }
  if (FileSystemEntity.typeSync(checkout.path, followLinks: false) !=
      FileSystemEntityType.directory) {
    return const ConsumerPackageBoundary.unsafe(
      reason: 'consumer-checkout-boundary-unsafe',
      detail: 'The disposable checkout root is absent or is a symbolic link.',
    );
  }
  final package = Directory('${checkout.path}/$packagePath');
  final packageType = FileSystemEntity.typeSync(
    package.path,
    followLinks: false,
  );
  if (packageType == FileSystemEntityType.notFound) {
    return const ConsumerPackageBoundary.unsafe(
      reason: 'consumer-package-missing',
      detail: 'The configured package path is absent from the archive.',
    );
  }
  if (packageType != FileSystemEntityType.directory) {
    return const ConsumerPackageBoundary.unsafe(
      reason: 'consumer-package-boundary-unsafe',
      detail: 'The configured package root is not a real directory.',
    );
  }
  try {
    final checkoutReal = checkout.resolveSymbolicLinksSync();
    final packageReal = package.resolveSymbolicLinksSync();
    final prefix = checkoutReal.endsWith(Platform.pathSeparator)
        ? checkoutReal
        : '$checkoutReal${Platform.pathSeparator}';
    if (!packageReal.startsWith(prefix)) {
      return const ConsumerPackageBoundary.unsafe(
        reason: 'consumer-package-boundary-unsafe',
        detail:
            'The configured package path resolves outside the disposable '
            'checkout.',
      );
    }
    final override = File('$packageReal/pubspec_overrides.yaml');
    if (FileSystemEntity.typeSync(override.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      return const ConsumerPackageBoundary.unsafe(
        reason: 'consumer-override-path-occupied',
        detail:
            'The disposable package already contains a file or link at the '
            'override path; no write was attempted.',
      );
    }
    return ConsumerPackageBoundary.safe(
      packageDirectory: Directory(packageReal),
      overrideFile: override,
    );
  } on FileSystemException {
    return const ConsumerPackageBoundary.unsafe(
      reason: 'consumer-package-boundary-unresolvable',
      detail: 'The disposable package boundary could not be resolved safely.',
    );
  }
}

bool _isSafeRelativePackagePath(String packagePath) {
  if (packagePath.isEmpty ||
      packagePath.startsWith('/') ||
      packagePath.startsWith('\\') ||
      packagePath.contains('\\') ||
      RegExp(r'^[A-Za-z]:').hasMatch(packagePath)) {
    return false;
  }
  final segments = packagePath.split('/');
  return segments.every(
    (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
  );
}

class ConsumerPackageBoundary {
  const ConsumerPackageBoundary.safe({
    required this.packageDirectory,
    required this.overrideFile,
  }) : reason = null,
       detail = null;

  const ConsumerPackageBoundary.unsafe({
    required this.reason,
    required this.detail,
  }) : packageDirectory = null,
       overrideFile = null;

  final Directory? packageDirectory;
  final File? overrideFile;
  final String? reason;
  final String? detail;

  bool get isSafe => reason == null;
}

(String, List<String>)? _allowedInvocation(String command) {
  return switch (command) {
    'flutter pub get' => ('flutter', <String>['pub', 'get']),
    'flutter analyze' => ('flutter', <String>['analyze']),
    'flutter test' => ('flutter', <String>['test', '--concurrency=1']),
    'flutter build bundle --release' => (
      'flutter',
      <String>['build', 'bundle', '--release'],
    ),
    _ => null,
  };
}
