import 'dart:convert';
import 'dart:io';

import 'src/phase5_compatibility.dart';

void main(List<String> arguments) {
  if (arguments.isNotEmpty &&
      !(arguments.length == 1 && arguments.single == '--json')) {
    stderr.writeln('Usage: dart run tool/classify_compatibility.dart [--json]');
    exitCode = 64;
    return;
  }
  try {
    final report = classifyRepositoryCompatibility(Directory.current);
    if (arguments.contains('--json')) {
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(report.toJson()),
      );
    } else {
      stdout.writeln(
        'BLDS compatibility: '
        '${report.classifications['additive']} additive, '
        'deprecated detection '
        '${report.classificationSupport['deprecated']}, '
        '${report.classifications['breaking']} breaking.',
      );
      for (final violation in report.violations) {
        stderr.writeln('- $violation');
      }
    }
    if (!report.passes) exitCode = 1;
  } on Object catch (error) {
    stderr.writeln('BLDS compatibility classification failed: $error');
    exitCode = 1;
  }
}
