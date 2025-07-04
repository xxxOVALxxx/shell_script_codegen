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

part 'my_scripts.g.dart';

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
    allowRawParameters: true,  // Enable raw parameter support
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
  
  // Get script with typed parameters
  final backupScript1 = scripts.getBackupScript(
    source: '/home/user/data',
    destination: '/backup/data',
    verbose: true,
  );
  
  // Get script with raw parameters
  final backupScript2 = scripts.getBackupScript(
    rawParameters: '-s /home/user/docs -d /backup/docs -v',
  );
  
  // Mix typed and raw parameters
  final backupScript3 = scripts.getBackupScript(
    source: '/home/user/data',
    destination: '/backup/data',
    rawParameters: '-v --extra-option value',
  );
  
  print(backupScript1);
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
  allowRawParameters: true,  // Enable raw parameter string support
)
void myMethod() {} // Method name will be converted to camelCase
```

**Parameters:**
- `fileName` (required) - name of the shell script file
- `parameters` (default `[]`) - list of typed parameters
- `allowRawParameters` (default `false`) - enables raw parameter string input

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

## Parameter Usage Patterns

### 1. Typed Parameters Only

```dart
@ShellScript(
  fileName: 'process.sh',
  parameters: [
    ShellParameter(flag: 'i', name: 'input', required: true),
    ShellParameter(flag: 'o', name: 'output', required: true),
    ShellParameter(flag: 'v', name: 'verbose', type: ParameterType.flag),
  ],
)
void processFiles() {}

// Usage:
final script = scripts.getProcessFiles(
  input: '/path/to/input',
  output: '/path/to/output',
  verbose: true,
);
```

### 2. Raw Parameters Only

```dart
@ShellScript(
  fileName: 'flexible.sh',
  allowRawParameters: true,
)
void flexibleScript() {}

// Usage:
final script = scripts.getFlexibleScript(
  rawParameters: '-i /input -o /output --format json -v',
);
```

### 3. Mixed Parameters

```dart
@ShellScript(
  fileName: 'mixed.sh',
  parameters: [
    ShellParameter(flag: 'i', name: 'input', required: true),
    ShellParameter(flag: 'o', name: 'output', required: true),
  ],
  allowRawParameters: true,
)
void mixedScript() {}

// Usage:
final script = scripts.getMixedScript(
  input: '/path/to/input',
  output: '/path/to/output',
  rawParameters: '--format json --compress --verbose',
);
```

## Raw Parameter String Features

### Automatic Parsing

The generator automatically parses raw parameter strings, handling:

- **Quoted arguments**: `"file with spaces.txt"` or `'single quotes'`
- **Escaped characters**: `\"` and `\'` within strings
- **Multiple spaces**: Properly handled as separators
- **Mixed quotes**: Support for both single and double quotes

### Examples of Raw Parameter Strings

```dart
// Simple flags and values
rawParameters: '-v -f input.txt -o output.txt'

// Arguments with spaces (quoted)
rawParameters: '-f "file with spaces.txt" -d "output directory"'

// Mixed quotes and escaping
rawParameters: '-m "It\'s working" -n \'Say "Hello"\'  -v'

// Complex combinations
rawParameters: '--input-file=/path/to/file --output-dir="./build dir" --verbose'
```

### Safety Features

- **Argument escaping**: All arguments are automatically escaped for shell safety
- **Quote handling**: Proper handling of nested quotes and escape sequences
- **Validation**: Automatic validation of parameter syntax

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

### Scripts with Raw Parameter Support

When using `allowRawParameters: true`, your scripts can handle both typed and raw parameters:

```bash
#!/bin/bash
# scripts/flexible_script.sh

# Initialize variables
VERBOSE=false
INPUT_FILE=""
OUTPUT_DIR=""
FORMAT="txt"

# Handle all parameters including raw ones
while getopts "i:o:f:v-:" opt; do
  case $opt in
    i) INPUT_FILE="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    f) FORMAT="$OPTARG" ;;
    v) VERBOSE=true ;;
    -) 
      # Handle long options passed via raw parameters
      case "$OPTARG" in
        format=*) FORMAT="${OPTARG#*=}" ;;
        verbose) VERBOSE=true ;;
        input-file=*) INPUT_FILE="${OPTARG#*=}" ;;
        output-dir=*) OUTPUT_DIR="${OPTARG#*=}" ;;
        *) echo "Unknown long option: --$OPTARG" >&2; exit 1 ;;
      esac
      ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

# Your script logic here
```

## Best Practices

### When to Use Raw Parameters

- **Complex command-line tools**: When you need to pass many options that change frequently
- **Long option support**: For scripts that use `--long-option` style parameters
- **Dynamic parameter sets**: When the set of parameters is determined at runtime
- **Third-party tool integration**: When wrapping existing command-line tools

### When to Use Typed Parameters

- **Fixed API**: When your script has a stable set of parameters
- **Type safety**: When you want compile-time checking of parameter names
- **Documentation**: When you want clear parameter documentation in your Dart code
- **Simple scripts**: For scripts with a small, well-defined set of parameters

### Combining Both Approaches

```dart
@ShellScript(
  fileName: 'hybrid.sh',
  parameters: [
    // Core required parameters as typed
    ShellParameter(flag: 'i', name: 'input', required: true),
    ShellParameter(flag: 'o', name: 'output', required: true),
  ],
  allowRawParameters: true,  // Additional options as raw
)
void hybridScript() {}

// Usage:
final script = scripts.getHybridScript(
  input: '/required/input',
  output: '/required/output',
  rawParameters: '--format json --compress --threads 4 --verbose',
);
```

## Troubleshooting

### Common Errors

1. **Script not found**: Make sure the `scriptsPath` is set correctly relative to the project root

2. **Incorrect generation**: Check that all methods with `@ShellScript` have corresponding `.sh` files

3. **Parameter errors**: Make sure the flags in `ShellParameter` match the flags in `getopts`

4. **Raw parameter parsing issues**: 
   - Ensure quotes are properly balanced in raw parameter strings
   - Use escaping for special characters: `\"` and `\'`
   - Check that parameter syntax matches your script's `getopts` pattern

5. **Stale generated code**: If you renamed script files but didn't update annotations:
   - Update the `fileName` in `@ShellScript` annotations
   - Run `dart run build_runner clean` then `dart run build_runner build`
   - Check build output for warnings about missing files

### Raw Parameter Debugging

If raw parameters aren't working as expected:

1. **Check quote balance**: Ensure all quotes are properly opened and closed
2. **Verify escaping**: Make sure special characters are properly escaped
3. **Test parameter parsing**: Use simple parameters first, then add complexity
4. **Check script compatibility**: Ensure your script handles the generated parameters correctly