import 'dart:io';

import 'package:yaml/yaml.dart';

import 'phase5_compatibility.dart';
import 'public_api_snapshot.dart';

const phase5BaselineAdmissionPath =
    'contracts/compatibility/baseline-admission.template.yaml';

Future<List<String>> validatePhase5Baselines(
  Directory root, {
  bool reproduceApi = true,
}) async {
  final errors = <String>[];
  final provenanceFile = File('${root.path}/$phase5CompatibilityBaselinePath');
  if (!provenanceFile.existsSync()) {
    return ['$phase5CompatibilityBaselinePath is missing.'];
  }
  final provenance = _map(loadYaml(provenanceFile.readAsStringSync()));
  final metadata = _map(provenance['metadata']);
  final origin = _map(provenance['origin']);
  final api = _map(provenance['api']);
  final tokens = _map(provenance['tokens']);
  final commit = origin['commit'];
  if (metadata['mutation_policy'] != 'never-regenerate-in-place' ||
      metadata['admission_workflow'] != phase5BaselineAdmissionPath ||
      origin['git_object_validation'] != 'required-cat-file-commit' ||
      api['reproducibility_check'] !=
          'analyzer-regeneration-from-origin-commit-lib-blobs-with-pinned-local-package-config-no-network' ||
      tokens['reproducibility_check'] !=
          'byte-equality-with-git-show-origin.commit-source_path_at_origin') {
    errors.add(
      'Baseline provenance must require immutable Git-backed reproduction '
      'and separate human-bound admission.',
    );
  }
  if (commit is! String || !RegExp(r'^[a-f0-9]{40,64}$').hasMatch(commit)) {
    return ['Baseline origin.commit must be a full hexadecimal Git object id.'];
  }

  final commitCheck = await Process.run('git', [
    'cat-file',
    '-e',
    '$commit^{commit}',
  ], workingDirectory: root.path);
  if (commitCheck.exitCode != 0) {
    return ['Baseline origin.commit is not an available Git commit object.'];
  }

  final tokenBaseline = _safeFile(
    root,
    tokens['path'],
    'token baseline',
    errors,
  );
  final tokenSourcePath = tokens['source_path_at_origin'];
  if (tokenBaseline != null &&
      tokenSourcePath is String &&
      _normalizedRelative(tokenSourcePath)) {
    _checkDeclaredDigest(tokenBaseline, tokens['sha256'], errors);
    final gitBytes = await _gitBlob(root, commit, tokenSourcePath);
    if (gitBytes == null ||
        !_bytesEqual(tokenBaseline.readAsBytesSync(), gitBytes)) {
      errors.add(
        'Token baseline does not equal origin.commit Git blob: '
        '$tokenSourcePath.',
      );
    }
  } else if (tokenSourcePath is! String ||
      !_normalizedRelative(tokenSourcePath)) {
    errors.add('Token baseline source_path_at_origin is unsafe.');
  }

  final apiBaseline = _safeFile(root, api['path'], 'API baseline', errors);
  if (apiBaseline != null) {
    _checkDeclaredDigest(apiBaseline, api['sha256'], errors);
    final snapshot = apiBaseline.readAsStringSync();
    if (!publicApiSnapshotBodyChecksumMatches(snapshot)) {
      errors.add('API baseline body checksum is invalid.');
    }
    if (reproduceApi) {
      final reproduced = await _reproduceApiSnapshot(root, commit, errors);
      if (reproduced != null && reproduced != snapshot) {
        errors.add(
          'API baseline is not reproducible from origin.commit source.',
        );
      }
    }
  }

  final admission = File('${root.path}/$phase5BaselineAdmissionPath');
  if (!admission.existsSync()) {
    errors.add('$phase5BaselineAdmissionPath is missing.');
  } else {
    final document = _map(loadYaml(admission.readAsStringSync()));
    final authority = _map(document['authority']);
    final boundary = _map(document['boundary']);
    if (authority['status'] != 'human-approval-required' ||
        authority['approved'] != false ||
        boundary['mutate_existing_baseline'] != false ||
        boundary['admission_performed'] != false) {
      errors.add(
        'Mutable baseline admission must remain separate and human-bound.',
      );
    }
  }
  return errors..sort();
}

