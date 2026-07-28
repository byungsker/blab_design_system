import 'dart:io';

Future<void> main() async {
  try {
    final passed = await runVerificationWithExampleBuildCleanup(
      repositoryRoot: Directory.current,
      verification: _runVerification,
    );
    if (!passed) {
      exitCode = 1;
    }
  } on FileSystemException catch (error) {
    stderr.writeln('BLDS example build cleanup failed safely: $error');
    exitCode = 1;
  }
}

Future<bool> _runVerification() async {
  final commands = <_VerificationCommand>[
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>['run', 'tool/validate_verify_cleanup.dart'],
      label: 'Example build cleanup success and failure validation',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>['run', 'tool/validate_diff_hygiene.dart'],
      label: 'Exact diff hygiene and immutable-byte exception validation',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>[
        'format',
        '--output=none',
        '--set-exit-if-changed',
        'lib',
        'example/lib',
        'test',
        'tool',
      ],
      label: 'Dart format check',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>['run', 'tool/validate_contract.dart'],
      label: 'Contract validation',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>['run', 'tool/generate_tokens.dart', '--check'],
      label: 'Generated output drift check',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>['run', 'tool/public_api_snapshot.dart', '--check'],
      label: 'Public API snapshot check',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>['run', 'tool/validate_phase5_baselines.dart'],
      label: 'Git-object-backed Phase 5 baseline trust check',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>['run', 'tool/validate_workflow.dart'],
      label: 'Workflow syntax and authority check',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>['run', 'tool/validate_phase4_evidence.dart'],
      label: 'Phase 4 evidence contract, story, platform, and golden check',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>[
        'run',
        'tool/generate_phase5_inventories.dart',
        '--check',
      ],
      label: 'Phase 5 file-origin and dependency inventory drift check',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>[
        'run',
        'tool/capture_package_dry_run.dart',
        '--check',
      ],
      label: 'Nonpublishing package composition and digest drift check',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>['run', 'tool/validate_phase5_readiness.dart'],
      label: 'Phase 5 local compatibility, rights, and readiness validation',
    ),
    const _VerificationCommand(
      executable: 'dart',
      arguments: <String>['run', 'tool/run_consumer_smoke.dart', '--json'],
      label: 'Representative consumer read-only preflight',
    ),
  ];

  for (final command in commands) {
    if (!await _run(command)) {
      return false;
    }
  }
  if (!await _runDoctorJsonValidation()) {
    return false;
  }
  for (final command in const <_VerificationCommand>[
    _VerificationCommand(
      executable: 'flutter',
      arguments: <String>['analyze', '--no-pub'],
      label: 'Flutter analyze',
    ),
    _VerificationCommand(
      executable: 'flutter',
      arguments: <String>[
        'test',
        '--no-pub',
        '--concurrency=1',
        '--exclude-tags=phase4-candidate',
      ],
      label: 'Flutter package tests',
    ),
    _VerificationCommand(
      executable: 'flutter',
      arguments: <String>[
        'test',
        '--no-pub',
        '--concurrency=1',
        'test/phase4_candidate_golden_test.dart',
      ],
      label: 'Candidate Latin and Korean golden drift check',
    ),
    _VerificationCommand(
      executable: 'flutter',
      arguments: <String>[
        'test',
        '--no-pub',
        '--concurrency=1',
        'test/phase4_candidate_rtl_golden_test.dart',
      ],
      label: 'Candidate Arabic RTL golden drift check',
    ),
    _VerificationCommand(
      executable: 'flutter',
      arguments: <String>['analyze', '--no-pub'],
      label: 'Example analyze',
      workingDirectory: 'example',
    ),
    _VerificationCommand(
      executable: 'flutter',
      arguments: <String>['build', 'bundle', '--release', '--no-pub'],
      label: 'Example release bundle build',
      workingDirectory: 'example',
    ),
  ]) {
    if (!await _run(command)) {
      return false;
    }
  }
  stdout.writeln('BLDS local verification passed.');
  return true;
}

