import 'dart:io';

import 'src/contract_validation.dart';

void main() {
  final errors = validateBlabContract(Directory.current);
  if (errors.isNotEmpty) {
    stderr.writeln('Blab contract validation failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Blab contract validation passed.');
}
