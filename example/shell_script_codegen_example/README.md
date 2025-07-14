This example demonstrates how to use the `shell_script_codegen` package to generate Dart classes from shell script annotations.

## Quick Start

1. **Install dependencies:**
   ```bash
   dart pub get
   ```

2. **Generate code:**
   ```bash
   dart run build_runner build
   ```

3. **Run the example:**
   ```bash
   # Show help
   dart run lib/shell_script_codegen_example.dart help

   # Run full demo
   dart run lib/shell_script_codegen_example.dart demo

   # Test system scripts
   dart run lib/shell_script_codegen_example.dart system info --verbose --format=json

   # Test simple scripts
   dart run lib/shell_script_codegen_example.dart simple hello

   # Test developer scripts
   dart run lib/shell_script_codegen_example.dart dev git-status --branch

   # Run tests
   dart run lib/shell_script_codegen_example.dart test
   ```

## Examples Included

### 1. System Scripts (with parameters)
- **system_info.sh**: Get system information with verbose and format options
- **cleanup.sh**: Clean temporary files with directory and recursive options
- **backup.sh**: Create backups with source, target, and compression options

### 2. Simple Scripts (no parameters)
- **hello.sh**: Simple greeting script
- **current_date.sh**: Display current date and time

### 3. Developer Scripts
- **git_status.sh**: Show git repository status with optional branch info
- **build_project.sh**: Build project with environment and clean options

## Code Generation Features Demonstrated

- ✅ Parameter support with `getopts`
- ✅ Required and optional parameters
- ✅ Flag and value parameters
- ✅ Default values
- ✅ Method naming conventions
- ✅ Multiple annotation configurations
- ✅ Error handling


## Usage Examples

```bash
# System scripts with parameters
dart run lib/shell_script_codegen_example.dart system info --verbose --format=json
dart run lib/shell_script_codegen_example.dart system cleanup --directory=/tmp --recursive

# Simple scripts
dart run lib/shell_script_codegen_example.dart simple hello
dart run lib/shell_script_codegen_example.dart simple date

# Developer scripts
dart run lib/shell_script_codegen_example.dart dev git-status --branch
dart run lib/shell_script_codegen_example.dart dev build --environment=production --clean
```