# Shell Script Codegen

A powerful Dart code generation package that seamlessly integrates shell scripts into your application. It automatically creates type-safe Dart classes for embedding and parameterizing shell scripts, complete with support for `getopts`.

## Key Features

- ⚙️ **Automatic Dart Class Generation**: Transforms your `.sh` files into Dart classes.
- 🔡 **Embedded Script Content**: Shell scripts are embedded directly as string constants in your Dart code.
- 🎛️ **Powerful Parameterization**: Supports both type-safe and raw string parameters using `getopts`.
- 🛡️ **Enhanced Safety**: Provides automatic and secure escaping for all shell arguments.
- 🎯 **Type-Safe Access**: Access your scripts through generated methods for improved reliability.
- 🔄 **Flexible Usage Patterns**: Mix and match typed and raw parameters to suit your needs.

## Installation

To get started, add the necessary dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  # This package is not needed at runtime, so it's not a dependency.
  # Add it if you need access to annotations directly.
  # shell_script_codegen: ^1.2.0

dev_dependencies:
  build_runner: ^2.5.4
  shell_script_codegen: ^1.2.0 # Add the generator to dev_dependencies
```

Then, run `dart pub get` to install the packages.

## Quick Start

Follow these steps to quickly integrate `shell_script_codegen` into your project.

### 1. Create Your Shell Scripts

First, create a directory for your scripts (e.g., `assets/scripts`) and add your `.sh` files.

**`assets/scripts/backup.sh`**
```bash
#!/bin/bash

# Default values
VERBOSE=false

# Parse parameters using getopts
while getopts "s:d:v" opt; do
  case $opt in
    s) SOURCE="$OPTARG" ;;
    d) DEST="$OPTARG" ;;
    v) VERBOSE=true ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Main script logic
if [ "$VERBOSE" = true ]; then
    echo "Backing up from '$SOURCE' to '$DEST'..."
fi

# A real script would do more here, like:
# cp -r "$SOURCE" "$DEST"
echo "Backup command executed."
```

### 2. Annotate a Dart Class

Create a Dart file and define a class with annotations to configure the code generation.

**`lib/my_scripts.dart`**
```dart
import 'package:shell_script_codegen/annotations.dart';

part 'my_scripts.g.dart';

