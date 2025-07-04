import 'package:meta/meta_meta.dart';

/// Annotation to specify configuration for generating Dart classes that interface with shell scripts.
///
/// Apply this annotation to a class to indicate that it should be associated with shell script files,
/// and to configure code generation options such as the scripts path, parameter support, and method prefix.
///
/// Example usage:
/// ```dart
/// @ShellScripts(
///   scriptsPath: 'scripts',
///   enableParameters: true,
///   methodPrefix: 'run',
/// )
/// class MyShellScripts {}
/// ```
///
/// The generated class will be named based on the annotated class name with "Scripts" suffix.
/// For example, if applied to `MyShellScripts`, the generated class will be `MyShellScriptsScripts`.
///
/// - [scriptsPath]: Path to the folder containing `.sh` files. Can be relative or absolute.
/// - [enableParameters]: Whether to enable parameter support via `getopts` in the generated methods. Defaults to `true`.
/// - [methodPrefix]: Prefix for the generated methods that access scripts. Defaults to `'get'`.
@Target({TargetKind.classType})
class ShellScripts {
  /// Path to the folder with .sh files
  final String scriptsPath;

  /// Whether to enable parameter support via getopts
  final bool enableParameters;

  /// Prefix for methods accessing scripts
  final String methodPrefix;

  /// Creates a [ShellScripts] annotation.
  ///
  /// [scriptsPath] specifies the path to the shell scripts directory.
  /// [enableParameters] determines whether method parameters are enabled. Defaults to `true`.
  /// [methodPrefix] sets the prefix for generated method names. Defaults to `'get'`.
  const ShellScripts({
    required this.scriptsPath,
    this.enableParameters = true,
    this.methodPrefix = 'get',
  });
}

/// Annotation for a single shell script
///
/// Only methods marked with this annotation will have corresponding
/// shell scripts generated. The method name will be converted to camelCase
/// for the final generated method name.
@Target({TargetKind.method})
class ShellScript {
  /// Script file name (including .sh extension)
  final String fileName;

  /// List of supported parameters
  final List<ShellParameter> parameters;

  /// Whether to allow raw parameter string input
  final bool allowRawParameters;

  /// Creates a [ShellScript] annotation.
  ///
  /// [fileName] is the name of the shell script file to be generated.
  /// [parameters] is an optional list of parameters to be passed to the script.
  /// [allowRawParameters] enables raw parameter string input alongside typed parameters.
  const ShellScript({
    required this.fileName,
    this.parameters = const [],
    this.allowRawParameters = false,
  });
}

/// Description of a parameter for a shell script
class ShellParameter {
  /// Parameter flag (e.g., 'f' for -f)
  final String flag;

  /// Parameter name in the Dart method
  final String name;

  /// Whether the parameter is required
  final bool required;

  /// Default value
  final String? defaultValue;

  /// Parameter type (flag, value)
  final ParameterType type;

  /// Creates a [ShellParameter] with the specified properties.
  ///
  /// [flag] is the command-line flag associated with this parameter (e.g., `-f` or `--file`).
  /// [name] is the name of the parameter.
  /// [required] indicates whether this parameter is mandatory. Defaults to `false`.
  /// [defaultValue] specifies the default value for the parameter if not provided.
  /// [type] defines the type of the parameter, defaulting to [ParameterType.value].
  const ShellParameter({
    required this.flag,
    required this.name,
    this.required = false,
    this.defaultValue,
    this.type = ParameterType.value,
  });
}

/// Represents the type of a command-line parameter.
///
/// [ParameterType.flag] is used for flags that do not require a value (e.g., `-v` for verbose).
/// [ParameterType.value] is used for parameters that require an associated value (e.g., `-f filename`).
enum ParameterType {
  /// Flag without value (e.g., -v for verbose)
  flag,

  /// Parameter with value (e.g., -f filename)
  value,
}
