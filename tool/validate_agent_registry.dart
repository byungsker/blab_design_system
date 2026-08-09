import 'dart:io';

import 'src/agent_consumption.dart';

void main() {
  final errors = validateAgentRegistry(Directory.current);
  if (errors.isEmpty) {
    stdout.writeln('Agent component registry validation passed.');
    return;
  }
  stderr.writeln('Agent component registry validation failed:');
  for (final error in errors) {
    stderr.writeln('- $error');
  }
  exitCode = 1;
}
