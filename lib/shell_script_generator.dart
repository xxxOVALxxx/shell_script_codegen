import 'dart:async';
import 'dart:io';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as path;

import 'annotations.dart';
import 'shell_script_parameterizer.dart';

/// Generator for creating classes with shell scripts
class ShellScriptGenerator extends GeneratorForAnnotation<ShellScripts> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'ShellScripts annotation can only be applied to classes.',
        element: element,
      );
    }

    final scriptsPath = annotation.read('scriptsPath').stringValue;
    final className = '${element.name}Scripts';
    final enableParameters = annotation.read('enableParameters').boolValue;
    final methodPrefix = annotation.read('methodPrefix').stringValue;

    // Get the list of methods with the @ShellScript annotation
    final annotatedMethods = _getAnnotatedMethods(element);

    if (annotatedMethods.isEmpty) {
      throw InvalidGenerationSourceError(
        'No methods with @ShellScript annotation found in class ${element.name}',
        element: element,
      );
    }

    // Check for the existence of script files
    final validMethods = <MethodElement>[];
    for (final method in annotatedMethods) {
      final scriptAnnotation = _getShellScriptAnnotation(method);
      if (scriptAnnotation != null) {
        final fileName = scriptAnnotation.read('fileName').stringValue;
        final fullPath = path.join(scriptsPath, fileName);

        if (await File(fullPath).exists()) {
          validMethods.add(method);
        } else {
          log.warning(
              'Script file not found: $fullPath for method ${method.name}');
        }
      }
    }

    if (validMethods.isEmpty) {
      throw InvalidGenerationSourceError(
        'No valid script files found for annotated methods in class ${element.name}',
        element: element,
      );
    }

    final buffer = StringBuffer();
    _generateClassHeader(buffer, className);

    // Generate constants for all valid methods
    for (final method in validMethods) {
      final scriptAnnotation = _getShellScriptAnnotation(method)!;
      final fileName = scriptAnnotation.read('fileName').stringValue;
      final fullPath = path.join(scriptsPath, fileName);

      await _generateScriptConstant(
          buffer, fullPath, method.name, methodPrefix);
    }

    // Generate accessor methods
    for (final method in validMethods) {
      await _generateAccessMethod(
        buffer,
        method,
        methodPrefix,
        enableParameters,
      );
    }

    if (enableParameters) {
      buffer.writeln(ShellScriptParameterizer.generateBuildScriptMethod());
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Gets all methods with the @ShellScript annotation
  List<MethodElement> _getAnnotatedMethods(ClassElement classElement) {
    final methods = <MethodElement>[];

    for (final method in classElement.methods) {
      if (TypeChecker.fromRuntime(ShellScript).hasAnnotationOf(method)) {
        methods.add(method);
      }
    }

    return methods;
  }

  /// Gets the @ShellScript annotation for a method
  ConstantReader? _getShellScriptAnnotation(MethodElement method) {
    final annotation =
        TypeChecker.fromRuntime(ShellScript).firstAnnotationOf(method);
    return annotation != null ? ConstantReader(annotation) : null;
  }

  void _generateClassHeader(StringBuffer buffer, String className) {
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln();
    buffer.writeln('/// Generated class containing shell scripts');
    buffer.writeln('class $className {');
    buffer.writeln('  const $className._();');
    buffer.writeln('  static const $className instance = $className._();');
    buffer.writeln();
  }

  /// Generates a constant for the shell script content
  Future<void> _generateScriptConstant(
    StringBuffer buffer,
    String filePath,
    String methodName,
    String methodPrefix,
  ) async {
    final content = await File(filePath).readAsString();
    final camelCaseMethodName = _toCamelCase(methodName);
    final constantName =
        '_${methodPrefix}${_capitalize(camelCaseMethodName)}Base';

    buffer.writeln('  static const String $constantName = r"""');
    buffer.writeln(content);
    buffer.writeln('""";');
    buffer.writeln();
  }

  Future<void> _generateAccessMethod(
    StringBuffer buffer,
    MethodElement method,
    String methodPrefix,
    bool enableParameters,
  ) async {
    final camelCaseMethodName = _toCamelCase(method.name);
    final finalMethodName = '$methodPrefix${_capitalize(camelCaseMethodName)}';
    final constantName =
        '_${methodPrefix}${_capitalize(camelCaseMethodName)}Base';

    // Get parameters from the @ShellScript annotation
    final parameters = _getParametersFromMethod(method);
    final allowRawParameters = _getAllowRawParametersFromMethod(method);

    if (enableParameters && (parameters.isNotEmpty || allowRawParameters)) {
      // Generate method with parameters
      buffer.writeln(ShellScriptParameterizer.generateDartParameterMethod(
        finalMethodName,
        constantName,
        parameters,
        allowRawParameters,
      ));
    } else {
      // Generate simple getter
      buffer.writeln('  /// Returns the ${camelCaseMethodName} shell script');
      buffer.writeln('  String get $finalMethodName => $constantName;');
    }

    buffer.writeln();
  }

  List<ShellParameter> _getParametersFromMethod(MethodElement method) {
    final annotation =
        TypeChecker.fromRuntime(ShellScript).firstAnnotationOf(method);

    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final parametersReader = reader.read('parameters');

      return parametersReader.listValue.map((paramObj) {
        final paramReader = ConstantReader(paramObj);
        return ShellParameter(
          flag: paramReader.read('flag').stringValue,
          name: paramReader.read('name').stringValue,
          required: paramReader.read('required').boolValue,
          defaultValue: paramReader.read('defaultValue').isNull
              ? null
              : paramReader.read('defaultValue').stringValue,
          type: ParameterType.values[paramReader
              .read('type')
              .objectValue
              .getField('index')!
              .toIntValue()!],
        );
      }).toList();
    }

    return [];
  }

  bool _getAllowRawParametersFromMethod(MethodElement method) {
    final annotation =
        TypeChecker.fromRuntime(ShellScript).firstAnnotationOf(method);

    if (annotation != null) {
      final reader = ConstantReader(annotation);
      return reader.read('allowRawParameters').boolValue;
    }

    return false;
  }

  /// Convert a string to camelCase
  String _toCamelCase(String text) {
    if (text.isEmpty) return text;

    // Split by underscores and dashes
    final parts = text.split(RegExp(r'[_-]'));

    if (parts.length == 1) {
      // If there are no delimiters, just lowercase the first letter
      return text[0].toLowerCase() + text.substring(1);
    }

    final buffer = StringBuffer();

    // The first part remains lowercase
    buffer.write(parts[0].toLowerCase());

    // The rest start with uppercase
    for (int i = 1; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        buffer.write(_capitalize(parts[i].toLowerCase()));
      }
    }

    return buffer.toString();
  }

  /// Capitalizes the first letter
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
