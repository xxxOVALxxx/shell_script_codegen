import 'dart:io';
import 'package:shell_script_codegen/shell_script_codegen.dart';

part 'shell_script_codegen_example.g.dart';

/// Test class to demonstrate main functionality
@ShellScripts(
  scriptsPath: 'assets/scripts/scripts',
  enableParameters: true,
  methodPrefix: 'get',
)
class SystemShell {
  /// Get system information
  @ShellScript(
    fileName: 'system_info.sh',
    allowRawParameters: true,
  )
  void systemInfo() {}

  /// Clean temporary files
  @ShellScript(
    fileName: 'cleanup.sh',
    parameters: [
      ShellParameter(
        flag: 'd',
        name: 'directory',
        required: true,
      ),
      ShellParameter(
        flag: 'r',
        name: 'recursive',
        type: ParameterType.flag,
      ),
    ],
  )
  void cleanup() {}

  /// Create a backup
  @ShellScript(
    fileName: 'backup.sh',
    parameters: [
      ShellParameter(
        flag: 's',
        name: 'source',
        required: true,
      ),
      ShellParameter(
        flag: 't',
        name: 'target',
        required: true,
      ),
      ShellParameter(
        flag: 'c',
        name: 'compress',
        type: ParameterType.flag,
      ),
    ],
  )
  void backup() {}
}

/// Simple class without parameters
@ShellScripts(
  scriptsPath: 'assets/scripts/simple_scripts',
  enableParameters: false,
  methodPrefix: 'script',
)
class Simple {
  @ShellScript(fileName: 'hello.sh')
  void hello() {}

  @ShellScript(fileName: 'current_date.sh')
  void currentDate() {}
}

/// Class for developer utilities
@ShellScripts(
  scriptsPath: 'assets/scripts/dev_scripts',
  methodPrefix: 'run',
)
class Developer {
  @ShellScript(
    fileName: 'git_status.sh',
    parameters: [
      ShellParameter(
        flag: 'b',
        name: 'branch',
        type: ParameterType.flag,
      ),
    ],
  )
  void gitStatus() {}

  @ShellScript(
    fileName: 'build_project.sh',
    parameters: [
      ShellParameter(
        flag: 'e',
        name: 'environment',
        defaultValue: 'development',
      ),
      ShellParameter(
        flag: 'c',
        name: 'clean',
        type: ParameterType.flag,
      ),
    ],
  )
  void buildProject() {}
}

void main(List<String> arguments) async {
  print('🚀 Shell Script CodeGen Test CLI');
  print('==================================\n');

  if (arguments.isEmpty) {
    showHelp();
    return;
  }

  final command = arguments[0];

  switch (command) {
    case 'demo':
      await runDemo();
      break;
    case 'system':
      await runSystemScripts(arguments.skip(1).toList());
      break;
    case 'simple':
      await runSimpleScripts(arguments.skip(1).toList());
      break;
    case 'dev':
      await runDevScripts(arguments.skip(1).toList());
      break;
    case 'test':
      await runTests();
      break;
    case 'help':
    case '--help':
    case '-h':
      showHelp();
      break;
    default:
      print('❌ Unknown command: $command');
      print('Use "help" to see available commands.\n');
      showHelp();
  }
}

void showHelp() {
  print('''
Available commands:

📋 demo     - Run all demonstrations
🖥️  system   - Test system scripts
📄 simple   - Test simple scripts (without parameters)
🛠️  dev      - Test developer scripts
🧪 test     - Run all tests
❓ help     - Show this help

Examples:
  dart run lib/shell_script_codegen_example.dart demo
  dart run lib/shell_script_codegen_example.dart system info --verbose
  dart run lib/shell_script_codegen_example.dart simple hello
  dart run lib/shell_script_codegen_example.dart dev git-status --branch
  dart run lib/shell_script_codegen_example.dart test
''');
}