Future<bool> runVerificationWithExampleBuildCleanup({
  required Directory repositoryRoot,
  required Future<bool> Function() verification,
}) async {
  try {
    return await verification();
  } finally {
    final result = cleanupExactExampleBuild(repositoryRoot);
    if (!result.success) {
      throw FileSystemException(result.detail, result.path);
    }
  }
}

ExampleBuildCleanupResult cleanupExactExampleBuild(Directory repositoryRoot) {
  try {
    if (FileSystemEntity.typeSync(repositoryRoot.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      return ExampleBuildCleanupResult.failure(
        path: repositoryRoot.path,
        detail: 'Repository root must be a real directory.',
      );
    }
    final canonicalRoot = repositoryRoot.resolveSymbolicLinksSync();
    final example = Directory('$canonicalRoot/example');
    if (FileSystemEntity.typeSync(example.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      return ExampleBuildCleanupResult.failure(
        path: example.path,
        detail: 'Repository example path must be a real directory.',
      );
    }
    final canonicalExample = example.resolveSymbolicLinksSync();
    final build = Directory('$canonicalExample/build');
    if (build.path.split(Platform.pathSeparator).last != 'build') {
      return ExampleBuildCleanupResult.failure(
        path: build.path,
        detail: 'Cleanup target basename must be build.',
      );
    }
    final targetType = FileSystemEntity.typeSync(
      build.path,
      followLinks: false,
    );
    if (targetType == FileSystemEntityType.notFound) {
      return ExampleBuildCleanupResult.success(
        path: build.path,
        removed: false,
      );
    }
    if (targetType != FileSystemEntityType.directory) {
      return ExampleBuildCleanupResult.failure(
        path: build.path,
        detail: 'Cleanup target must be a real non-symlink directory.',
      );
    }
    final canonicalBuild = build.resolveSymbolicLinksSync();
    if (Directory(canonicalBuild).parent.path != canonicalExample) {
      return ExampleBuildCleanupResult.failure(
        path: canonicalBuild,
        detail: 'Cleanup target must be exactly inside repository example.',
      );
    }
    Directory(canonicalBuild).deleteSync(recursive: true);
    return ExampleBuildCleanupResult.success(
      path: canonicalBuild,
      removed: true,
    );
  } on FileSystemException catch (error) {
    return ExampleBuildCleanupResult.failure(
      path: error.path ?? repositoryRoot.path,
      detail: error.message,
    );
  }
}

class ExampleBuildCleanupResult {
  const ExampleBuildCleanupResult.success({
    required this.path,
    required this.removed,
  }) : success = true,
       detail = '';

  const ExampleBuildCleanupResult.failure({
    required this.path,
    required this.detail,
  }) : success = false,
       removed = false;

  final bool success;
  final bool removed;
  final String path;
  final String detail;
}

Future<bool> _run(_VerificationCommand command) async {
  stdout.writeln('==> ${command.label}');
  final process = await Process.start(
    command.executable,
    command.arguments,
    workingDirectory: command.workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  return await process.exitCode == 0;
}

Future<bool> _runDoctorJsonValidation() async {
  stdout.writeln('==> Doctor JSON and schema-content validation');
  final result = await Process.run('dart', const <String>[
    'run',
    'tool/blab_doctor.dart',
    '--json',
  ]);
  if (result.exitCode != 0) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    return false;
  }
  final fixture = Directory.systemTemp.createTempSync(
    'blab-doctor-validation-',
  );
  try {
    final doctorFile = File('${fixture.path}/doctor.json')
      ..writeAsStringSync(result.stdout as String, flush: true);
    return await _run(
      _VerificationCommand(
        executable: 'dart',
        arguments: <String>[
          'run',
          'tool/validate_doctor_json.dart',
          doctorFile.path,
        ],
        label: 'Doctor JSON schema-content validator',
      ),
    );
  } finally {
    fixture.deleteSync(recursive: true);
  }
}

class _VerificationCommand {
  const _VerificationCommand({
    required this.executable,
    required this.arguments,
    required this.label,
    this.workingDirectory,
  });

  final String executable;
  final List<String> arguments;
  final String label;
  final String? workingDirectory;
}
