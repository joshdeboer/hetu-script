import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: '../../script/');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  final result = hetu.evalFile('import_test2.hts', invokeFunc: 'main');
  print(result);

  // final result2 = hetu.evalFile('import_test.ht', invokeFunc: 'importTest');
  // print(result2);

  // final result3 = hetu.evalFile('mod.ht', invokeFunc: 'modTest');
  // print(result3);
}
