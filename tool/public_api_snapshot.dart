import 'dart:io';

import 'src/public_api_snapshot.dart';

Future<void> main(List<String> arguments) async {
  const allowedArguments = {'--check', '--write'};
  if (arguments.length != 1 || !allowedArguments.contains(arguments.single)) {
    stderr.writeln(
      'Usage: dart run tool/public_api_snapshot.dart --check|--write',
    );
    exitCode = 64;
    return;
  }

  final repositoryRoot = Directory.current;
  final snapshot = await buildPublicApiSnapshot(repositoryRoot);
  final snapshotFile = File('${repositoryRoot.path}/$publicApiSnapshotPath');

  if (arguments.single == '--write') {
    snapshotFile.parent.createSync(recursive: true);
    snapshotFile.writeAsStringSync(snapshot);
    stdout.writeln('Wrote $publicApiSnapshotPath.');
    return;
  }

  if (!snapshotFile.existsSync()) {
    stderr.writeln(
      'Public API snapshot is missing. Generate it with '
      '`dart run tool/public_api_snapshot.dart --write`.',
    );
    exitCode = 1;
    return;
  }

  final expected = snapshotFile.readAsStringSync();
  if (expected != snapshot) {
    stderr.writeln(
      'Public API drift detected. Review the change, then regenerate with '
      '`dart run tool/public_api_snapshot.dart --write`.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Public API snapshot check passed.');
}
