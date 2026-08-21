import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/src/agent_query.dart';

void main() {
  late AgentQueryEngine engine;

  setUpAll(() {
    engine = AgentQueryEngine(Directory.current);
  });

  test('lists normalized and compatibility-preserved token surfaces', () {
    final tokens = engine.listTokens();
    final normalized = tokens.firstWhere(
      (token) => token['id'] == 'semantic.focus.ring',
    );
    final preserved = tokens.firstWhere(
      (token) => token['id'] == '--blab-space-5',
    );

    expect(normalized['status'], 'normalized');
    expect(preserved['status'], 'compatibility-preserved');
    expect(tokens.length, 419);
  });

  test('returns resolved values and evidence for normalized tokens', () {
    final result = engine.query(kind: 'token', id: 'semantic.focus.ring');

    expect(result['layer'], 'semantics');
    expect(result['status'], 'normalized');
    expect((result['resolved_modes'] as Map)['high-contrast-dark'], '#FFFFFF');
    expect(result['evidence'], contains('generated/token-traceability.md'));
  });

  test('exposes preserved CSS mappings without promoting them', () {
    final result = engine.query(kind: 'token', id: '--blab-space-5');

    expect(result['layer'], 'legacy-css');
    expect(result['status'], 'compatibility-preserved');
    expect(
      result['claim_boundary'],
      contains('not a normalized semantic token'),
    );
    expect(result['compatibility_source'], 'docs/design/tokens.css');
    expect(result['resolved_modes'], isNull);
  });

  test('exposes mapped Dart symbols with typed-graph resolution', () {
    final result = engine.query(kind: 'token', id: 'BLabColors.actionPrimary');

    expect(result['layer'], 'legacy-dart');
    expect(result['status'], 'compatibility-mapped');
    expect((result['resolved_modes'] as Map)['light'], '#5B7FFF');
    expect(result['compatibility_source'], 'lib/src/theme/app_colors.dart');
  });

  test('keeps missing token behavior bounded', () {
    expect(
      () => engine.query(kind: 'token', id: 'token.missing'),
      throwsA(
        isA<AgentQueryError>().having(
          (error) => error.code,
          'code',
          'not-found',
        ),
      ),
    );
  });
}
