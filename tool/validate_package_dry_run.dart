import 'dart:io';

import 'capture_package_dry_run.dart' as package_dry_run;

void main() {
  const stableInventory = <String, Object?>{
    'schema': 'blab.package-dry-run-inventory/v1',
    'publication_performed': false,
    'file_count': 1,
    'content_manifest_sha256': 'stable-content',
    'files': <String>['lib/blab_design_system.dart'],
  };
  final changedSize = <String, Object?>{
    ...stableInventory,
    'compressed_archive_size': '128 KB',
  };
  final baseline = <String, Object?>{
    ...stableInventory,
    'compressed_archive_size': '127 KB',
  };
  _expect(
    package_dry_run.packageDryRunInventoriesMatchStable(baseline, changedSize),
    'Compressed archive-size variation must not drift deterministic evidence.',
  );
  _expect(
    !package_dry_run.packageDryRunInventoriesMatchStable(baseline, {
      ...changedSize,
      'content_manifest_sha256': 'changed-content',
    }),
    'Package content changes must remain reproducibility failures.',
  );
  stdout.writeln(
    'BLDS deterministic package dry-run inventory validation passed.',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
