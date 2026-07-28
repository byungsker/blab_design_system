import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'src/phase5_inventory_scope.dart';
import 'src/platform_executable.dart';

const _dependencySnapshotPath = 'contracts/sbom/dependencies.json';
const _spdxPath = 'contracts/sbom/blab-design-system.spdx.json';
const _cycloneDxPath = 'contracts/sbom/blab-design-system.cdx.json';
const _originMapPath = 'contracts/legal/file-origin-map.yaml';

Future<void> main(List<String> arguments) async {
  const allowed = {'--write', '--check'};
  if (arguments.length != 1 || !allowed.contains(arguments.single)) {
    stderr.writeln(
      'Usage: dart run tool/generate_phase5_inventories.dart '
      '--write|--check',
    );
    exitCode = 64;
    return;
  }
  final root = Directory.current;
  if (arguments.single == '--write') {
    final result = await Process.run(platformExecutable('flutter'), const [
      'pub',
      'deps',
      '--json',
    ], workingDirectory: root.path);
    if (result.exitCode != 0) {
      stderr.write(result.stderr);
      exitCode = 1;
      return;
    }
    final dependencySnapshot = _canonicalDependencySnapshot(
      jsonDecode(result.stdout as String),
    );
    _writeJson(root, _dependencySnapshotPath, dependencySnapshot);
  }
  final snapshotFile = File('${root.path}/$_dependencySnapshotPath');
  if (!snapshotFile.existsSync()) {
    stderr.writeln('Missing $_dependencySnapshotPath.');
    exitCode = 1;
    return;
  }
  final dependencySnapshot = jsonDecode(snapshotFile.readAsStringSync());
  final expected = <String, String>{
    _spdxPath: _pretty(_buildSpdx(dependencySnapshot)),
    _cycloneDxPath: _pretty(_buildCycloneDx(dependencySnapshot)),
    _originMapPath: _pretty(_buildOriginMap(root)),
  };
  if (arguments.single == '--write') {
    for (final entry in expected.entries.where(
      (entry) => entry.key != _originMapPath,
    )) {
      _write(root, entry.key, entry.value);
    }
    _write(root, _originMapPath, _pretty(_buildOriginMap(root)));
    stdout.writeln('Wrote Phase 5 provenance and SBOM inventories.');
    return;
  }
  final drift = <String>[];
  for (final entry in expected.entries) {
    final file = File('${root.path}/${entry.key}');
    if (!file.existsSync() || file.readAsStringSync() != entry.value) {
      drift.add(entry.key);
    }
  }
  if (drift.isNotEmpty) {
    stderr.writeln('Phase 5 inventory drift: ${drift.join(', ')}.');
    exitCode = 1;
    return;
  }
  stdout.writeln('Phase 5 provenance and SBOM inventory drift check passed.');
}

Map<String, Object?> _canonicalDependencySnapshot(Object? raw) {
  final document = _stringMap(raw);
  final rawPackages = document['packages'];
  if (rawPackages is! List) {
    throw const FormatException('flutter pub deps JSON has no packages.');
  }
  final packages =
      rawPackages
          .map(_stringMap)
          .map(
            (package) => <String, Object?>{
              'name': package['name'],
              'version': package['version'],
              'kind': package['kind'],
              'source': package['source'],
              'dependencies':
                  ((package['dependencies'] as List?) ?? const <Object?>[])
                      .whereType<String>()
                      .toList()
                    ..sort(),
              'license_declared': package['name'] == 'blab_design_system'
                  ? 'MIT'
                  : 'NOASSERTION',
            },
          )
          .toList()
        ..sort(
          (left, right) =>
              (left['name'] as String).compareTo(right['name'] as String),
        );
  return <String, Object?>{
    'schema': 'blab.local-dependency-resolution/v1',
    'status': 'local-resolution-evidence-not-release-lock',
    'as_of': '2026-07-28',
    'root': document['root'],
    'package_count': packages.length,
    'license_boundary':
        'NOASSERTION means dependency license review was not performed; '
        'it is not a license conclusion.',
    'packages': packages,
  };
}

