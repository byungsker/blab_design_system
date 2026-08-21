import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

const _activeDeliveryContractPath =
    'contracts/delivery/blab-design-system-0.2.0.yaml';

const _exactAllowedWarnings = <String, ({String message, String sha256})>{
  'api/blab_design_system.api.txt': (
    message: 'new blank line at EOF.',
    sha256: '469f79a1c46da12bb4ac76a55565bcbe118e82a7fe3cc694b63a6ea71794ac5c',
  ),
  'contracts/compatibility/baselines/head-ee78fbe.api.txt': (
    message: 'new blank line at EOF.',
    sha256: '69d604922ef6f4109dcf03afc23fcc5b9c5cf0342afa0fd422dcdd556fc16089',
  ),
  'generated/blab.tokens.css': (
    message: 'new blank line at EOF.',
    sha256: '6436f56bc38e1d3b473a25987be08592641d40aadb5db219292d2ad164ee8076',
  ),
  'test/assets/fonts/LICENSE-NOTO-SANS-ARABIC.txt': (
    message: 'trailing whitespace.',
    sha256: '07fc70bfeb985cc1a87a8587d0a0c80bab11c86c9dc3fd95b6f0cb332f983e96',
  ),
  'test/assets/fonts/LICENSE-NOTO-SANS-KR.txt': (
    message: 'trailing whitespace.',
    sha256: '1c05c68c34f9708415aada51f17e1b0092d2cea709bf4a94cd38114f9e73d7d9',
  ),
};

Future<void> main(List<String> arguments) async {
  if (arguments.length > 1 ||
      (arguments.isNotEmpty && !arguments.single.startsWith('--base='))) {
    stderr.writeln(
      'Usage: dart run tool/validate_diff_hygiene.dart [--base=<ref>]',
    );
    exitCode = 64;
    return;
  }
  final explicitBase = arguments.isEmpty
      ? null
      : arguments.single.substring('--base='.length);
  final base = await _resolveBase(explicitBase);
  if (base == null) {
    stderr.writeln('BLDS diff hygiene could not resolve a comparison base.');
    exitCode = 1;
    return;
  }

  final errors = <String>[];
  await _checkDiff(<String>[base, 'HEAD', '--'], errors);
  await _checkDiff(const <String>[], errors);
  if (errors.isNotEmpty) {
    stderr.writeln('BLDS diff hygiene failed:');
    for (final error in errors.toSet()) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'BLDS diff hygiene passed against $base; only exact generated, immutable '
    'baseline, and third-party license byte exceptions were allowed.',
  );
}

Future<String?> _resolveBase(String? explicitBase) async {
  final contract = File(_activeDeliveryContractPath);
  if (!contract.existsSync()) {
    return null;
  }
  final document = loadYaml(contract.readAsStringSync());
  if (document is! YamlMap || document['delivery'] is! YamlMap) {
    return null;
  }
  final expectedBase = (document['delivery'] as YamlMap)['expected_base_sha'];
  if (expectedBase is! String ||
      !RegExp(r'^[a-f0-9]{40}$').hasMatch(expectedBase)) {
    return null;
  }

  final requestedBase = explicitBase?.isNotEmpty == true
      ? explicitBase
      : (Platform.environment['BLDS_DIFF_BASE'] ?? '').isNotEmpty
      ? Platform.environment['BLDS_DIFF_BASE']
      : null;
  if (requestedBase != null) {
    final requestedCommit = await Process.run('git', <String>[
      'rev-parse',
      '--verify',
      '$requestedBase^{commit}',
    ]);
    if (requestedCommit.exitCode != 0 ||
        (requestedCommit.stdout as String).trim() != expectedBase) {
      return null;
    }
  }

  final mergeBase = await Process.run('git', <String>[
    'merge-base',
    'HEAD',
    expectedBase,
  ]);
  if (mergeBase.exitCode != 0 ||
      (mergeBase.stdout as String).trim() != expectedBase) {
    return null;
  }
  return expectedBase;
}

Future<void> _checkDiff(List<String> range, List<String> errors) async {
  final result = await Process.run('git', <String>[
    'diff',
    '--check',
    ...range,
  ]);
  final lines = const LineSplitter().convert(
    '${result.stdout}${result.stderr}',
  );
  var previousHeaderAllowed = false;
  for (final line in lines) {
    final match = RegExp(r'^(.+):(\d+): (.+)$').firstMatch(line);
    if (match == null) {
      if (line.startsWith('+') && previousHeaderAllowed) {
        continue;
      }
      if (line.trim().isNotEmpty) {
        errors.add(line);
      }
      previousHeaderAllowed = false;
      continue;
    }
    final path = match.group(1)!;
    final message = match.group(3)!;
    final exception = _exactAllowedWarnings[path];
    previousHeaderAllowed =
        exception != null &&
        exception.message == message &&
        _sha256(path) == exception.sha256;
    if (!previousHeaderAllowed) {
      errors.add(line);
    }
  }
}

String? _sha256(String path) {
  final file = File(path);
  return file.existsSync()
      ? sha256.convert(file.readAsBytesSync()).toString()
      : null;
}
