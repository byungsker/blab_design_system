import 'dart:convert';
import 'dart:io';

import 'src/agent_query.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.isEmpty) {
    stdout.writeln(
      'Usage: dart run tool/query_agent.dart --kind <kind> --id <id>',
    );
    stdout.writeln(
      'Kinds: component, token, state, accessibility, example, platform.',
    );
    if (arguments.isEmpty) exitCode = 2;
    return;
  }

  final kind = _option(arguments, '--kind');
  final id =
      _option(arguments, '--id') ?? (kind == 'accessibility' ? 'all' : null);
  if (kind == null || id == null) {
    _error('invalid-input', 'Both --kind and --id are required.');
    return;
  }

  try {
    final result = AgentQueryEngine(
      Directory.current,
    ).query(kind: kind, id: id);
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'schema': 'blab.agent-query/v1',
        'query': <String, String>{'kind': kind, 'id': id},
        'result': result,
      }),
    );
  } on AgentQueryError catch (error) {
    _error(error.code, error.message);
  } on Object catch (error) {
    _error('query-failed', error.toString());
  }
}

String? _option(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  if (index == -1 || index + 1 >= arguments.length) return null;
  final value = arguments[index + 1].trim();
  return value.isEmpty ? null : value;
}

void _error(String code, String message) {
  stderr.writeln(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schema': 'blab.agent-query-error/v1',
      'error': <String, String>{'code': code, 'message': message},
    }),
  );
  exitCode = 1;
}
