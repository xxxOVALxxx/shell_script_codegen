import 'annotations.dart';

/// A utility class for parameterizing shell scripts by injecting or replacing
/// variables and values within the script content.
///
/// Use this class to safely and programmatically modify shell scripts,
/// enabling dynamic script generation and execution.
class ShellScriptParameterizer {
  /// Generates Dart code for creating a script with parameters
  static String generateDartParameterMethod(
    String methodName,
    String scriptContent,
    List<ShellParameter> parameters,
    bool allowRawParameters,
  ) {
    final buffer = StringBuffer();

    // Generate method signature
    buffer.write('  String $methodName(');

    final hasParameters = parameters.isNotEmpty || allowRawParameters;

    if (hasParameters) {
      buffer.writeln('{');

      // Add typed parameters
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

        if (i < parameters.length - 1 || allowRawParameters) {
          buffer.writeln(',');
        } else {
          buffer.writeln();
        }
      }

      // Add raw parameters option
      if (allowRawParameters) {
        buffer.writeln('    String? rawParameters,');
      }

      buffer.write('  }');
    }

    buffer.writeln(') {');

    // Generate method body
    buffer.writeln('    final args = <String>[];');

    // Process typed parameters
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

    // Process raw parameters
    if (allowRawParameters) {
      buffer.writeln(
          '    if (rawParameters != null && rawParameters.isNotEmpty) {');
      buffer.writeln('      args.addAll(_parseRawParameters(rawParameters));');
      buffer.writeln('    }');
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
  }

  /// Parses raw parameter string into a list of arguments
  List<String> _parseRawParameters(String rawParameters) {
    final args = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    bool inSingleQuotes = false;
    bool escapeNext = false;

    for (int i = 0; i < rawParameters.length; i++) {
      final char = rawParameters[i];

      if (escapeNext) {
        buffer.write(char);
        escapeNext = false;
        continue;
      }

      switch (char) {
        case '\\\\':
          escapeNext = true;
          break;
        case '"':
          if (!inSingleQuotes) {
            inQuotes = !inQuotes;
          } else {
            buffer.write(char);
          }
          break;
        case "'":
          if (!inQuotes) {
            inSingleQuotes = !inSingleQuotes;
          } else {
            buffer.write(char);
          }
          break;
        case ' ':
        case '\\t':
        case '\\n':
          if (inQuotes || inSingleQuotes) {
            buffer.write(char);
          } else {
            if (buffer.isNotEmpty) {
              args.add(buffer.toString());
              buffer.clear();
            }
          }
          break;
        default:
          buffer.write(char);
          break;
      }
    }

    if (buffer.isNotEmpty) {
      args.add(buffer.toString());
    }

    return args;
  }''';
  }
}