@ShellScripts(
  scriptsPath: 'assets/scripts',
  enableParameters: true,
  methodPrefix: 'run',
)
abstract class MyScripts {
  @ShellScript(
    fileName: 'backup.sh',
    parameters: [
      ShellParameter(
        flag: 's',
        name: 'source',
        required: true,
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
    allowRawParameters: true,
  )
  void backupScript();
}
```

### 3. Run Code Generation

Execute the following command in your terminal to generate the Dart code:

```bash
dart run build_runner build
```

### 4. Use the Generated Code

You can now import the generated file and use the class to access your scripts with type-safe parameters or raw strings.

```dart
import 'my_scripts.dart';

void main() {
  // Access the generated instance
  final scripts = MyScriptsScripts.instance;

  // --- Usage Examples ---

  // 1. Typed parameters for safety and clarity
  final backupScript1 = scripts.runBackupScript(
    source: '/home/user/data',
    destination: '/backup/data',
    verbose: true,
  );
  print('--- Typed ---');
  print(backupScript1);

  // 2. Raw parameters for flexibility
  final backupScript2 = scripts.runBackupScript(
    rawParameters: '-s /home/user/docs -d /backup/docs -v',
  );
  print('\n--- Raw ---');
  print(backupScript2);

  // 3. Mix typed and raw parameters
  final backupScript3 = scripts.runBackupScript(
    source: '/home/user/media',
    destination: '/backup/media',
    rawParameters: '--verbose --force', // Your script would need to handle --force
  );
  print('\n--- Mixed ---');
  print(backupScript3);
}
```

## API Reference

### @ShellScripts

This class-level annotation configures the code generator.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `scriptsPath` | `String` | *Required* | Path to the directory containing `.sh` files, relative to the project root. |
| `enableParameters` | `bool` | `true` | If true, generates methods that accept parameters. |
| `methodPrefix` | `String` | `'get'` | A prefix for all generated script-accessing methods. |

### @ShellScript

This method-level annotation links an abstract method to a specific shell script file.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `fileName` | `String` | *Required* | The name of the `.sh` file in the `scriptsPath` directory. |
| `parameters` | `List<ShellParameter>` | `[]` | A list of typed parameters that the script accepts. |
| `allowRawParameters` | `bool` | `false` | If true, allows passing a raw string of additional parameters to the script. |

### ShellParameter

Defines a single parameter for a shell script.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `flag` | `String` | *Required* | The parameter flag (e.g., `'f'` for `-f`). |
| `name` | `String` | *Required* | The name of the parameter in the generated Dart method. |
| `required` | `bool` | `false` | Whether the parameter is mandatory. |
| `defaultValue` | `String?` | `null` | A default value if the parameter is not provided. |
| `type` | `ParameterType` | `ParameterType.value` | The type of parameter. Can be `.value` or `.flag`. |

- **`ParameterType.value`**: A parameter that takes a value (e.g., `-f filename`).
- **`ParameterType.flag`**: A boolean flag that doesn't take a value (e.g., `-v`).

## Usage Patterns

### Typed Parameters Only

Best for scripts with a fixed API for maximum type safety and clarity.

```dart
@ShellScript(
  fileName: 'process.sh',
  parameters: [
    ShellParameter(flag: 'i', name: 'input', required: true),
    ShellParameter(flag: 'o', name: 'output', required: true),
    ShellParameter(flag: 'v', name: 'verbose', type: ParameterType.flag),
  ],
)
void processFiles();

// Usage
final script = scripts.getProcessFiles(
  input: '/path/to/input',
  output: '/path/to/output',
  verbose: true,
);
```

### Raw Parameters Only

Ideal for wrapping complex command-line tools or when parameters are dynamic.

```dart
@ShellScript(
  fileName: 'flexible.sh',
  allowRawParameters: true,
)
void flexibleScript();

// Usage
final script = scripts.getFlexibleScript(
  rawParameters: '-i /input -o /output --format json -v',
);
```

### Mixed Typed and Raw Parameters

Combine required, typed parameters with optional, raw parameters for the ultimate flexibility.

```dart
@ShellScript(
  fileName: 'mixed.sh',
  parameters: [
    ShellParameter(flag: 'i', name: 'input', required: true),
  ],
  allowRawParameters: true,
)
void mixedScript();

// Usage
final script = scripts.getMixedScript(
  input: '/path/to/input',
  rawParameters: '--format json --compress --verbose',
);
```

## Shell Script Guidelines

To ensure compatibility with the code generator, your shell scripts should follow these guidelines.

### Requirements

1.  **`.sh` Extension**: All script files must use the `.sh` extension.
2.  **Use `getopts`**: Parameters must be parsed inside the script using the `getopts` command.
3.  **Error Handling**: Scripts should handle unknown options gracefully.

### Recommended Script Structure

```bash
#!/bin/bash

# 1. Initialize default values
VERBOSE=false
OUTPUT_DIR="."

# 2. Parse options with getopts
while getopts "o:vh" opt; do
  case $opt in
    o) OUTPUT_DIR="$OPTARG" ;;
    v) VERBOSE=true ;;
    h) show_help; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# 3. Check for required arguments (if any)
# Example: if [ -z "$INPUT_FILE" ]; then ...

# 4. Main script logic
if [ "$VERBOSE" = true ]; then
    echo "Verbose mode is ON."
    echo "Output directory: $OUTPUT_DIR"
fi

# Your script's main functionality here
```

## Troubleshooting

- **Generated File Not Found**: Ensure you have included `part 'my_scripts.g.dart';` and run the build command.
- **Script Not Found**: Verify that `scriptsPath` in `@ShellScripts` is a correct path relative to your assets folder.
- **Parameter Errors**: Double-check that the `flag` in `ShellParameter` exactly matches the flag used in your script's `getopts` string.
- **Stale Code**: If you make changes and they don't appear, try cleaning and rebuilding: `dart run build_runner clean && dart run build_runner build`.