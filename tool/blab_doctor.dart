import 'dart:io';

import 'src/doctor.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length > 1 ||
      (arguments.isNotEmpty && arguments.single != '--json')) {
    stderr.writeln('Usage: dart run tool/blab_doctor.dart [--json]');
    exitCode = 64;
    return;
  }

  final envelope = await buildDoctorEnvelope(Directory.current);
  stdout.write(
    arguments.contains('--json')
        ? renderDoctorJson(envelope)
        : renderDoctorHuman(envelope),
  );
  exitCode = doctorExitCode(envelope);
}
