import 'annotations.dart';

class ShellScriptParameterizer {
  /// Generates Dart code for creating a script with parameters
  static String generateDartParameterMethod(
    String methodName,
    String scriptContent,
    List<ShellParameter> parameters,
  ) {
    final buffer = StringBuffer();

    // Generate method signature
    buffer.write('  String $methodName(');

    if (parameters.isNotEmpty) {
      buffer.writeln('{');
      for (int i = 0; i < parameters.length; i++) {
        final param = parameters[i];
        final paramType = param.type == ParameterType.flag ? 'bool' : 'String';

        if (param.required) {
          buffer.write('    required $paramType ${param.name}');
        } else {
          final defaultValue = param.type == ParameterType.flag
              ? 'false'
              : (param.defaultValue != null
                  ? "'${param.defaultValue}'"
                  : 'null');
          buffer.write('    $paramType? ${param.name} = $defaultValue');
        }

        if (i < parameters.length - 1) {
          buffer.writeln(',');
        } else {
          buffer.writeln();
        }
      }
      buffer.write('  }');
    }

    buffer.writeln(') {');

    // Generate method body
    buffer.writeln('    final args = <String>[];');

    for (final param in parameters) {
      if (param.type == ParameterType.flag) {
        buffer.writeln(
            '    if (${param.name} == true) args.add("-${param.flag}");');
      } else {
        buffer.writeln('    if (${param.name} != null) {');
        buffer.writeln('      args.add("-${param.flag}");');
        buffer.writeln('      args.add(${param.name}!);');
        buffer.writeln('    }');
      }
    }

    buffer.writeln('    return _buildScriptWithArgs($scriptContent, args);');
    buffer.writeln('  }');

    return buffer.toString();
  }

  /// Generates a helper method for building a script with arguments
  static String generateBuildScriptMethod() {
    return '''
  String _buildScriptWithArgs(String baseScript, List<String> args) {
    if (args.isEmpty) return baseScript;

    final lines = baseScript.split('\\n');
    final resultLines = <String>[];
    
    // Initialize the insert index for the set -- line
    int insertIndex = 0;
    
    // Skip the shebang line if it exists
    if (lines.isNotEmpty && lines[0].startsWith('#!')) {
      resultLines.add(lines[0]);
      insertIndex = 1;
    }
    
    // Insert the set -- line after the shebang or at the start
    final escapedArgs = args.map(_escapeShellArg).toList();
    final argsString = escapedArgs.join(' ');
    resultLines.add('set -- \$argsString');
    
    // Add the rest of the script lines
    resultLines.addAll(lines.skip(insertIndex));
    
    return resultLines.join('\\n');
  }

  String _escapeShellArg(String arg) {
    // Escape single quotes by replacing them with '\'' in the argument
    return "'\${arg.replaceAll(\"'\", \"'\\\"'\\\"'\")}'";
  }''';
  }
}
