import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'shell_script_generator.dart';

/// Builder options for the shell script builder
Builder shellScriptBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [ShellScriptGenerator()],
    'shell_scripts',
  );
}
