import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HT_Interpreter();

  hetu.eval(r'''
      fun main {
        print(System.now)
      }
      ''', invokeFunc: 'main');
}
