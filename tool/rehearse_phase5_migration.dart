import 'dart:io';

import 'src/phase5_readiness_validation.dart';

void main() {
  final result = rehearsePhase5Migration(Directory.current);
  if (!result.passes) {
    stderr.writeln('BLDS Phase 5 migration/rollback rehearsal failed:');
    for (final error in result.errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'BLDS Phase 5 approved compatibility-correction and repository-artifact '
    'rollback rehearsal passed in a disposable copy; no consumer source was '
    'accessed or mutated.',
  );
}
