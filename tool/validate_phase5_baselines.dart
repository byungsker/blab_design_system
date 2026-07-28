import 'dart:io';

import 'src/phase5_baseline_validation.dart';

Future<void> main() async {
  final errors = await validatePhase5Baselines(Directory.current);
  if (errors.isNotEmpty) {
    stderr.writeln('BLDS Phase 5 baseline trust validation failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'BLDS Phase 5 baselines match origin.commit Git objects and the API '
    'baseline is reproducible.',
  );
}
