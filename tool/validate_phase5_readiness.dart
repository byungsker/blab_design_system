import 'dart:io';

import 'src/phase5_readiness_validation.dart';

void main() {
  final root = Directory.current;
  final errors = validatePhase5Readiness(root);
  final rehearsal = rehearsePhase5Migration(root);
  errors.addAll(rehearsal.errors);
  errors.sort();
  if (errors.isNotEmpty) {
    stderr.writeln('BLDS Phase 5 local-preparation validation failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'BLDS Phase 5 local preparation passed; Phase 5 exit, delivery, and '
    'publication remain blocked.',
  );
}
