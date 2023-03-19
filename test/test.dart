import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  final sourceContext = HTOverlayContext();
  var hetu = Hetu(
    config: HetuConfig(
      // printPerformanceStatistics: true,
      removeLineInfo: false,
      // doStaticAnalysis: true,
      // computeConstantExpression: true,
      showHetuStackTrace: true,
      showDartStackTrace: true,
      // stackTraceDisplayCountLimit: 20,
      allowVariableShadowing: true,
      allowImplicitVariableDeclaration: true,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
      checkTypeAnnotationAtRuntime: true,
      normalizeImportPath: false,
    ),
    sourceContext: sourceContext,
  );
  hetu.init(
    locale: HTLocaleSimplifiedChinese(),
  );

  final r = hetu.eval(r'''
    1
''');

  if (r is Future) {
    print(await r);
  } else {
    print(r);
  }
}
