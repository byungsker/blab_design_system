import 'dart:io';

import 'verify.dart' as verification;

Future<void> main() async {
  _expect(
    verification.isExactExampleBuildPath(r'C:\workspace\example/build'),
    'Windows mixed-separator example/build path must retain its build basename.',
  );
  _expect(
    !verification.isExactExampleBuildPath(r'C:\workspace\example/build-old'),
    'Only the exact build basename may be accepted for cleanup.',
  );
  final fixture = Directory.systemTemp.createTempSync(
    'blab-verify-cleanup-test-',
  );
  try {
    final example = Directory('${fixture.path}/example')..createSync();
    final repositorySentinel = File('${fixture.path}/repository-sentinel')
      ..writeAsStringSync('preserve');
    final exampleSentinel = File('${example.path}/example-sentinel')
      ..writeAsStringSync('preserve');

    final success = await verification.runVerificationWithExampleBuildCleanup(
      repositoryRoot: fixture,
      verification: () async {
        final build = Directory('${example.path}/build')..createSync();
        File('${build.path}/success-output').writeAsStringSync('generated');
        return true;
      },
    );
    _expect(success, 'Successful verification result must be preserved.');
    _expect(
      !Directory('${example.path}/build').existsSync(),
      'Successful verification must clean the exact example/build directory.',
    );
    _expect(
      repositorySentinel.readAsStringSync() == 'preserve' &&
          exampleSentinel.readAsStringSync() == 'preserve',
      'Successful cleanup must not delete broader repository/example paths.',
    );

    final failure = await verification.runVerificationWithExampleBuildCleanup(
      repositoryRoot: fixture,
      verification: () async {
        final build = Directory('${example.path}/build')..createSync();
        File('${build.path}/failure-output').writeAsStringSync('generated');
        return false;
      },
    );
    _expect(!failure, 'Failed verification result must be preserved.');
    _expect(
      !Directory('${example.path}/build').existsSync(),
      'Failed verification must clean the exact example/build directory.',
    );
    _expect(
      repositorySentinel.readAsStringSync() == 'preserve' &&
          exampleSentinel.readAsStringSync() == 'preserve',
      'Failure cleanup must not delete broader repository/example paths.',
    );
  } finally {
    fixture.deleteSync(recursive: true);
  }
  stdout.writeln(
    'BLDS example build cleanup success and failure validation passed.',
  );
}

void _expect(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}
