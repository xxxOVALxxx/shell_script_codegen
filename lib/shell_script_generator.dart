import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as path;

import 'annotations.dart';
import 'shell_script_parameterizer.dart';

/// A helper class to hold a method and its corresponding script content.
class _MethodWithContent {
  final MethodElement method;
  final String content;
  _MethodWithContent(this.method, this.content);
}

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

    final annotatedMethods = _getAnnotatedMethods(element);
    if (annotatedMethods.isEmpty) {
      throw InvalidGenerationSourceError(
        'No methods with @ShellScript annotation found in class ${element.name}',
        element: element,
      );
    }

    final methodsWithContent = <_MethodWithContent>[];

    // Process all annotated methods, read their associated script assets
    for (final method in annotatedMethods) {
      final scriptAnnotation = _getShellScriptAnnotation(method);
      if (scriptAnnotation == null) continue;

      final fileName = scriptAnnotation.read('fileName').stringValue;
      final assetId = AssetId(
        buildStep.inputId.package,
        path.join(scriptsPath, fileName),
      );

      if (await buildStep.canRead(assetId)) {
        final content = await buildStep.readAsString(assetId);
        methodsWithContent.add(_MethodWithContent(method, content));
      } else {
        log.warning(
            'Script asset not found: ${assetId.path} for method ${method.name}');
      }
    }

    if (methodsWithContent.isEmpty) {
      throw InvalidGenerationSourceError(
        'No valid script assets found for annotated methods in class ${element.name}',
        element: element,
      );
    }

    final buffer = StringBuffer();
    _generateClassHeader(buffer, className);

    // Generate constants for all valid methods
    for (final item in methodsWithContent) {
      _generateScriptConstant(
        buffer,
        item.content,
        item.method.name,
        methodPrefix,
      );
    }

    // Generate accessor methods
    for (final item in methodsWithContent) {
      _generateAccessMethod(
        buffer,
        item.method,
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
    return classElement.methods
        .where((m) => TypeChecker.fromRuntime(ShellScript).hasAnnotationOf(m))
        .toList();
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
  void _generateScriptConstant(
    StringBuffer buffer,
    String content,
    String methodName,
    String methodPrefix,
  ) {
    final camelCaseMethodName = _toCamelCase(methodName);
    final constantName =
        '_${methodPrefix}${_capitalize(camelCaseMethodName)}Base';

    buffer.writeln('  static const String $constantName = r"""');
    buffer.writeln(content);
    buffer.writeln('""";');
    buffer.writeln();
  }

  void _generateAccessMethod(
    StringBuffer buffer,
    MethodElement method,
    String methodPrefix,
    bool enableParameters,
  ) {
    final camelCaseMethodName = _toCamelCase(method.name);
    final finalMethodName = '$methodPrefix${_capitalize(camelCaseMethodName)}';
    final constantName =
        '_${methodPrefix}${_capitalize(camelCaseMethodName)}Base';

    final parameters = _getParametersFromMethod(method);
    final allowRawParameters = _getAllowRawParametersFromMethod(method);

    if (enableParameters && (parameters.isNotEmpty || allowRawParameters)) {
      buffer.writeln(ShellScriptParameterizer.generateDartParameterMethod(
        finalMethodName,
        constantName,
        parameters,
        allowRawParameters,
      ));
    } else {
      buffer.writeln('  /// Returns the ${camelCaseMethodName} shell script');
      buffer.writeln('  String get $finalMethodName => $constantName;');
    }

    buffer.writeln();
  }

  List<ShellParameter> _getParametersFromMethod(MethodElement method) {
    final annotation = _getShellScriptAnnotation(method);
    if (annotation == null) return [];

    final parametersReader = annotation.read('parameters');
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

  bool _getAllowRawParametersFromMethod(MethodElement method) {
    final annotation = _getShellScriptAnnotation(method);
    if (annotation == null) return false;

    return annotation.read('allowRawParameters').boolValue;
  }

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    final parts = text.split(RegExp(r'[_-]'));
    if (parts.length == 1) {
      return text[0].toLowerCase() + text.substring(1);
    }
    final buffer = StringBuffer(parts.first.toLowerCase());
    for (int i = 1; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        buffer.write(_capitalize(parts[i].toLowerCase()));
      }
    }
    return buffer.toString();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
