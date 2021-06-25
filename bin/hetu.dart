import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:args/args.dart';

import 'package:hetu_script/hetu_script.dart';

const cli_help = r'''
Hetu Script Command-line Tool
Version: 0.1.0
Usage:
hetu [command] [command_args]
  command:
    fmt [path]
      to format a script file.
      --script(-s)
      --print(-p)
      --out(-o) [outpath]
    run [path]
      to run a script file.
      --script(-s)
hetu [option]
  option:
    --help(-h)
''';

const repl_info = r'''
Hetu Script Read-Evaluate-Print-Loop Tool
Version: 0.1.0
Enter expression to evaluate.
Enter '\' for multiline, enter '.exit' to quit.''';

final hetu = Hetu(
    config: InterpreterConfig(
        sourceType: SourceType.script, scriptStackTrace: false));

void main(List<String> arguments) async {
  try {
    await hetu.init();

    if (arguments.isEmpty) {
      print(repl_info);
      var exit = false;

      while (!exit) {
        stdout.write('>>>');
        var input = stdin.readLineSync();

        if (input == '.exit') {
          exit = true;
        } else {
          if (input!.endsWith('\\')) {
            input += '\n' + stdin.readLineSync()!;
          }
          try {
            final result = await hetu.eval(input);
            print(result);
          } catch (e) {
            if (e is HTError) {
              print(e.message);
            } else {
              print(e);
            }
          }
        }
      }
    } else {
      final results = parseArg(arguments);
      if (results['help']) {
        print(cli_help);
      } else if (results.command != null) {
        final cmd = results.command!;
        final cmdArgs = cmd.arguments;

        final targetPath = cmdArgs.first;
        if (path.extension(targetPath) != '.ht') {
          throw 'Error: target file extension is not \'.ht\'';
        }

        final sourceType =
            cmd['script'] ? SourceType.script : SourceType.module;

        switch (cmd.name) {
          case 'run':
            await run(cmdArgs, sourceType);
            break;
          case 'fmt':
            format(cmdArgs, cmd['out'], cmd['print']);
            break;
        }
      } else {
        await run(arguments);
      }
    }
  } catch (e) {
    print(e);
  }
}

Future<void> run(List<String> args,
    [SourceType sourceType = SourceType.script]) async {
  dynamic result;
  final config = InterpreterConfig(sourceType: sourceType);
  hetu.config = config;
  if (args.length == 1) {
    result = await hetu.evalFile(args.first);
  } else {
    result = await hetu.evalFile(args.first, invokeFunc: args[1]);
  }
  print('Execution result:');
  print(result);
}

void format(List<String> args, [String? outPath, bool printResult = true]) {
  final parser = HTAstParser();
  final formatter = HTFormatter();
  final sourceProvider = DefaultSourceProvider();
  final source = sourceProvider.getSourceSync(args.first);

  try {
    // final config = ParserConfig(sourceType: sourceType);
    final compilation = parser.parseToCompilation(source); //, config);

    final module = compilation.getModule(source.fullName);

    final fmtResult = formatter.format(module.nodes);

    if (printResult) {
      print(fmtResult);
    }

    if (outPath != null) {
      if (!path.isAbsolute(outPath)) {
        final curPath = path.dirname(source.fullName);
        final name = path.basenameWithoutExtension(outPath);
        outPath = path.join(curPath, '$name.ht');
      }
    } else {
      outPath = module.fullName;
    }

    final outFile = File(outPath);
    outFile.writeAsStringSync(fmtResult);

    print('Saved formatted file to:');
    print(outPath);
  } catch (e) {
    if (e is HTError && e.type == ErrorType.compileTimeError) {
      e.moduleFullName = parser.curModuleFullName;
      e.line = parser.curLine;
      e.column = parser.curColumn;
    }
    rethrow;
  }
}

ArgResults parseArg(List<String> args) {
  final parser = ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false);
  final runCmd = parser.addCommand('run');
  runCmd.addFlag('script', abbr: 's');
  final fmtCmd = parser.addCommand('fmt');
  fmtCmd.addFlag('script');
  fmtCmd.addFlag('print', abbr: 'p');
  fmtCmd.addOption('out', abbr: 'o');

  return parser.parse(args);
}