Future<String?> _reproduceApiSnapshot(
  Directory root,
  String commit,
  List<String> errors,
) async {
  final packageConfig = File('${root.path}/.dart_tool/package_config.json');
  if (!packageConfig.existsSync()) {
    errors.add(
      'Pinned local package configuration is missing for API reproduction.',
    );
    return null;
  }
  final listing = await Process.run('git', [
    'ls-tree',
    '-r',
    '--name-only',
    commit,
    '--',
    'lib',
    'pubspec.yaml',
  ], workingDirectory: root.path);
  if (listing.exitCode != 0) {
    errors.add('Could not enumerate origin.commit API source inputs.');
    return null;
  }
  final paths = (listing.stdout as String)
      .split('\n')
      .where((path) => path.isNotEmpty)
      .where(_normalizedRelative)
      .toList();
  if (!paths.contains('lib/blab_design_system.dart')) {
    errors.add('origin.commit has no public BLDS library.');
    return null;
  }

  final temp = Directory.systemTemp.createTempSync('blds-phase5-baseline-');
  try {
    for (final path in paths) {
      final bytes = await _gitBlob(root, commit, path);
      if (bytes == null) {
        errors.add('Could not read origin.commit API source: $path.');
        return null;
      }
      File('${temp.path}/$path')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(bytes, flush: true);
    }
    final tempPackageConfig = File(
      '${temp.path}/.dart_tool/package_config.json',
    )..parent.createSync(recursive: true);
    packageConfig.copySync(tempPackageConfig.path);
    return await buildPublicApiSnapshot(temp);
  } on Object catch (error) {
    errors.add('API baseline reproduction failed safely: $error');
    return null;
  } finally {
    temp.deleteSync(recursive: true);
    if (temp.existsSync()) {
      errors.add('API baseline reproduction cleanup failed.');
    }
  }
}

Future<List<int>?> _gitBlob(Directory root, String commit, String path) async {
  if (!_normalizedRelative(path)) return null;
  final result = await Process.run(
    'git',
    ['show', '$commit:$path'],
    workingDirectory: root.path,
    stdoutEncoding: null,
  );
  if (result.exitCode != 0 || result.stdout is! List<int>) return null;
  return (result.stdout as List<int>);
}

File? _safeFile(
  Directory root,
  Object? rawPath,
  String role,
  List<String> errors,
) {
  if (rawPath is! String || !_normalizedRelative(rawPath)) {
    errors.add('$role path is unsafe.');
    return null;
  }
  final canonicalRoot = root.resolveSymbolicLinksSync();
  final file = File('${root.path}/$rawPath');
  if (!file.existsSync()) {
    errors.add('$role is missing: $rawPath.');
    return null;
  }
  if (FileSystemEntity.typeSync(file.path, followLinks: false) ==
      FileSystemEntityType.link) {
    errors.add('$role symlink is forbidden: $rawPath.');
    return null;
  }
  final canonical = file.resolveSymbolicLinksSync();
  if (canonical != canonicalRoot &&
      !canonical.startsWith('$canonicalRoot${Platform.pathSeparator}')) {
    errors.add('$role escapes repository containment: $rawPath.');
    return null;
  }
  return file;
}

void _checkDeclaredDigest(File file, Object? expected, List<String> errors) {
  if (expected is! String || sha256File(file) != expected) {
    errors.add('Baseline declared checksum mismatch: ${file.path}.');
  }
}

bool _normalizedRelative(String path) =>
    path.isNotEmpty &&
    !path.startsWith('/') &&
    !path.contains('\\') &&
    !path.contains('//') &&
    !path.endsWith('/') &&
    !RegExp(r'^[A-Za-z]:').hasMatch(path) &&
    !path
        .split('/')
        .any((segment) => segment.isEmpty || segment == '.' || segment == '..');

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

YamlMap _map(Object? value) =>
    value is YamlMap ? value : throw const FormatException('Expected mapping.');
