import 'dart:convert';
import 'dart:io';

import 'src/doctor.dart';
import 'src/json_schema_validation.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/validate_doctor_json.dart <doctor-json-file>',
    );
    exitCode = 64;
    return;
  }

  try {
    final schema = jsonDecode(
      File('contracts/schema/blab.doctor.schema.json').readAsStringSync(),
    );
    if (schema is! Map || schema[r'$id'] != doctorEnvelopeSchema) {
      stderr.writeln(
        'BLDS doctor JSON validation failed: unsupported schema contract.',
      );
      exitCode = 1;
      return;
    }
    final document = jsonDecode(File(arguments.single).readAsStringSync());
    final errors = <String>[
      ...validateJsonAgainstSchema(document, schema),
      ...validateDoctorEnvelope(document),
    ];
    if (errors.isNotEmpty) {
      stderr.writeln(
        'BLDS doctor JSON validation failed: ${errors.length} violation(s).',
      );
      for (final error in errors.take(20)) {
        stderr.writeln('- $error');
      }
      if (errors.length > 20) {
        stderr.writeln('- Additional violations omitted.');
      }
      exitCode = 1;
      return;
    }
    stdout.writeln('BLDS doctor JSON validation passed.');
  } on Object {
    stderr.writeln('BLDS doctor JSON validation failed: invalid JSON input.');
    exitCode = 1;
  }
}