Future<void> runDemo() async {
  print('🎯 Running Full Demo\n');

  // Demo 1: System Scripts with parameters
  print('1️⃣ System Scripts Demo:');
  print('─' * 30);

  final systemScripts = SystemShellScripts.instance;

  // Test system info with parameters
  print('📊 System Info (verbose):');
  final systemInfoScript =
      systemScripts.getSystemInfo(rawParameters: '-v -f json');
  print('Generated script:');
  _printScript(systemInfoScript);

  // Test cleanup
  print('\n🧹 Cleanup Script:');
  final cleanupScript =
      systemScripts.getCleanup(directory: '/tmp', recursive: true);
  print('Generated script:');
  _printScript(cleanupScript);

  // Demo 2: Simple Scripts
  print('\n2️⃣ Simple Scripts Demo:');
  print('─' * 30);

  final simpleScripts = SimpleScripts.instance;

  print('👋 Hello Script:');
  _printScript(simpleScripts.scriptHello);

  print('\n📅 Current Date Script:');
  _printScript(simpleScripts.scriptCurrentDate);

  // Demo 3: Developer Scripts
  print('\n3️⃣ Developer Scripts Demo:');
  print('─' * 30);

  final devTools = DeveloperScripts.instance;

  print('📋 Git Status (with branch info):');
  final gitScript = devTools.runGitStatus(branch: true);
  print('Generated script:');
  _printScript(gitScript);

  print('\n🔨 Build Project (production, clean):');
  final buildScript =
      devTools.runBuildProject(environment: 'production', clean: true);
  print('Generated script:');
  _printScript(buildScript);

  print('\n✅ Demo completed successfully!');
}

Future<void> runSystemScripts(List<String> args) async {
  print('🖥️ System Scripts Test\n');

  final scripts = SystemShellScripts.instance;

  if (args.isEmpty) {
    print('Available system commands:');
    print('• info [--verbose] [--format=FORMAT]');
    print('• cleanup --directory=DIR [--recursive]');
    print('• backup --source=SRC --target=TGT [--compress]');
    return;
  }

  final command = args[0];

  switch (command) {
    case 'info':
      final verbose = args.contains('--verbose');
      final formatArg = args.firstWhere(
        (arg) => arg.startsWith('--format='),
        orElse: () => '--format=plain',
      );
      final format = formatArg.split('=')[1];

      final script = scripts.getSystemInfo(
          rawParameters: '${verbose ? '-v ' : ''}-f $format');
      print('🔍 Generated System Info Script:');
      _printScript(script);
      await _executeScript(script, 'system_info');
      break;

    case 'cleanup':
      final dirArg = args.firstWhere(
        (arg) => arg.startsWith('--directory='),
        orElse: () => '',
      );

      if (dirArg.isEmpty) {
        print('❌ Error: --directory parameter is required');
        return;
      }

      final directory = dirArg.split('=')[1];
      final recursive = args.contains('--recursive');

      final script =
          scripts.getCleanup(directory: directory, recursive: recursive);
      print('🧹 Generated Cleanup Script:');
      _printScript(script);
      await _executeScript(script, 'cleanup');
      break;

    default:
      print('❌ Unknown system command: $command');
  }
}

Future<void> runSimpleScripts(List<String> args) async {
  print('📄 Simple Scripts Test\n');

  final scripts = SimpleScripts.instance;

  if (args.isEmpty) {
    print('Available simple commands:');
    print('• hello');
    print('• date');
    return;
  }

  final command = args[0];

  switch (command) {
    case 'hello':
      print('👋 Hello Script:');
      _printScript(scripts.scriptHello);
      await _executeScript(scripts.scriptHello, 'hello');
      break;

    case 'date':
      print('📅 Current Date Script:');
      _printScript(scripts.scriptCurrentDate);
      await _executeScript(scripts.scriptCurrentDate, 'current_date');
      break;

    default:
      print('❌ Unknown simple command: $command');
  }
}

Future<void> runDevScripts(List<String> args) async {
  print('🛠️ Developer Scripts Test\n');

  final devTools = DeveloperScripts.instance;

  if (args.isEmpty) {
    print('Available dev commands:');
    print('• git-status [--branch]');
    print('• build [--environment=ENV] [--clean]');
    return;
  }

  final command = args[0];

  switch (command) {
    case 'git-status':
      final branch = args.contains('--branch');
      final script = devTools.runGitStatus(branch: branch);
      print('📋 Generated Git Status Script:');
      _printScript(script);
      await _executeScript(script, 'git_status');
      break;

    case 'build':
      final envArg = args.firstWhere(
        (arg) => arg.startsWith('--environment='),
        orElse: () => '--environment=development',
      );
      final environment = envArg.split('=')[1];
      final clean = args.contains('--clean');

      final script =
          devTools.runBuildProject(environment: environment, clean: clean);
      print('🔨 Generated Build Script:');
      _printScript(script);
      await _executeScript(script, 'build_project');
      break;

    default:
      print('❌ Unknown dev command: $command');
  }
}

