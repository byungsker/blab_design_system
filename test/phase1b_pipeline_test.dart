import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import '../tool/src/contract_validation.dart';
import '../tool/src/doctor.dart';
import '../tool/src/json_schema_validation.dart';
import '../tool/src/platform_executable.dart';
import '../tool/src/public_api_snapshot.dart';
import '../tool/src/token_generation.dart';

void main() {
  test('Flutter command resolves to the Windows batch wrapper', () {
    expect(platformExecutable('flutter', windows: true), 'flutter.bat');
    expect(platformExecutable('flutter', windows: false), 'flutter');
    expect(platformExecutable('dart', windows: true), 'dart');
  });

  test('Dart SDK detection supports Windows executable names', () {
    final fixture = Directory.systemTemp.createTempSync(
      'blab-windows-dart-sdk-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));
    Directory('${fixture.path}${Platform.pathSeparator}lib').createSync();
    final executable = File(
      '${fixture.path}${Platform.pathSeparator}bin'
      '${Platform.pathSeparator}dart.exe',
    )..createSync(recursive: true);
    executable.writeAsStringSync('fixture');

    expect(isDartSdkDirectory(fixture, executableName: 'dart.exe'), isTrue);
    expect(isDartSdkDirectory(fixture, executableName: 'dart'), isFalse);
  });

  group('Phase 1B deterministic outputs', () {
    test('owns every approved local output with stable structured data', () {
      final first = buildGeneratedTokenOutputs(Directory.current);
      final second = buildGeneratedTokenOutputs(Directory.current);

      expect(second, first);
      expect(
        generatedTokenPaths,
        containsAll(<String>[
          generatedKoreanTokenDocumentationPath,
          generatedFigmaMappingPath,
          generatedComponentStateCoveragePath,
          generatedCapabilityManifestPath,
        ]),
      );

      final tokenDocumentation = first[generatedKoreanTokenDocumentationPath]!;
      expect(tokenDocumentation, contains('# Blab 토큰 참조표'));
      expect(tokenDocumentation, contains('원시 토큰'));
      expect(tokenDocumentation, contains('의미 토큰'));
      expect(tokenDocumentation, contains('컴포넌트 토큰'));

      final figma = jsonDecode(first[generatedFigmaMappingPath]!);
      expect(figma['schema'], 'blab.figma-token-mapping/v1');
      expect(figma['_generated']['remote_mutation'], isFalse);
      expect(figma['mappings'], isA<List<Object?>>());

      final capabilities = jsonDecode(first[generatedCapabilityManifestPath]!);
      expect(capabilities['schema'], 'blab.capabilities/v1');
      expect(
        capabilities['_generated']['content_checksum_sha256'],
        hasLength(64),
      );
      expect(
        capabilities['phase_status']['phase-2'],
        'implemented-local-parent-gates-required',
      );
      expect(
        capabilities['phase_status']['phase-3'],
        'all-nine-existing-component-families-implemented-local-parent-gates-required',
      );
      expect(
        capabilities['phase_status']['phase-5'],
        'local-preparation-implemented-exit-blocked',
      );
      expect(capabilities['claims']['component_state_implementation'], isFalse);
      final capabilityEntries = <String, Map<String, Object?>>{
        for (final raw in capabilities['capabilities'] as List<Object?>)
          (raw as Map<String, Object?>)['id'] as String: raw,
      };
      expect(
        capabilityEntries['accessibility-implementation-evidence']!['status'],
        'implemented-local',
      );
      expect(
        capabilityEntries['button-component-state-implementation']!['status'],
        'implemented-local-family-partial',
      );
      expect(
        capabilityEntries['button-component-state-implementation']!['phase'],
        3,
      );
      expect(
        capabilityEntries['button-component-state-implementation']!['scope'],
        <String, Object?>{
          'component_family': 'button',
          'global_capability_complete': false,
          'loading_busy_claimed': false,
          'public_type': 'BLabButton',
        },
      );
      expect(
        capabilityEntries['text-field-component-state-implementation']!['status'],
        'implemented-local-family-partial',
      );
      expect(
        capabilityEntries['text-field-component-state-implementation']!['phase'],
        3,
      );
      expect(
        capabilityEntries['text-field-component-state-implementation']!['scope'],
        <String, Object?>{
          'component_family': 'text-field',
          'global_capability_complete': false,
          'loading_claimed': false,
          'public_type': 'BLabTextField',
          'required_claimed': true,
        },
      );
      expect(
        capabilityEntries['segmented-control-component-state-implementation']!['status'],
        'implemented-local-family-partial',
      );
      expect(
        capabilityEntries['segmented-control-component-state-implementation']!['phase'],
        3,
      );
      expect(
        capabilityEntries['segmented-control-component-state-implementation']!['scope'],
        <String, Object?>{
          'component_family': 'segmented-control',
          'global_capability_complete': false,
          'public_type': 'BLabSegmentedControl',
          'required_claimed': true,
          'unsupported_claimed': false,
        },
      );
      expect(
        capabilityEntries['snackbar-component-state-implementation']!['status'],
        'implemented-local-family-partial',
      );
      expect(
        capabilityEntries['snackbar-component-state-implementation']!['phase'],
        3,
      );
      expect(
        capabilityEntries['snackbar-component-state-implementation']!['scope'],
        <String, Object?>{
          'component_family': 'snackbar',
          'global_capability_complete': false,
          'public_type': 'BLabSnackbar',
          'required_claimed': true,
          'unsupported_claimed': false,
        },
      );
      expect(
        capabilityEntries['keyboard-accessory-component-state-implementation']!['status'],
        'implemented-local-family-partial',
      );
      expect(
        capabilityEntries['keyboard-accessory-component-state-implementation']!['phase'],
        3,
      );
      expect(
        capabilityEntries['keyboard-accessory-component-state-implementation']!['scope'],
        <String, Object?>{
          'component_family': 'keyboard-accessory-bar',
          'global_capability_complete': false,
          'public_type': 'BLabKeyboardAccessoryBar',
          'required_claimed': true,
          'unsupported_claimed': false,
        },
      );
      expect(
        capabilityEntries['tab-bar-component-state-implementation']!['status'],
        'implemented-local-family-partial',
      );
      expect(
        capabilityEntries['tab-bar-component-state-implementation']!['phase'],
        3,
      );
      expect(
        capabilityEntries['tab-bar-component-state-implementation']!['scope'],
        <String, Object?>{
          'component_family': 'tab-bar',
          'disabled_claimed': false,
          'global_capability_complete': false,
          'public_type': 'BLabTabBar',
          'required_claimed': true,
          'unsupported_claimed': false,
        },
      );
      expect(
        capabilityEntries,
        isNot(contains('component-state-implementation')),
      );
      expect(capabilityEntries['visual-baseline-images']!['phase'], 4);
      expect(capabilityEntries['migration-and-release']!['phase'], 5);
      expect(
        capabilityEntries['migration-and-release']!['status'],
        'local-preparation-implemented-exit-blocked',
      );
      expect(
        capabilityEntries['migration-and-release']!['scope'],
        <String, Object?>{
          'compatibility_classifier_implemented': true,
          'conformance_claimed': false,
          'migration_rehearsal_implemented': true,
          'phase5_exit_complete': false,
          'publication_authorized': false,
          'release_authorized': false,
          'rights_preparation_implemented': true,
        },
      );

      final stateCoverage = loadYaml(
        first[generatedComponentStateCoveragePath]!,
      );
      expect(stateCoverage['schema'], 'blab.component-state-coverage/v1');
      expect(
        stateCoverage['metadata']['implementation_evidence'],
        'partial-component-families-only',
      );
      expect(
        stateCoverage['metadata']['implementation_family_scope'],
        'bottom-bar,button,card,keyboard-accessory-bar,pressable-wrapper,segmented-control,snackbar,tab-bar,text-field',
      );
      expect(stateCoverage['components'], hasLength(9));
    });

    test(
      'covers every Design-applicable state with only proven family claims',
      () {
        final source = loadYaml(
          File(
            'contracts/components/state-applicability.yaml',
          ).readAsStringSync(),
        );
        final generated = loadYaml(
          buildGeneratedTokenOutputs(
            Directory.current,
          )[generatedComponentStateCoveragePath]!,
        );

        final sourceById = <String, Map<Object?, Object?>>{
          for (final component in source['components'] as List<Object?>)
            (component as Map<Object?, Object?>)['id'] as String: component,
        };
        final generatedById = <String, Map<Object?, Object?>>{
          for (final component in generated['components'] as List<Object?>)
            (component as Map<Object?, Object?>)['id'] as String: component,
        };
        expect(generatedById.keys.toSet(), sourceById.keys.toSet());
        for (final entry in sourceById.entries) {
          final expected = <String>{
            ..._strings(entry.value['required']),
            ..._strings(entry.value['conditional']),
            ...((entry.value['required_when'] as Map<Object?, Object?>?)?.keys
                    .cast<String>() ??
                const <String>[]),
          };
          final observed = <String>{
            for (final state
                in generatedById[entry.key]!['applicable_states']
                    as List<Object?>)
              (state as Map<Object?, Object?>)['id'] as String,
          };
          expect(observed, expected, reason: entry.key);
        }

        final buttonStates = <String, Map<Object?, Object?>>{
          for (final state
              in generatedById['button']!['applicable_states'] as List<Object?>)
            (state as Map<Object?, Object?>)['id'] as String: state,
        };
        for (final state in <String>[
          'default',
          'destructive-variant',
          'disabled',
          'focus',
          'hover-pointer',
          'pressed',
        ]) {
          expect(
            buttonStates[state]!['implementation_evidence'],
            'implemented-local',
            reason: state,
          );
          expect(
            buttonStates[state]!['test_evidence'],
            'test/blab_button_test.dart',
            reason: state,
          );
          expect(
            buttonStates[state]!['documentation_evidence'],
            'docs/BLDS_PHASE_3_BUTTON_STATUS.md',
            reason: state,
          );
        }
        expect(
          buttonStates['loading-busy']!['implementation_evidence'],
          'not-claimed',
        );
        final buttonAbsence = <String, Map<Object?, Object?>>{
          for (final evidence
              in generatedById['button']!['absence_evidence'] as List<Object?>)
            (evidence as Map<Object?, Object?>)['id'] as String: evidence,
        };
        expect(
          buttonAbsence['invalid']!['status'],
          'observable-runtime-validation-absence',
        );
        expect(
          buttonAbsence['current']!['status'],
          'typed-code-inspection-only',
        );
        expect(
          buttonAbsence['loading-busy']!['status'],
          'typed-code-inspection-only',
        );

        final textFieldStates = <String, Map<Object?, Object?>>{
          for (final state
              in generatedById['text-field']!['applicable_states']
                  as List<Object?>)
            (state as Map<Object?, Object?>)['id'] as String: state,
        };
        for (final state in <String>[
          'clear-action',
          'disabled',
          'empty',
          'error-help',
          'focus',
          'hover-pointer',
          'invalid',
          'multiline',
          'obscured',
          'populated',
          'read-only',
          'required',
        ]) {
          expect(
            textFieldStates[state]!['implementation_evidence'],
            'implemented-local',
            reason: state,
          );
          expect(
            textFieldStates[state]!['test_evidence'],
            'test/blab_text_field_test.dart',
            reason: state,
          );
          expect(
            textFieldStates[state]!['documentation_evidence'],
            'docs/BLDS_PHASE_3_TEXT_FIELD_STATUS.md',
            reason: state,
          );
        }
        final textFieldAbsence = <String, Map<Object?, Object?>>{
          for (final evidence
              in generatedById['text-field']!['absence_evidence']
                  as List<Object?>)
            (evidence as Map<Object?, Object?>)['id'] as String: evidence,
        };
        expect(
          textFieldAbsence['selected']!['status'],
          'observable-runtime-semantics-absence',
        );
        expect(
          textFieldAbsence['current']!['status'],
          'typed-code-inspection-only',
        );
        expect(
          textFieldAbsence['loading']!['status'],
          'typed-code-inspection-only',
        );

        final segmentedStates = <String, Map<Object?, Object?>>{
          for (final state
              in generatedById['segmented-control']!['applicable_states']
                  as List<Object?>)
            (state as Map<Object?, Object?>)['id'] as String: state,
        };
        for (final state in <String>[
          'controlled-selection',
          'disabled-item-or-control',
          'hover-pointer',
          'keyboard-roving-focus',
          'keyboard-visible-focus',
          'pressed',
          'selected',
          'unselected',
        ]) {
          expect(
            segmentedStates[state]!['implementation_evidence'],
            'implemented-local',
            reason: state,
          );
          expect(
            segmentedStates[state]!['test_evidence'],
            'test/blab_segmented_control_test.dart',
            reason: state,
          );
          expect(
            segmentedStates[state]!['documentation_evidence'],
            'docs/BLDS_PHASE_3_SEGMENTED_CONTROL_STATUS.md',
            reason: state,
          );
        }
        expect(
          segmentedStates['scrollable-overflow']!['implementation_evidence'],
          'implemented-local',
        );
        expect(
          segmentedStates['scrollable-overflow']!['test_evidence'],
          'test/blab_segmented_control_test.dart',
        );
        expect(
          segmentedStates['scrollable-overflow']!['documentation_evidence'],
          'docs/BLDS_PHASE_3_SEGMENTED_CONTROL_SCROLLABLE_OVERFLOW_ADDENDUM.md',
        );
        final segmentedAbsence = <String, Map<Object?, Object?>>{
          for (final evidence
              in generatedById['segmented-control']!['absence_evidence']
                  as List<Object?>)
            (evidence as Map<Object?, Object?>)['id'] as String: evidence,
        };
        expect(
          segmentedAbsence['current']!['status'],
          'observable-runtime-semantics-absence',
        );
        expect(
          segmentedAbsence['haptic']!['status'],
          'typed-code-inspection-only',
        );
        final tabBarStates = <String, Map<Object?, Object?>>{
          for (final state
              in generatedById['tab-bar']!['applicable_states']
                  as List<Object?>)
            (state as Map<Object?, Object?>)['id'] as String: state,
        };
        for (final state in <String>[
          'controller-controlled-selection',
          'hover-pointer',
          'keyboard-roving-focus',
          'keyboard-visible-focus',
          'pressed',
          'selected-current',
          'unselected',
          'scrollable-overflow-when-isScrollable',
        ]) {
          expect(
            tabBarStates[state]!['implementation_evidence'],
            'implemented-local',
            reason: state,
          );
          expect(
            tabBarStates[state]!['test_evidence'],
            'test/blab_tab_bar_test.dart',
            reason: state,
          );
          expect(
            tabBarStates[state]!['documentation_evidence'],
            'docs/BLDS_PHASE_3_TAB_BAR_STATUS.md',
            reason: state,
          );
        }
        final tabBarAbsence = <String, Map<Object?, Object?>>{
          for (final evidence
              in generatedById['tab-bar']!['absence_evidence'] as List<Object?>)
            (evidence as Map<Object?, Object?>)['id'] as String: evidence,
        };
        expect(
          tabBarAbsence['disabled']!['status'],
          'typed-code-inspection-only',
        );
        expect(
          tabBarAbsence['drag-selection']!['status'],
          'observable-runtime-semantics-absence',
        );
        final snackbarStates = <String, Map<Object?, Object?>>{
          for (final state
              in generatedById['snackbar']!['applicable_states']
                  as List<Object?>)
            (state as Map<Object?, Object?>)['id'] as String: state,
        };
        for (final state in <String>[
          'entering',
          'visible',
          'exiting',
          'success',
          'error',
          'warning',
          'info',
          'live-announcement',
        ]) {
          expect(
            snackbarStates[state]!['implementation_evidence'],
            'implemented-local',
            reason: state,
          );
          expect(
            snackbarStates[state]!['test_evidence'],
            'test/blab_snackbar_test.dart',
            reason: state,
          );
          expect(
            snackbarStates[state]!['documentation_evidence'],
            'docs/BLDS_PHASE_3_SNACKBAR_STATUS.md',
            reason: state,
          );
        }
        final snackbarAbsence = <String, Map<Object?, Object?>>{
          for (final evidence
              in generatedById['snackbar']!['absence_evidence']
                  as List<Object?>)
            (evidence as Map<Object?, Object?>)['id'] as String: evidence,
        };
        expect(
          snackbarAbsence['selected']!['status'],
          'observable-runtime-semantics-absence',
        );
        expect(
          snackbarAbsence['loading']!['status'],
          'typed-code-inspection-only',
        );
        final keyboardStates = <String, Map<Object?, Object?>>{
          for (final state
              in generatedById['keyboard-accessory-bar']!['applicable_states']
                  as List<Object?>)
            (state as Map<Object?, Object?>)['id'] as String: state,
        };
        for (final state in <String>[
          'default',
          'hover-pointer',
          'pressed',
          'focus',
          'disabled-per-action',
          'repeated-action-active-for-undo-redo',
          'scrollable-overflow',
        ]) {
          expect(
            keyboardStates[state]!['implementation_evidence'],
            'implemented-local',
            reason: state,
          );
          expect(
            keyboardStates[state]!['test_evidence'],
            'test/blab_keyboard_accessory_bar_test.dart',
            reason: state,
          );
          expect(
            keyboardStates[state]!['documentation_evidence'],
            'docs/BLDS_PHASE_3_KEYBOARD_ACCESSORY_STATUS.md',
            reason: state,
          );
        }
        final keyboardAbsence = <String, Map<Object?, Object?>>{
          for (final evidence
              in generatedById['keyboard-accessory-bar']!['absence_evidence']
                  as List<Object?>)
            (evidence as Map<Object?, Object?>)['id'] as String: evidence,
        };
        expect(
          keyboardAbsence['selected']!['status'],
          'observable-runtime-semantics-absence',
        );
        expect(
          keyboardAbsence['loading']!['status'],
          'typed-code-inspection-only',
        );
        for (final entry in generatedById.entries.where(
          (entry) => !<String>{
            'bottom-bar',
            'button',
            'card',
            'keyboard-accessory-bar',
            'pressable-wrapper',
            'segmented-control',
            'snackbar',
            'tab-bar',
            'text-field',
          }.contains(entry.key),
        )) {
          for (final rawState
              in entry.value['applicable_states'] as List<Object?>) {
            final state = rawState as Map<Object?, Object?>;
            expect(
              state['implementation_evidence'],
              'not-claimed',
              reason: '${entry.key}/${state['id']}',
            );
          }
        }
      },
    );

    test('manual drift in each new output is rejected', () {
      final expected = buildGeneratedTokenOutputs(Directory.current);
      for (final path in <String>[
        generatedKoreanTokenDocumentationPath,
        generatedFigmaMappingPath,
        generatedComponentStateCoveragePath,
        generatedCapabilityManifestPath,
      ]) {
        final fixture = Directory.systemTemp.createTempSync(
          'blab-phase1b-drift-',
        );
        addTearDown(() => fixture.deleteSync(recursive: true));
        writeGeneratedTokenOutputs(fixture, expected);
        File(
          '${fixture.path}/$path',
        ).writeAsStringSync('\ndeliberate mutation\n', mode: FileMode.append);
        expect(
          findGeneratedTokenDrift(fixture, expected),
          contains('$path differs from deterministic generation'),
        );
      }
    });

    test('new output symlinks are rejected before any replacement', () {
      final expected = buildGeneratedTokenOutputs(Directory.current);
      final fixture = Directory.systemTemp.createTempSync(
        'blab-phase1b-symlink-',
      );
      final outside = Directory.systemTemp.createTempSync(
        'blab-phase1b-outside-',
      );
      addTearDown(() => fixture.deleteSync(recursive: true));
      addTearDown(() => outside.deleteSync(recursive: true));
      final sentinel = File('${outside.path}/sentinel.json')
        ..writeAsStringSync('outside-sentinel');
      final link = Link('${fixture.path}/$generatedCapabilityManifestPath');
      link.parent.createSync(recursive: true);
      link.createSync(sentinel.path);

      expect(
        () => writeGeneratedTokenOutputs(fixture, expected),
        throwsA(isA<StateError>()),
      );
      expect(sentinel.readAsStringSync(), 'outside-sentinel');
      expect(
        File('${fixture.path}/$generatedTokenDataPath').existsSync(),
        isFalse,
      );
    });
  });

  group('Phase 1B contract validation', () {
    test(
      'locks bounded Phase 2 evidence and canonical capability phase routing',
      () {
        final contract = loadYaml(
          File('contracts/blab.design.yaml').readAsStringSync(),
        );
        expect(
          contract['accessibility']['implementation_evidence'],
          'implemented-local-parent-gates-required',
        );
        expect(validateBlabContract(Directory.current), isEmpty);

        final evidenceFixture = _copyCurrentFixture();
        addTearDown(() => evidenceFixture.deleteSync(recursive: true));
        final evidenceContract = File(
          '${evidenceFixture.path}/contracts/blab.design.yaml',
        );
        evidenceContract.writeAsStringSync(
          evidenceContract.readAsStringSync().replaceFirst(
            'implementation_evidence: '
                '"implemented-local-parent-gates-required"',
            'implementation_evidence: "not-yet-established"',
          ),
        );
        expect(
          validateBlabContract(evidenceFixture),
          contains(
            'accessibility.implementation_evidence must match '
            'capabilities.phase_status.phase-2 '
            '(implemented-local-parent-gates-required), but was '
            'not-yet-established.',
          ),
        );

        final phaseFixture = _copyCurrentFixture();
        addTearDown(() => phaseFixture.deleteSync(recursive: true));
        final phaseContract = File(
          '${phaseFixture.path}/contracts/blab.design.yaml',
        );
        phaseContract.writeAsStringSync(
          phaseContract.readAsStringSync().replaceFirst(
            '- id: "button-component-state-implementation"\n'
                '      phase: 3',
            '- id: "button-component-state-implementation"\n'
                '      phase: 2',
          ),
        );
        expect(
          validateBlabContract(phaseFixture),
          contains(
            'Capability button-component-state-implementation must be routed to '
            'Phase 3, but was Phase 2.',
          ),
        );

        final textFieldPhaseFixture = _copyCurrentFixture();
        addTearDown(() => textFieldPhaseFixture.deleteSync(recursive: true));
        final textFieldPhaseContract = File(
          '${textFieldPhaseFixture.path}/contracts/blab.design.yaml',
        );
        textFieldPhaseContract.writeAsStringSync(
          textFieldPhaseContract.readAsStringSync().replaceFirst(
            '- id: "text-field-component-state-implementation"\n'
                '      phase: 3',
            '- id: "text-field-component-state-implementation"\n'
                '      phase: 2',
          ),
        );
        expect(
          validateBlabContract(textFieldPhaseFixture),
          contains(
            'Capability text-field-component-state-implementation must be '
            'routed to Phase 3, but was Phase 2.',
          ),
        );

        final segmentedPhaseFixture = _copyCurrentFixture();
        addTearDown(() => segmentedPhaseFixture.deleteSync(recursive: true));
        final segmentedPhaseContract = File(
          '${segmentedPhaseFixture.path}/contracts/blab.design.yaml',
        );
        segmentedPhaseContract.writeAsStringSync(
          segmentedPhaseContract.readAsStringSync().replaceFirst(
            '- id: "segmented-control-component-state-implementation"\n'
                '      phase: 3',
            '- id: "segmented-control-component-state-implementation"\n'
                '      phase: 2',
          ),
        );
        expect(
          validateBlabContract(segmentedPhaseFixture),
          contains(
            'Capability segmented-control-component-state-implementation '
            'must be routed to Phase 3, but was Phase 2.',
          ),
        );

        final tabBarPhaseFixture = _copyCurrentFixture();
        addTearDown(() => tabBarPhaseFixture.deleteSync(recursive: true));
        final tabBarPhaseContract = File(
          '${tabBarPhaseFixture.path}/contracts/blab.design.yaml',
        );
        tabBarPhaseContract.writeAsStringSync(
          tabBarPhaseContract.readAsStringSync().replaceFirst(
            '- id: "tab-bar-component-state-implementation"\n'
                '      phase: 3',
            '- id: "tab-bar-component-state-implementation"\n'
                '      phase: 2',
          ),
        );
        expect(
          validateBlabContract(tabBarPhaseFixture),
          contains(
            'Capability tab-bar-component-state-implementation must be routed '
            'to Phase 3, but was Phase 2.',
          ),
        );
      },
    );

    test('retains immutable Phase 0 history and validates current Button', () {
      final contract =
          loadYaml(File('contracts/blab.design.yaml').readAsStringSync())
              as YamlMap;
      final manifest = (contract['values']['reference_manifest'] as YamlList)
          .cast<YamlMap>();
      final button = manifest.singleWhere(
        (entry) => entry['path'] == 'lib/src/widgets/liquid_glass_button.dart',
      );
      expect(
        button['historical_sha256'],
        '27400bff8776551ca6803dd799bf12d83020320b33979d30649fc61fad88bf4f',
      );
      final current = button['current'] as YamlMap;
      expect(current['phase'], 3);
      expect(
        current['evidence'],
        contains('docs/BLDS_PHASE_3_BUTTON_STATUS.md'),
      );
      expect(
        current['sha256'],
        sha256
            .convert(
              File(
                'lib/src/widgets/liquid_glass_button.dart',
              ).readAsBytesSync(),
            )
            .toString(),
      );
      expect(validateBlabContract(Directory.current), isEmpty);

      final historyFixture = _copyCurrentFixture();
      addTearDown(() => historyFixture.deleteSync(recursive: true));
      final historyContract = File(
        '${historyFixture.path}/contracts/blab.design.yaml',
      );
      historyContract.writeAsStringSync(
        historyContract.readAsStringSync().replaceFirst(
          '27400bff8776551ca6803dd799bf12d83020320b33979d30649fc61fad88bf4f',
          '0000000000000000000000000000000000000000000000000000000000000000',
        ),
      );
      expect(
        validateBlabContract(historyFixture),
        contains(
          contains(
            'Immutable Phase 0 digest for '
            'lib/src/widgets/liquid_glass_button.dart must remain '
            '27400bff8776551ca6803dd799bf12d83020320b33979d30649fc61fad88bf4f',
          ),
        ),
      );

      final currentFixture = _copyCurrentFixture();
      addTearDown(() => currentFixture.deleteSync(recursive: true));
      final currentContract = File(
        '${currentFixture.path}/contracts/blab.design.yaml',
      );
      currentContract.writeAsStringSync(
        currentContract.readAsStringSync().replaceFirst(
          current['sha256'] as String,
          '0000000000000000000000000000000000000000000000000000000000000000',
        ),
      );
      expect(
        validateBlabContract(currentFixture),
        contains(
          contains(
            'Current reference drift for '
            'lib/src/widgets/liquid_glass_button.dart',
          ),
        ),
      );
    });

    test(
      'retains immutable Phase 0 history and validates current TextField',
      () {
        final contract =
            loadYaml(File('contracts/blab.design.yaml').readAsStringSync())
                as YamlMap;
        final manifest = (contract['values']['reference_manifest'] as YamlList)
            .cast<YamlMap>();
        final textField = manifest.singleWhere(
          (entry) =>
              entry['path'] == 'lib/src/widgets/liquid_glass_text_field.dart',
        );
        expect(
          textField['historical_sha256'],
          '6f7775e19887d9e227d21a01278d2fae3feea662cc8cbb94c2a822b8dcc6948f',
        );
        final current = textField['current'] as YamlMap;
        expect(current['phase'], 3);
        expect(
          current['evidence'],
          contains('docs/BLDS_PHASE_3_TEXT_FIELD_STATUS.md'),
        );
        expect(
          current['sha256'],
          sha256
              .convert(
                File(
                  'lib/src/widgets/liquid_glass_text_field.dart',
                ).readAsBytesSync(),
              )
              .toString(),
        );
        expect(validateBlabContract(Directory.current), isEmpty);

        final historyFixture = _copyCurrentFixture();
        addTearDown(() => historyFixture.deleteSync(recursive: true));
        final historyContract = File(
          '${historyFixture.path}/contracts/blab.design.yaml',
        );
        historyContract.writeAsStringSync(
          historyContract.readAsStringSync().replaceFirst(
            '6f7775e19887d9e227d21a01278d2fae3feea662cc8cbb94c2a822b8dcc6948f',
            '0000000000000000000000000000000000000000000000000000000000000000',
          ),
        );
        expect(
          validateBlabContract(historyFixture),
          contains(
            contains(
              'Immutable Phase 0 digest for '
              'lib/src/widgets/liquid_glass_text_field.dart must remain '
              '6f7775e19887d9e227d21a01278d2fae3feea662cc8cbb94c2a822b8dcc6948f',
            ),
          ),
        );

        final currentFixture = _copyCurrentFixture();
        addTearDown(() => currentFixture.deleteSync(recursive: true));
        final currentContract = File(
          '${currentFixture.path}/contracts/blab.design.yaml',
        );
        currentContract.writeAsStringSync(
          currentContract.readAsStringSync().replaceFirst(
            current['sha256'] as String,
            '0000000000000000000000000000000000000000000000000000000000000000',
          ),
        );
        expect(
          validateBlabContract(currentFixture),
          contains(
            contains(
              'Current reference drift for '
              'lib/src/widgets/liquid_glass_text_field.dart',
            ),
          ),
        );
      },
    );

    test(
      'retains immutable Phase 0 history and validates current SegmentedControl',
      () {
        final contract =
            loadYaml(File('contracts/blab.design.yaml').readAsStringSync())
                as YamlMap;
        final manifest = (contract['values']['reference_manifest'] as YamlList)
            .cast<YamlMap>();
        final segmented = manifest.singleWhere(
          (entry) =>
              entry['path'] == 'lib/src/widgets/blab_segmented_control.dart',
        );
        expect(
          segmented['historical_sha256'],
          'd3fa831d6cf4764130cd4f1430f134f7db840b0dbd1816a067ca7a776cf97628',
        );
        final current = segmented['current'] as YamlMap;
        expect(current['phase'], 3);
        expect(
          current['evidence'],
          contains('docs/BLDS_PHASE_3_SEGMENTED_CONTROL_STATUS.md'),
        );
        expect(
          current['sha256'],
          sha256
              .convert(
                File(
                  'lib/src/widgets/blab_segmented_control.dart',
                ).readAsBytesSync(),
              )
              .toString(),
        );
        expect(validateBlabContract(Directory.current), isEmpty);

        final historyFixture = _copyCurrentFixture();
        addTearDown(() => historyFixture.deleteSync(recursive: true));
        final historyContract = File(
          '${historyFixture.path}/contracts/blab.design.yaml',
        );
        historyContract.writeAsStringSync(
          historyContract.readAsStringSync().replaceFirst(
            'd3fa831d6cf4764130cd4f1430f134f7db840b0dbd1816a067ca7a776cf97628',
            '0000000000000000000000000000000000000000000000000000000000000000',
          ),
        );
        expect(
          validateBlabContract(historyFixture),
          contains(
            contains(
              'Immutable Phase 0 digest for '
              'lib/src/widgets/blab_segmented_control.dart must remain '
              'd3fa831d6cf4764130cd4f1430f134f7db840b0dbd1816a067ca7a776cf97628',
            ),
          ),
        );

        final currentFixture = _copyCurrentFixture();
        addTearDown(() => currentFixture.deleteSync(recursive: true));
        final currentContract = File(
          '${currentFixture.path}/contracts/blab.design.yaml',
        );
        currentContract.writeAsStringSync(
          currentContract.readAsStringSync().replaceFirst(
            current['sha256'] as String,
            '0000000000000000000000000000000000000000000000000000000000000000',
          ),
        );
        expect(
          validateBlabContract(currentFixture),
          contains(
            contains(
              'Current reference drift for '
              'lib/src/widgets/blab_segmented_control.dart',
            ),
          ),
        );
      },
    );

    test('retains immutable Phase 0 history and validates current TabBar', () {
      final contract =
          loadYaml(File('contracts/blab.design.yaml').readAsStringSync())
              as YamlMap;
      final manifest = (contract['values']['reference_manifest'] as YamlList)
          .cast<YamlMap>();
      final tabBar = manifest.singleWhere(
        (entry) => entry['path'] == 'lib/src/widgets/liquid_glass_tab_bar.dart',
      );
      expect(
        tabBar['historical_sha256'],
        '6120a861479ca1db44eb1fd14680a48ab046652e4f63bfc262c157a0176d8bc3',
      );
      final current = tabBar['current'] as YamlMap;
      expect(current['phase'], 3);
      expect(
        current['evidence'],
        contains('docs/BLDS_PHASE_3_TAB_BAR_STATUS.md'),
      );
      expect(
        current['sha256'],
        sha256
            .convert(
              File(
                'lib/src/widgets/liquid_glass_tab_bar.dart',
              ).readAsBytesSync(),
            )
            .toString(),
      );
      expect(validateBlabContract(Directory.current), isEmpty);

      final historyFixture = _copyCurrentFixture();
      addTearDown(() => historyFixture.deleteSync(recursive: true));
      final historyContract = File(
        '${historyFixture.path}/contracts/blab.design.yaml',
      );
      historyContract.writeAsStringSync(
        historyContract.readAsStringSync().replaceFirst(
          '6120a861479ca1db44eb1fd14680a48ab046652e4f63bfc262c157a0176d8bc3',
          '0000000000000000000000000000000000000000000000000000000000000000',
        ),
      );
      expect(
        validateBlabContract(historyFixture),
        contains(
          contains(
            'Immutable Phase 0 digest for '
            'lib/src/widgets/liquid_glass_tab_bar.dart must remain '
            '6120a861479ca1db44eb1fd14680a48ab046652e4f63bfc262c157a0176d8bc3',
          ),
        ),
      );

      final currentFixture = _copyCurrentFixture();
      addTearDown(() => currentFixture.deleteSync(recursive: true));
      final currentContract = File(
        '${currentFixture.path}/contracts/blab.design.yaml',
      );
      currentContract.writeAsStringSync(
        currentContract.readAsStringSync().replaceFirst(
          current['sha256'] as String,
          '0000000000000000000000000000000000000000000000000000000000000000',
        ),
      );
      expect(
        validateBlabContract(currentFixture),
        contains(
          contains(
            'Current reference drift for '
            'lib/src/widgets/liquid_glass_tab_bar.dart',
          ),
        ),
      );
    });

    test('rejects malformed state, baseline, and glossary manifests', () {
      final cases = <String, String>{
        'contracts/components/state-applicability.yaml': 'schema: [',
        'contracts/visual-baselines.yaml': 'schema: [',
        'contracts/glossary/blab.terms.yaml': 'schema: [',
      };
      for (final entry in cases.entries) {
        final fixture = _copyCurrentFixture();
        addTearDown(() => fixture.deleteSync(recursive: true));
        File('${fixture.path}/${entry.key}').writeAsStringSync(entry.value);
        expect(validateBlabContract(fixture), isNotEmpty, reason: entry.key);
      }
    });

    test('rejects duplicate component, state, and capability ids', () {
      final componentFixture = _copyCurrentFixture();
      addTearDown(() => componentFixture.deleteSync(recursive: true));
      final stateFile = File(
        '${componentFixture.path}/contracts/components/'
        'state-applicability.yaml',
      );
      stateFile.writeAsStringSync(
        stateFile.readAsStringSync().replaceFirst(
          '  - id: "text-field"',
          '  - id: "button"',
        ),
      );
      expect(
        validateBlabContract(componentFixture),
        contains(
          'Duplicate id in contracts/components/state-applicability.yaml '
          'components: button',
        ),
      );

      final stateFixture = _copyCurrentFixture();
      addTearDown(() => stateFixture.deleteSync(recursive: true));
      final duplicateStateFile = File(
        '${stateFixture.path}/contracts/components/state-applicability.yaml',
      );
      duplicateStateFile.writeAsStringSync(
        duplicateStateFile.readAsStringSync().replaceFirst(
          '"default", "hover-pointer"',
          '"default", "default", "hover-pointer"',
        ),
      );
      expect(
        validateBlabContract(stateFixture),
        contains('Duplicate required state for button: default'),
      );

      final capabilityFixture = _copyCurrentFixture();
      addTearDown(() => capabilityFixture.deleteSync(recursive: true));
      final contract = File(
        '${capabilityFixture.path}/contracts/blab.design.yaml',
      );
      contract.writeAsStringSync(
        contract.readAsStringSync().replaceFirst(
          '  - id: "offline-doctor"',
          '  - id: "deterministic-contract-generation"',
        ),
      );
      expect(
        validateBlabContract(capabilityFixture),
        contains(
          'Duplicate id in contracts/blab.design.yaml capabilities: '
          'deterministic-contract-generation',
        ),
      );
    });
  });

  group('BLDS doctor', () {
    test(
      'returns a stable typed envelope and deterministic renderings',
      () async {
        final first = await buildDoctorEnvelope(Directory.current);
        final second = await buildDoctorEnvelope(Directory.current);

        expect(first.toJson(), second.toJson());
        expect(validateDoctorEnvelope(first.toJson()), isEmpty);
        expect(renderDoctorJson(first), renderDoctorJson(second));
        expect(renderDoctorHuman(first), renderDoctorHuman(second));
        expect(first.result, isNotNull);
        expect(first.error, isNull);
        expect(first.result!.checks, isNotEmpty);
        expect(
          first.result!.checks.map((check) => check.id).toList(),
          orderedEquals(
            first.result!.checks.map((check) => check.id).toList()..sort(),
          ),
        );
        expect(
          first.result!.checks.map((check) => check.severity).toSet(),
          containsAll(<DoctorSeverity>[
            DoctorSeverity.pass,
            DoctorSeverity.warning,
            DoctorSeverity.information,
          ]),
        );
        expect(doctorExitCode(first), 0);
      },
    );

    test('rejects invalid classifications and malformed envelopes', () {
      final malformed = <String, Object?>{
        'schema': doctorEnvelopeSchema,
        'tool_version': doctorToolVersion,
        'ok': true,
        'result': <String, Object?>{
          'schema': doctorReportSchema,
          'status': 'unknown',
          'exit_code': 0,
          'summary': <String, Object?>{},
          'checks': <Object?>[
            <String, Object?>{
              'id': 'invalid',
              'severity': 'conformant',
              'message': 'invalid',
            },
          ],
        },
        'error': null,
      };
      final errors = validateDoctorEnvelope(malformed);
      expect(errors, contains('Doctor status is invalid.'));
      expect(errors, contains('Doctor check severity is invalid.'));
      expect(
        validateDoctorEnvelope(<String, Object?>{
          'schema': doctorEnvelopeSchema,
          'tool_version': doctorToolVersion,
          'ok': false,
          'result': <String, Object?>{},
          'error': <String, Object?>{},
        }),
        contains('Doctor envelope must contain exactly one result or error.'),
      );
    });

    test('schema validator rejects every contracted malformed shape', () {
      final schema = jsonDecode(
        File('contracts/schema/blab.doctor.schema.json').readAsStringSync(),
      );
      final valid = DoctorEnvelope.success(
        DoctorReport(
          checks: const <DoctorCheck>[
            DoctorCheck(
              id: 'schema-check',
              severity: DoctorSeverity.pass,
              message: 'Schema check passed.',
            ),
          ],
        ),
      ).toJson();

      Map<String, Object?> clone() =>
          jsonDecode(jsonEncode(valid)) as Map<String, Object?>;

      final cases = <String, Map<String, Object?>>{
        'top-level additional property': clone()
          ..['unexpected_secret'] = 'synthetic',
        'result additional property': clone()
          ..update(
            'result',
            (value) => (value! as Map<String, Object?>)..['extra'] = true,
          ),
        'summary additional property': clone()
          ..update('result', (value) {
            final result = value! as Map<String, Object?>;
            (result['summary']! as Map<String, Object?>)['extra'] = 0;
            return result;
          }),
        'check additional property': clone()
          ..update('result', (value) {
            final result = value! as Map<String, Object?>;
            final checks = result['checks']! as List<Object?>;
            (checks.single! as Map<String, Object?>)['extra'] = true;
            return result;
          }),
        'error additional property': <String, Object?>{
          'schema': doctorEnvelopeSchema,
          'tool_version': doctorToolVersion,
          'ok': false,
          'result': null,
          'error': <String, Object?>{
            'code': 'doctor-error',
            'message': 'Doctor failed safely.',
            'extra': true,
          },
        },
        'missing required field': clone()..remove('tool_version'),
        'wrong nested type': clone()
          ..update('result', (value) {
            final result = value! as Map<String, Object?>;
            (result['summary']! as Map<String, Object?>)['pass'] = '1';
            return result;
          }),
        'invalid nested enum': clone()
          ..update('result', (value) {
            final result = value! as Map<String, Object?>;
            final checks = result['checks']! as List<Object?>;
            (checks.single! as Map<String, Object?>)['severity'] = 'unknown';
            return result;
          }),
        'invalid nested pattern': clone()
          ..update('result', (value) {
            final result = value! as Map<String, Object?>;
            final checks = result['checks']! as List<Object?>;
            (checks.single! as Map<String, Object?>)['id'] = 'Invalid Id';
            return result;
          }),
        'invalid nested minimum': clone()
          ..update('result', (value) {
            final result = value! as Map<String, Object?>;
            (result['summary']! as Map<String, Object?>)['pass'] = -1;
            return result;
          }),
        'invalid one-of shape': clone()..['result'] = 42,
      };

      expect(validateJsonAgainstSchema(valid, schema), isEmpty);
      for (final entry in cases.entries) {
        expect(
          validateJsonAgainstSchema(entry.value, schema),
          isNotEmpty,
          reason: entry.key,
        );
      }
      expect(
        () => validateJsonAgainstSchema(valid, <String, Object?>{
          'type': 'object',
          'unevaluatedProperties': false,
        }),
        throwsFormatException,
      );
    });

    test(
      'failure classification and exit code are stable under drift',
      () async {
        final fixture = _copyCurrentFixture(
          includeGenerated: true,
          includeApi: true,
        );
        addTearDown(() => fixture.deleteSync(recursive: true));
        File(
          '${fixture.path}/$generatedFigmaMappingPath',
        ).writeAsStringSync('deliberate drift');

        final first = await buildDoctorEnvelope(fixture);
        final second = await buildDoctorEnvelope(fixture);
        expect(first.toJson(), second.toJson());
        expect(first.result!.status, DoctorStatus.failure);
        expect(doctorExitCode(first), 1);
        expect(
          first.result!.checks
              .singleWhere((check) => check.id == 'generation-drift')
              .severity,
          DoctorSeverity.failure,
        );
        for (final output in <String>[
          renderDoctorJson(first),
          renderDoctorHuman(first),
        ]) {
          expect(output, isNot(contains(generatedFigmaMappingPath)));
        }
      },
    );

    test(
      'detects checked-in API snapshot body drift without analyzer work',
      () async {
        final fixture = _copyCurrentFixture(
          includeGenerated: true,
          includeApi: true,
        );
        addTearDown(() => fixture.deleteSync(recursive: true));
        File(
          '${fixture.path}/api/blab_design_system.api.txt',
        ).writeAsStringSync(
          '\ndeliberate API snapshot drift\n',
          mode: FileMode.append,
        );

        final envelope = await buildDoctorEnvelope(fixture);
        expect(
          envelope.result!.checks
              .singleWhere((check) => check.id == 'api-snapshot')
              .severity,
          DoctorSeverity.failure,
        );
        expect(doctorExitCode(envelope), 1);
      },
    );

    test('output is redacted and makes no conformance claim', () async {
      final envelope = await buildDoctorEnvelope(Directory.current);
      final outputs = <String>[
        renderDoctorJson(envelope),
        renderDoctorHuman(envelope),
      ];
      for (final output in outputs) {
        expect(output, isNot(contains(Directory.current.absolute.path)));
        expect(output, isNot(contains('/Users/')));
        expect(output, isNot(contains(r'C:\Users\')));
        expect(output.toLowerCase(), isNot(contains('telemetry')));
        expect(output.toLowerCase(), isNot(contains('credential')));
        expect(output.toLowerCase(), isNot(contains('customer data')));
        expect(output.toLowerCase(), isNot(contains('environment secret')));
        expect(output.toLowerCase(), isNot(contains('conformant')));
        expect(output.toLowerCase(), isNot(contains('conformance passed')));
      }
    });

    test(
      'malformed contract values never appear in human or JSON output',
      () async {
        final cases = <({String path, String before, String after})>[
          (
            path: 'contracts/tokens/blab.tokens.yaml',
            before: 'value: "#000000"',
            after: 'value: "credential-fixture-value"',
          ),
          (
            path: 'contracts/blab.design.yaml',
            before: 'status: "approved"',
            after:
                'status: "customer-record-fixture '
                '/private/fixture/absolute/path"',
          ),
          (
            path: 'contracts/blab.design.yaml',
            before: 'status: "implemented-local"',
            after: 'status: "environment-secret-fixture"',
          ),
        ];
        const protectedValues = <String>[
          'credential-fixture-value',
          'customer-record-fixture',
          '/private/fixture/absolute/path',
          'environment-secret-fixture',
        ];

        for (final mutation in cases) {
          final fixture = _copyCurrentFixture(
            includeGenerated: true,
            includeApi: true,
          );
          addTearDown(() => fixture.deleteSync(recursive: true));
          final file = File('${fixture.path}/${mutation.path}');
          final source = file.readAsStringSync();
          expect(source, contains(mutation.before));
          file.writeAsStringSync(
            source.replaceFirst(mutation.before, mutation.after),
          );

          final envelope = await buildDoctorEnvelope(fixture);
          expect(doctorExitCode(envelope), 1);
          final contractCheck = envelope.result!.checks.singleWhere(
            (check) => check.id == 'contract-validation',
          );
          expect(contractCheck.severity, DoctorSeverity.failure);
          expect(
            contractCheck.message,
            matches(RegExp(r'^\d+ contract validation error\(s\) found\.$')),
          );
          for (final output in <String>[
            renderDoctorJson(envelope),
            renderDoctorHuman(envelope),
          ]) {
            for (final protectedValue in protectedValues) {
              expect(output, isNot(contains(protectedValue)));
            }
            expect(output, isNot(contains(fixture.absolute.path)));
          }
        }
      },
    );
  });
}

List<String> _strings(Object? value) =>
    (value as List<Object?>?)?.cast<String>() ?? const <String>[];

Directory _copyCurrentFixture({
  bool includeGenerated = false,
  bool includeApi = false,
}) {
  final fixture = Directory.systemTemp.createTempSync('blab-phase1b-current-');
  for (final path in <String>[
    'contracts',
    'docs',
    'lib',
    'tool',
    if (includeGenerated) 'generated',
    if (includeApi) 'api',
  ]) {
    _copyDirectory(Directory(path), Directory('${fixture.path}/$path'));
  }
  File('LICENSE').copySync('${fixture.path}/LICENSE');
  File('DESIGN.md').copySync('${fixture.path}/DESIGN.md');
  File('pubspec.yaml').copySync('${fixture.path}/pubspec.yaml');
  return fixture;
}

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final name = entity.uri.pathSegments.where((part) => part.isNotEmpty).last;
    final target = '${destination.path}/$name';
    if (entity is Directory) {
      _copyDirectory(entity, Directory(target));
    } else if (entity is File) {
      entity.copySync(target);
    }
  }
}
