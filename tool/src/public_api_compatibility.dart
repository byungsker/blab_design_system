import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const publicLibraryPath = 'lib/blab_design_system.dart';
const publicApiSnapshotPath = 'api/blab_design_system.api.txt';

String buildPublicApiInputChecksum(Directory repositoryRoot) {
  final library = File('${repositoryRoot.path}/$publicLibraryPath');
  if (!library.existsSync()) {
    throw StateError('Missing public library input.');
  }
  final source = library.readAsStringSync();
  final paths = <String>[publicLibraryPath];
  final exportPattern = RegExp(r"^\s*export\s+'([^']+)';", multiLine: true);
  for (final match in exportPattern.allMatches(source)) {
    final relative = match.group(1)!;
    if (relative.startsWith('/') ||
        relative.split(RegExp(r'[/\\]')).contains('..')) {
      throw StateError('Unsafe public API export path.');
    }
    paths.add('lib/$relative');
  }
  paths.sort();
  final canonicalRoot = repositoryRoot.resolveSymbolicLinksSync();
  final bytes = <int>[];
  for (final path in paths) {
    final file = File('${repositoryRoot.path}/$path');
    if (!file.existsSync()) {
      throw StateError('Missing public API input.');
    }
    final canonicalFile = file.resolveSymbolicLinksSync();
    if (canonicalFile != canonicalRoot &&
        !canonicalFile.startsWith('$canonicalRoot${Platform.pathSeparator}')) {
      throw StateError('Public API input escapes the repository.');
    }
    bytes
      ..addAll(utf8.encode(path))
      ..add(0)
      ..addAll(file.readAsBytesSync())
      ..add(0x0A);
  }
  return sha256.convert(bytes).toString();
}

String? publicApiSnapshotInputChecksum(String snapshot) {
  return RegExp(
    r'^# Public API input checksum \(SHA-256\): ([a-f0-9]{64})$',
    multiLine: true,
  ).firstMatch(snapshot)?.group(1);
}

bool publicApiSnapshotBodyChecksumMatches(String snapshot) {
  final match = RegExp(
    r'^# Content checksum \(SHA-256, body only\): ([a-f0-9]{64})$',
    multiLine: true,
  ).firstMatch(snapshot);
  final separator = snapshot.indexOf('\n\n');
  if (match == null || separator == -1) {
    return false;
  }
  final body = snapshot.substring(separator + 2);
  return sha256.convert(utf8.encode(body)).toString() == match.group(1);
}
