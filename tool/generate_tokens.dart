import 'dart:io';

import 'src/token_generation.dart';

void main(List<String> arguments) {
  const allowedArguments = {'--check', '--write'};
  if (arguments.length != 1 || !allowedArguments.contains(arguments.single)) {
    stderr.writeln('Usage: dart run tool/generate_tokens.dart --check|--write');
    exitCode = 64;
    return;
  }

  final repositoryRoot = Directory.current;
  try {
    final generated = buildGeneratedTokenOutputs(repositoryRoot);
    if (arguments.single == '--write') {
      writeGeneratedTokenOutputs(repositoryRoot, generated);
      stdout.writeln(
        'Wrote ${generatedTokenPaths.length} deterministic Blab token outputs.',
      );
      return;
    }

    final drift = findGeneratedTokenDrift(repositoryRoot, generated);
    if (drift.isNotEmpty) {
      stderr.writeln('Generated Blab token drift detected:');
      for (final error in drift) {
        stderr.writeln('- $error');
      }
      exitCode = 1;
      return;
    }
    stdout.writeln('Generated Blab token check passed.');
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
