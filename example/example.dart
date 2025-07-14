part 'main.g.dart';

@ShellScripts(
  scriptsPath: 'assets/scripts', // Path to the scripts folder
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

// Example usage of MyShell (assuming code generation is complete)
void main() async {
  // Get the singleton instance (or create as appropriate for your generator)
  final shell = MyShellScripts.instance;

  // Generate a backup script with all parameters
  final script = shell.getBackupScript(
    source: 'data.txt',
    destination: '/backups/data.bak',
    verbose: true,
  );

  print('Generated backup script:');
  print(script);

  // Execute the generated script
  await shell.executeScript(script);
}
