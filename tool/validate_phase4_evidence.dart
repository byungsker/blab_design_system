import 'dart:io';

import 'src/phase4_evidence_validation.dart';

void main() {
  final errors = validatePhase4Evidence(Directory.current);
  if (errors.isNotEmpty) {
    stderr.writeln('BLDS Phase 4 evidence validation failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'BLDS Phase 4 evidence validation passed without approving visual, '
    'platform, consumer, or release conformance.',
  );
}
