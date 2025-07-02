part 'main.g.dart';

@ShellScripts(
  scriptsPath: 'scripts', // Path to the scripts folder
  enableParameters: true, // Enable parameter support
  methodPrefix: 'get', // Prefix for generated methods
)
class MyShell {
  @ShellScript(
    fileName: 'backup.sh',
    parameters: [
      ShellParameter(
        flag: 's', // Parameter flag (without -)
        name: 'source', // Name in Dart method
        required: true, // Whether the parameter is required
        defaultValue: 'default.txt', // Default value
        type: ParameterType.value, // Parameter type
      ),
      ShellParameter(
        flag: 'd',
        name: 'destination',
        required: true,
      ),
      ShellParameter(
        flag: 'v',
        name: 'verbose',
        type: ParameterType.flag,
      ),
    ],
  )
  void backupScript() {}
}
