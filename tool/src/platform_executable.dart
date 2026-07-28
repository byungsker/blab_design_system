import 'dart:io';

String platformExecutable(String executable, {bool? windows}) {
  final useWindows = windows ?? Platform.isWindows;
  if (useWindows && executable == 'flutter') {
    return 'flutter.bat';
  }
  return executable;
}
