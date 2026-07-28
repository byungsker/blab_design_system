import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'src/platform_executable.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1 ||
      !const {'--write', '--check'}.contains(arguments.single)) {
    stderr.writeln(
      'Usage: dart run tool/capture_package_dry_run.dart --write|--check',
    );
    exitCode = 64;
    return;
  }
  final write = arguments.single == '--write';
  final result = await Process.run(
    platformExecutable('flutter'),
    const ['pub', 'publish', '--dry-run'],
    workingDirectory: Directory.current.path,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final output = '${result.stdout}${result.stderr}';
  final files = parsePackageArchiveFiles(output);
  final compressed = RegExp(
    r'Total compressed archive size: ([^\n.]+)',
  ).firstMatch(output)?.group(1);
  final warnings = <String>[
    if (output.contains('checked-in files are modified in git'))
      'dirty-git-state',
    if (output.contains('Rename the top-level "docs" directory to "doc"'))
      'pub-doc-layout',
  ];
  final nameManifest = files.join('\n');
  final contentManifest = files
      .map((path) {
        final file = File('${Directory.current.path}/$path');
        final digest = sha256.convert(file.readAsBytesSync());
        return '$path\u0000$digest';
      })
      .join('\n');
  final document = <String, Object?>{
    'schema': 'blab.package-dry-run-inventory/v1',
    'as_of': '2026-07-28',
    'command': 'flutter pub publish --dry-run',
    'publication_performed': false,
    'exit_code': result.exitCode,
    'archive_name': 'blab_design_system-0.2.0.tar.gz',
    'compressed_archive_size': compressed,
    'compressed_archive_size_scope':
        'informational-platform-dependent-local-observation',
    'warning_ids': warnings,
    'file_count': files.length,
    'name_manifest_sha256': sha256
        .convert(utf8.encode(nameManifest))
        .toString(),
    'content_manifest_sha256': sha256
        .convert(utf8.encode(contentManifest))
        .toString(),
    'files': files,
  };
  final file = File(
    '${Directory.current.path}/contracts/release/'
    'package-dry-run-inventory.json',
  );
  final encoded = '${const JsonEncoder.withIndent('  ').convert(document)}\n';
  if (write) {
    file
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(encoded, flush: true);
  } else if (!file.existsSync() ||
      !packageDryRunInventoriesMatchStable(file.readAsStringSync(), document)) {
    stderr.writeln(
      'Package dry-run inventory drift detected. Run '
      '`dart run tool/capture_package_dry_run.dart --write`.',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln(
    '${write ? 'Captured' : 'Verified'} ${files.length} dry-run archive '
    'files, exit '
    '${result.exitCode}, warnings ${warnings.join(', ')}. No publication '
    'was performed.',
  );
}

bool packageDryRunInventoriesMatchStable(
  String recordedSource,
  Map<String, Object?> observed,
) {
  final recordedValue = jsonDecode(recordedSource);
  if (recordedValue is! Map) {
    return false;
  }
  final recorded = recordedValue.map(
    (key, value) => MapEntry(key.toString(), value),
  );
  final recordedSize = recorded.remove('compressed_archive_size');
  final observedStable = Map<String, Object?>.of(observed)
    ..remove('compressed_archive_size');
  return recordedSize is String &&
      recordedSize.isNotEmpty &&
      const JsonEncoder().convert(recorded) ==
          const JsonEncoder().convert(observedStable);
}

List<String> parsePackageArchiveFiles(String output) {
  final stack = <String>[];
  final files = <String>[];
  final linePattern = RegExp(r'^([│ ]*)(?:├──|└──) (.+)$');
  final sizePattern = RegExp(r' \((?:<)?[0-9]+(?:\.[0-9]+)? [KMG]?B\)$');
  for (final line in const LineSplitter().convert(output)) {
    final match = linePattern.firstMatch(line);
    if (match == null) continue;
    final prefix = match.group(1)!;
    final depth = prefix.runes.length ~/ 4;
    final rawName = match.group(2)!;
    final isFile = sizePattern.hasMatch(rawName);
    final name = rawName.replaceFirst(sizePattern, '');
    while (stack.length > depth) {
      stack.removeLast();
    }
    if (isFile) {
      files.add([...stack, name].join('/'));
    } else {
      if (stack.length == depth) {
        stack.add(name);
      } else {
        stack[depth] = name;
      }
    }
  }
  files.sort();
  return files;
}