Map<String, Object?> _buildSpdx(Object? raw) {
  final snapshot = _stringMap(raw);
  final packages = (snapshot['packages'] as List).map(_stringMap).toList();
  final spdxPackages = <Map<String, Object?>>[];
  final relationships = <Map<String, Object?>>[];
  for (final package in packages) {
    final name = package['name'] as String;
    final spdxId = _spdxId(name);
    spdxPackages.add(<String, Object?>{
      'name': name,
      'SPDXID': spdxId,
      'versionInfo': package['version'],
      'downloadLocation': package['source'] == 'hosted'
          ? 'https://pub.dev/packages/$name'
          : 'NOASSERTION',
      'filesAnalyzed': false,
      'licenseConcluded': 'NOASSERTION',
      'licenseDeclared': package['license_declared'],
      'copyrightText': 'NOASSERTION',
      'externalRefs': package['source'] == 'hosted'
          ? [
              {
                'referenceCategory': 'PACKAGE-MANAGER',
                'referenceType': 'purl',
                'referenceLocator': 'pkg:pub/$name@${package['version']}',
              },
            ]
          : <Object?>[],
    });
    for (final dependency
        in (package['dependencies'] as List).whereType<String>()) {
      relationships.add(<String, Object?>{
        'spdxElementId': spdxId,
        'relationshipType': 'DEPENDS_ON',
        'relatedSpdxElement': _spdxId(dependency),
      });
    }
  }
  spdxPackages.sort(
    (left, right) =>
        (left['name'] as String).compareTo(right['name'] as String),
  );
  relationships.sort(
    (left, right) => jsonEncode(left).compareTo(jsonEncode(right)),
  );
  return <String, Object?>{
    'spdxVersion': 'SPDX-2.3',
    'dataLicense': 'CC0-1.0',
    'SPDXID': 'SPDXRef-DOCUMENT',
    'name': 'blab_design_system-0.2.0-local-resolution',
    'documentNamespace':
        'https://byungskerlab.invalid/spdx/blab-design-system/'
        '0.2.0-local-${_snapshotDigest(snapshot)}',
    'creationInfo': {
      'created': '2026-07-28T00:00:00Z',
      'creators': ['Tool: BLDS Phase5 inventory generator 0.1.0'],
      'comment':
          'Local unreleased dependency resolution; not release composition '
          'or a dependency-license conclusion.',
    },
    'packages': spdxPackages,
    'relationships': relationships,
  };
}

Map<String, Object?> _buildCycloneDx(Object? raw) {
  final snapshot = _stringMap(raw);
  final packages = (snapshot['packages'] as List).map(_stringMap).toList();
  final components = <Map<String, Object?>>[];
  final dependencies = <Map<String, Object?>>[];
  for (final package in packages) {
    final name = package['name'] as String;
    final version = package['version'] as String;
    final ref = 'pkg:pub/$name@$version';
    components.add(<String, Object?>{
      'type': package['source'] == 'sdk' ? 'framework' : 'library',
      'bom-ref': ref,
      'name': name,
      'version': version,
      if (name == 'blab_design_system')
        'licenses': [
          {
            'license': {'id': 'MIT'},
          },
        ],
      'properties': [
        {'name': 'blab:dependency-kind', 'value': package['kind']},
        {'name': 'blab:source', 'value': package['source']},
        {
          'name': 'blab:license-review',
          'value': name == 'blab_design_system'
              ? 'project-license-observed-holder-authority-unresolved'
              : 'not-reviewed-noassertion',
        },
      ],
      if (package['source'] == 'hosted') 'purl': ref,
    });
    dependencies.add(<String, Object?>{
      'ref': ref,
      'dependsOn': [
        for (final dependency
            in (package['dependencies'] as List).whereType<String>())
          _dependencyRef(packages, dependency),
      ]..sort(),
    });
  }
  components.sort(
    (left, right) =>
        (left['bom-ref'] as String).compareTo(right['bom-ref'] as String),
  );
  dependencies.sort(
    (left, right) => (left['ref'] as String).compareTo(right['ref'] as String),
  );
  return <String, Object?>{
    'bomFormat': 'CycloneDX',
    'specVersion': '1.6',
    'serialNumber':
        'urn:uuid:00000000-0000-5000-8000-'
        '${_snapshotDigest(snapshot).substring(0, 12)}',
    'version': 1,
    'metadata': {
      'timestamp': '2026-07-28T00:00:00Z',
      'tools': {
        'components': [
          {
            'type': 'application',
            'name': 'BLDS Phase5 inventory generator',
            'version': '0.1.0',
          },
        ],
      },
      'properties': [
        {
          'name': 'blab:scope',
          'value':
              'local-unreleased-resolution-not-authoritative-release-composition',
        },
      ],
    },
    'components': components,
    'dependencies': dependencies,
  };
}

