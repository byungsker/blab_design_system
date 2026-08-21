import 'dart:io';

const _allowedCandidateRoots = <String>{
  '.github',
  'api',
  'contracts',
  'doc',
  'docs',
  'example',
  'generated',
  'lib',
  'test',
  'tool',
};

const _allowedCandidateFiles = <String>{
  '.gitignore',
  '.pubignore',
  'AGENTS.md',
  'CHANGELOG.md',
  'LICENSE',
  'README.md',
  'THIRD_PARTY_NOTICES.md',
  'analysis_options.yaml',
  'dart_test.yaml',
  'pubspec.lock',
  'pubspec.yaml',
};

List<String> freshCloneEquivalentOriginPaths(Directory root) {
  final tracked = _gitPaths(root, const ['ls-files', '--cached', '-z', '--']);
  final candidates = _gitPaths(root, const [
    'ls-files',
    '--others',
    '--exclude-standard',
    '-z',
    '--',
  ]).where(_explicitCandidatePath);
  final paths =
      <String>{...tracked, ...candidates}
          .where((path) => !_localConfigurationPath(path))
          .where((path) => _normalizedRelativePath(path))
          .where((path) {
            final absolute =
                '${root.path}${Platform.pathSeparator}'
                '${path.replaceAll('/', Platform.pathSeparator)}';
            return FileSystemEntity.typeSync(absolute, followLinks: false) ==
                FileSystemEntityType.file;
          })
          .toList()
        ..sort();
  return paths;
}

Iterable<String> _gitPaths(Directory root, List<String> arguments) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: root.path,
    stdoutEncoding: const SystemEncoding(),
    stderrEncoding: const SystemEncoding(),
  );
  if (result.exitCode != 0) {
    throw StateError(
      'Git origin inventory selection failed: ${(result.stderr as String).trim()}',
    );
  }
  return (result.stdout as String)
      .split('\u0000')
      .where((path) => path.isNotEmpty);
}

bool _explicitCandidatePath(String path) {
  if (_allowedCandidateFiles.contains(path)) return true;
  final separator = path.indexOf('/');
  final root = separator == -1 ? path : path.substring(0, separator);
  return _allowedCandidateRoots.contains(root);
}

bool _localConfigurationPath(String path) {
  final segments = path.split('/');
  if (segments.any(
    (segment) => const {
      '.claude',
      '.codex',
      '.idea',
      '.vscode',
      '.fleet',
      '.zed',
    }.contains(segment),
  )) {
    return true;
  }
  final name = segments.last;
  return name == '.DS_Store' ||
      name.endsWith('.iml') ||
      name.endsWith('.code-workspace') ||
      name.endsWith('.sublime-project') ||
      name.endsWith('.sublime-workspace');
}

bool _normalizedRelativePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains('\\') ||
      path.endsWith('/') ||
      path.contains('//') ||
      RegExp(r'^[A-Za-z]:').hasMatch(path)) {
    return false;
  }
  final segments = path.split('/');
  return !segments.any(
    (segment) => segment.isEmpty || segment == '.' || segment == '..',
  );
}
