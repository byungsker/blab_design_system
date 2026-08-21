import 'dart:convert';
import 'dart:io';

import 'src/agent_docs_mcp.dart';
import 'src/agent_query.dart';

Future<void> main() async {
  final server = AgentDocsMcpServer(AgentQueryEngine(Directory.current));
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    final decoded = jsonDecode(line);
    if (decoded is! Map) {
      stdout.writeln(jsonEncode(server.handle(<String, Object?>{})));
      continue;
    }
    final response = server.handle(<String, Object?>{
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    });
    if (response != null) stdout.writeln(jsonEncode(response));
  }
}