Map<String, Object?> _buildOriginMap(Directory root) {
  final files = <Map<String, Object?>>[];
  for (final relative in freshCloneEquivalentOriginPaths(root)) {
    final entity = File(
      '${root.path}${Platform.pathSeparator}'
      '${relative.replaceAll('/', Platform.pathSeparator)}',
    );
    final origin = _originFor(relative);
    files.add(<String, Object?>{
      'path': relative,
      'origin': origin.$1,
      'license_status': origin.$2,
      'evidence': origin.$3,
      'sha256': relative == _originMapPath
          ? null
          : sha256.convert(entity.readAsBytesSync()).toString(),
    });
  }
  files.sort(
    (left, right) =>
        (left['path'] as String).compareTo(right['path'] as String),
  );
  return <String, Object?>{
    'schema': 'blab.file-origin-map/v1',
    'metadata': {
      'version': '0.1.0',
      'status': 'fresh-clone-equivalent-candidate-inventory-rights-unresolved',
      'as_of': '2026-07-28',
      'file_count': files.length,
      'coverage':
          'Git-tracked files plus explicitly allowed, nonignored candidate '
          'paths. Git-ignored files, local editor configuration, symlinks, '
          'and arbitrary untracked root files are excluded before content '
          'access.',
      'boundary':
          'Repository-authored classification is not a human rights or '
          'non-derivation attestation. This scope is fresh-clone-equivalent '
          'delivery evidence, not a visible-worktree inventory.',
      'selection': {
        'tracked': 'git ls-files --cached',
        'candidate':
            'git ls-files --others --exclude-standard restricted to explicit '
            'repository delivery roots and files',
        'excluded':
            'ignored files, local editor configuration, symlinks, and '
            'arbitrary untracked root files',
      },
    },
    'files': files,
  };
}

(String, String, String) _originFor(String path) {
  if (path.startsWith('contracts/compatibility/baselines/')) {
    return (
      'git-head-derived-baseline',
      'same-project-rights-unresolved',
      'contracts/compatibility/baseline-provenance.yaml',
    );
  }
  if (path == 'test/assets/fonts/NotoSansKR[wght].ttf' ||
      path == 'test/assets/fonts/NotoSansArabic[wdth,wght].ttf') {
    return (
      'third-party-test-fixture',
      'OFL-1.1',
      'test/assets/fonts/THIRD_PARTY_NOTICES.md',
    );
  }
  if (path == 'test/assets/fonts/MaterialIcons-Regular.otf') {
    return (
      'third-party-test-fixture',
      'CC-BY-4.0',
      'test/assets/fonts/THIRD_PARTY_NOTICES.md',
    );
  }
  if (path == 'test/assets/fonts/CupertinoIcons.ttf') {
    return (
      'third-party-test-fixture',
      'MIT',
      'test/assets/fonts/THIRD_PARTY_NOTICES.md',
    );
  }
  if (path.startsWith('test/assets/fonts/LICENSE-')) {
    return (
      'third-party-license-text',
      'verbatim-license-copy',
      'test/assets/fonts/THIRD_PARTY_NOTICES.md',
    );
  }
  if (path.startsWith('generated/') ||
      path == 'api/blab_design_system.api.txt' ||
      path.startsWith('contracts/sbom/')) {
    return (
      'repository-generated',
      'project-license-observed-holder-authority-unresolved',
      'deterministic repository tooling',
    );
  }
  if (path.startsWith('test/goldens/')) {
    return (
      'repository-generated-candidate-baseline',
      'project-license-observed-origin-attestation-unresolved',
      'contracts/visual-baselines.yaml',
    );
  }
  if (path == 'contracts/legal/astryx-0.1.3-evidence.yaml') {
    return (
      'metadata-only-capability-evidence',
      'no-astryx-content-copy-claimed-not-proven',
      'docs/BLDS_PHASE_0_BASELINE.md',
    );
  }
  return (
    'repository-worktree-origin',
    'project-license-observed-human-rights-unverified',
    'contracts/legal/attestations/origin-attestation.template.yaml',
  );
}

String _dependencyRef(List<Map<String, Object?>> packages, String name) {
  final package = packages.singleWhere((entry) => entry['name'] == name);
  return 'pkg:pub/$name@${package['version']}';
}

String _spdxId(String name) =>
    'SPDXRef-Package-${name.replaceAll(RegExp(r'[^A-Za-z0-9.-]'), '-')}';

String _snapshotDigest(Map<String, Object?> snapshot) =>
    sha256.convert(utf8.encode(jsonEncode(snapshot))).toString();

Map<String, Object?> _stringMap(Object? value) {
  if (value is! Map) throw const FormatException('Expected JSON object.');
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

String _pretty(Object? value) =>
    '${const JsonEncoder.withIndent('  ').convert(value)}\n';

void _writeJson(Directory root, String path, Object? value) {
  _write(root, path, _pretty(value));
}

void _write(Directory root, String path, String content) {
  final file = File('${root.path}/$path')..parent.createSync(recursive: true);
  file.writeAsStringSync(content, flush: true);
}