Future<void> runTests() async {
  print('🧪 Running All Tests\n');

  var testsPassed = 0;
  var testsFailed = 0;

  // Test 1: Parameter generation
  print('Test 1: Parameter Generation');
  try {
    final scripts = SystemShellScripts.instance;
    final script = scripts.getSystemInfo(
      rawParameters: '-v -f json',
    );

    if (script.contains('set -- ') &&
        script.contains("'-v'") &&
        script.contains("'-f'")) {
      print('✅ PASSED: Parameters correctly injected');
      testsPassed++;
    } else {
      print('❌ FAILED: Parameters not found in generated script');
      testsFailed++;
    }
  } catch (e) {
    print('❌ FAILED: Exception occurred - $e');
    testsFailed++;
  }

  // Test 2: Simple script generation
  print('\nTest 2: Simple Script Generation');
  try {
    final simpleScripts = SimpleScripts.instance;
    final script = simpleScripts.scriptHello;

    if (script.isNotEmpty && !script.contains('set -- ')) {
      print('✅ PASSED: Simple script generated without parameters');
      testsPassed++;
    } else {
      print('❌ FAILED: Simple script generation issue');
      testsFailed++;
    }
  } catch (e) {
    print('❌ FAILED: Exception occurred - $e');
    testsFailed++;
  }

  // Test 3: Method naming
  print('\nTest 3: Method Naming Convention');
  try {
    final devTools = DeveloperScripts.instance;
    final script = devTools.runGitStatus();

    if (script.isNotEmpty) {
      print('✅ PASSED: Method naming convention works');
      testsPassed++;
    } else {
      print('❌ FAILED: Method naming issue');
      testsFailed++;
    }
  } catch (e) {
    print('❌ FAILED: Exception occurred - $e');
    testsFailed++;
  }

  // Test 4: Required parameters validation
  print('\nTest 4: Required Parameters');
  try {
    final scripts = SystemShellScripts.instance;
    // This should work because directory is provided
    final script = scripts.getCleanup(directory: '/tmp');

    if (script.isNotEmpty) {
      print('✅ PASSED: Required parameters handled correctly');
      testsPassed++;
    } else {
      print('❌ FAILED: Required parameters issue');
      testsFailed++;
    }
  } catch (e) {
    print('❌ FAILED: Exception occurred - $e');
    testsFailed++;
  }

  // Summary
  print('\n📊 Test Results:');
  print('─' * 20);
  print('✅ Passed: $testsPassed');
  print('❌ Failed: $testsFailed');
  print('📈 Total:  ${testsPassed + testsFailed}');

  if (testsFailed == 0) {
    print('\n🎉 All tests passed!');
  } else {
    print('\n⚠️ Some tests failed. Check the output above for details.');
    exit(1);
  }
}

void _printScript(String script) {
  print('```bash');
  print(script);
  print('```\n');
}

Future<void> _executeScript(String script, String name) async {
  print('🔄 Executing script...');

  try {
    // Create temporary script file
    final tempFile =
        File('/tmp/test_${name}_${DateTime.now().millisecondsSinceEpoch}.sh');
    await tempFile.writeAsString(script);

    // Make executable
    await Process.run('chmod', ['+x', tempFile.path]);

    // Execute
    final result = await Process.run('bash', [tempFile.path]);

    if (result.exitCode == 0) {
      print('✅ Script executed successfully');
      if (result.stdout.toString().trim().isNotEmpty) {
        print('📤 Output:');
        print(result.stdout);
      }
    } else {
      print('❌ Script execution failed (exit code: ${result.exitCode})');
      if (result.stderr.toString().trim().isNotEmpty) {
        print('📤 Error:');
        print(result.stderr);
      }
    }

    // Cleanup
    await tempFile.delete();
  } catch (e) {
    print('❌ Failed to execute script: $e');
  }

  print('');
}
