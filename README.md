# Shell Script Codegen

A package for generating Dart code that allows you to embed and parameterize shell scripts in your Dart applications. Automatically creates classes with methods for accessing shell scripts with parameter support via `getopts`.

## Features

- 🔧 Automatic generation of Dart classes from shell scripts
- 📝 Embedding `.sh` file contents as string constants
- ⚙️ Parameterization support for scripts via `getopts`
- 🛡️ Safe shell argument escaping
- 🎯 Type-safe script access

## Installation

Add dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  shell_script_codegen: ^1.0.0

dev_dependencies:
  build_runner: ^2.5.4
```

## Quick Start

### 1. Create shell scripts

Create a `scripts/` directory at the project root and place your `.sh` files there:

```bash
# scripts/backup.sh
#!/bin/bash

# Get parameters via getopts
while getopts "s:d:v" opt; do
  case $opt in
    s) SOURCE="$OPTARG" ;;
    d) DEST="$OPTARG" ;;
    v) VERBOSE=true ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

# Main script logic
if [ "$VERBOSE" = true ]; then
    echo "Creating backup from $SOURCE to $DEST"
fi

cp -r "$SOURCE" "$DEST"
```

### 2. Create an annotated class

```dart
// lib/my_scripts.dart
import 'package:shell_script_codegen/shell_script_codegen.dart';

part 'my_scripts.shell_scripts.g.part';

@ShellScripts(
  scriptsPath: 'scripts',
  enableParameters: true,
  methodPrefix: 'get',
)
class MyShell {
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
  )
  void backupScript() {}
}
```

### 3. Run code generation

```bash
dart run build_runner build
```

### 4. Use the generated class

```dart
import 'my_scripts.dart';

void main() {
  final scripts = MyShellScripts.instance;
  
  // Get script with parameters
  final backupScript = scripts.getBackupScript(
    source: '/home/user/data',
    destination: '/backup/data',
    verbose: true,
  );
  
  print(backupScript);
  // Output: script with automatically added set -- line with parameters
}
```

## Detailed Description

### Annotations

#### @ShellScripts

The main annotation for the class, specifying generation parameters:

```dart
@ShellScripts(
  scriptsPath: 'scripts',        // Path to the scripts folder
  enableParameters: true,        // Enable parameter support
  methodPrefix: 'get',           // Prefix for script access methods
)
```

**Parameters:**
- `scriptsPath` (required) - path to the directory with `.sh` files
- `enableParameters` (default `true`) - enables generation of methods with parameters
- `methodPrefix` (default `'get'`) - prefix for script access methods

#### @ShellScript

Annotation for methods, linking to a specific shell script:

```dart
@ShellScript(
  fileName: 'my_script.sh',
  parameters: [
    ShellParameter(
      flag: 'f',
      name: 'file',
      required: true,
    ),
  ],
)
void myMethod() {} // Method name will be converted to camelCase
```

#### ShellParameter

Description of a parameter for a shell script:

```dart
ShellParameter(
  flag: 'f',                    // Parameter flag (without -)
  name: 'fileName',             // Name in Dart method
  required: false,              // Whether the parameter is required
  defaultValue: 'default.txt',  // Default value
  type: ParameterType.value,    // Parameter type
)
```

**Parameter types:**
- `ParameterType.flag` - flag without value (e.g., `-v` for verbose)
- `ParameterType.value` - parameter with value (e.g., `-f filename`)

## Shell Script Requirements

### Mandatory Requirements

1. **File extension**: All scripts must have a `.sh` extension

2. **Using getopts**: For parameterized scripts, you must use `getopts` for parameter handling:

```bash
#!/bin/bash

while getopts "f:v" opt; do
  case $opt in
    f) FILE="$OPTARG" ;;
    v) VERBOSE=true ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done
```

3. **Proper error handling**: Scripts must properly handle unknown options:

```bash
\?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
```

### Script Structure Recommendations

#### Basic structure

```bash
#!/bin/bash

# Initialize default variables
VERBOSE=false
OUTPUT_DIR=""
INPUT_FILE=""

# Parameter handling
while getopts "i:o:vh" opt; do
  case $opt in
    i) INPUT_FILE="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    v) VERBOSE=true ;;
    h) show_help; exit 0 ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

# Check required parameters
if [ -z "$INPUT_FILE" ]; then
    echo "Error: Input file is required (-i)" >&2
    exit 1
fi

# Main script logic
if [ "$VERBOSE" = true ]; then
    echo "Processing $INPUT_FILE..."
fi

# Your code here
```

#### Handling flags and values

```bash
# For flags (no values)
while getopts "vh" opt; do
  case $opt in
    v) VERBOSE=true ;;      # Enable verbose mode flag
    h) show_help; exit 0 ;;  # Help flag
  esac
done

# For parameters with values
while getopts "f:d:n:" opt; do
  case $opt in
    f) FILE_PATH="$OPTARG" ;;     # File path
    d) DIRECTORY="$OPTARG" ;;     # Directory
    n) COUNT="$OPTARG" ;;         # Numeric value
  esac
done
```

#### Parameter validation

```bash
# Check if file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File $INPUT_FILE does not exist" >&2
    exit 1
fi

# Check write permissions for directory
if [ ! -w "$OUTPUT_DIR" ]; then
    echo "Error: Cannot write to directory $OUTPUT_DIR" >&2
    exit 1
fi

# Check numeric values
if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
    echo "Error: COUNT must be a positive integer" >&2
    exit 1
fi
```

### Generator Features

1. **Automatic parameter insertion**: The generator automatically adds a `set --` line with parameters at the beginning of the script after the shebang

2. **Argument escaping**: All arguments are automatically escaped for safe use in the shell

3. **Structure preservation**: The original script structure is preserved, only the parameter line is added

### Example of Correct Scripts

#### Simple script with one parameter

```bash
#!/bin/bash
# scripts/hello.sh

while getopts "n:" opt; do
  case $opt in
    n) NAME="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

echo "Hello, ${NAME:-World}!"
```

#### Complex script with multiple parameters

```bash
#!/bin/bash
# scripts/process_files.sh

# Default values
VERBOSE=false
RECURSIVE=false
OUTPUT_FORMAT="txt"
INPUT_DIR=""
OUTPUT_DIR=""

# Parameter handling
while getopts "i:o:f:vr" opt; do
  case $opt in
    i) INPUT_DIR="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    f) OUTPUT_FORMAT="$OPTARG" ;;
    v) VERBOSE=true ;;
    r) RECURSIVE=true ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

# Check required parameters
if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Error: Both input (-i) and output (-o) directories are required" >&2
    exit 1
fi

# Main logic
if [ "$VERBOSE" = true ]; then
    echo "Processing files from $INPUT_DIR to $OUTPUT_DIR"
    echo "Format: $OUTPUT_FORMAT"
    echo "Recursive: $RECURSIVE"
fi

# Your file processing logic here
```

## Troubleshooting

### Common Errors

1. **Script not found**: Make sure the `scriptsPath` is set correctly relative to the project root

2. **Incorrect generation**: Check that all methods with `@ShellScript` have corresponding `.sh` files

3. **Parameter errors**: Make sure the flags in `ShellParameter` match the flags in `getopts`