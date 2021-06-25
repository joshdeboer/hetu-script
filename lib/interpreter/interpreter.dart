import 'dart:typed_data';

import '../binding/external_function.dart';
import '../declaration/namespace.dart';
import '../object/object.dart';
import '../declaration/declaration.dart';
import '../declaration/class/class.dart';
import '../declaration/class/enum.dart';
import '../declaration/class/cast.dart';
import '../declaration/function/parameter_declaration.dart';
import '../declaration/function/function.dart';
import '../declaration/function/parameter.dart';
import '../declaration/variable/variable.dart';
import '../scanner/abstract_parser.dart';
import '../scanner/parser.dart';
import '../type/type.dart';
import '../type/function_type.dart';
import '../type/nominal_type.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../source/source_provider.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import 'abstract_interpreter.dart';
import 'const_table.dart';
import 'compiler.dart';
import 'opcode.dart';
import 'bytecode_library.dart';

/// Mixin for classes that holds a ref of Interpreter
mixin HetuRef {
  late final Hetu interpreter;
}

class _LoopInfo {
  final int startIp;
  final int continueIp;
  final int breakIp;
  final HTNamespace namespace;
  _LoopInfo(this.startIp, this.continueIp, this.breakIp, this.namespace);
}

/// A bytecode implementation of a Hetu script interpreter
class Hetu extends AbstractInterpreter {
  static const verMajor = 0;
  static const verMinor = 1;
  static const verPatch = 0;

  final _compilation = <String, HTBytecodeLibrary>{};

  late InterpreterConfig _curConfig;

  @override
  InterpreterConfig get curConfig => _curConfig;

  var _curLine = 0;
  @override
  int get curLine => _curLine;

  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  late HTBytecodeLibrary _curLibrary;
  @override
  HTBytecodeLibrary get curLibrary => _curLibrary;

  HTClass? _curClass;
  HTFunction? _curFunction;

  var _regIndex = -1;
  final _registers =
      List<dynamic>.filled(HTRegIdx.length, null, growable: true);

  int _getRegIndex(int relative) => (_regIndex * HTRegIdx.length + relative);
  void _setRegVal(int index, dynamic value) =>
      _registers[_getRegIndex(index)] = value;
  dynamic _getRegVal(int index) => _registers[_getRegIndex(index)];
  set _curValue(dynamic value) =>
      _registers[_getRegIndex(HTRegIdx.value)] = value;
  dynamic get _curValue => _registers[_getRegIndex(HTRegIdx.value)];
  set _curSymbol(String? value) =>
      _registers[_getRegIndex(HTRegIdx.symbol)] = value;
  String? get curSymbol => _registers[_getRegIndex(HTRegIdx.symbol)];
  set _curLeftValue(dynamic value) =>
      _registers[_getRegIndex(HTRegIdx.leftValue)] = value;
  dynamic get curLeftValue =>
      _registers[_getRegIndex(HTRegIdx.leftValue)] ?? _curNamespace;
  // set _curRefType(_RefType value) =>
  //     _registers[_getRegIndex(HTRegIdx.refType)] = value;
  // _RefType get _curRefType =>
  //     _registers[_getRegIndex(HTRegIdx.refType)] ?? _RefType.normal;
  set _curTypeArgs(List<HTType> value) =>
      _registers[_getRegIndex(HTRegIdx.typeArgs)] = value;
  List<HTType> get _curTypeArgs =>
      _registers[_getRegIndex(HTRegIdx.typeArgs)] ?? const [];
  set _curLoopCount(int value) =>
      _registers[_getRegIndex(HTRegIdx.loopCount)] = value;
  int get _curLoopCount => _registers[_getRegIndex(HTRegIdx.loopCount)] ?? 0;
  set _curAnchor(int value) =>
      _registers[_getRegIndex(HTRegIdx.anchor)] = value;
  int get _curAnchor => _registers[_getRegIndex(HTRegIdx.anchor)] ?? 0;

  /// loop 信息以栈的形式保存
  /// break 指令将会跳回最近的一个 loop 的出口
  final _loops = <_LoopInfo>[];

  /// Create a bytecode interpreter.
  /// Each interpreter has a independent global [HTNamespace].
  Hetu(
      {HTErrorHandler? errorHandler,
      HTSourceProvider? sourceProvider,
      InterpreterConfig config = const InterpreterConfig()})
      : super(
            config: config,
            errorHandler: errorHandler,
            sourceProvider: sourceProvider) {
    _curNamespace = global;
  }

  /// Evaluate a string content.
  /// During this process, all declarations will
  /// be defined to current [HTNamespace].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  @override
  Future<dynamic> evalSource(HTSource source,
      {HTNamespace? namespace,
      InterpreterConfig? config,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) async {
    if (source.content.isEmpty) {
      return null;
    }
    _curConfig = config ?? this.config;
    _curModuleFullName = source.fullName;
    final hasOwnNamespace = namespace != global;
    final parser = HTAstParser(
        config: _curConfig,
        errorHandler: errorHandler,
        sourceProvider: sourceProvider);
    final compiler = HTCompiler(
        config: _curConfig,
        errorHandler: errorHandler,
        sourceProvider: sourceProvider);
    try {
      final compilation =
          parser.parseToCompilation(source, hasOwnNamespace: hasOwnNamespace);
      final bytes = compiler.compile(compilation, source.libraryName);
      _curLibrary = HTBytecodeLibrary(source.libraryName, bytes);

      var result;
      if (_curConfig.sourceType == SourceType.script) {
        HTNamespace nsp = execute(namespace: namespace ?? global);
        _curLibrary.define(nsp.id!, nsp);
        _compilation[_curLibrary.id] = _curLibrary;
        // every scripts shares each others declarations,
        // this is achieved by global namespace import from them
        global.import(nsp);
        // return the last expression's value
        result = _registers.first;
      } else if (_curConfig.sourceType == SourceType.module) {
        while (_curLibrary.ip < _curLibrary.bytes.length) {
          final HTNamespace nsp = execute();
          _curLibrary.define(nsp.id!, nsp);
        }
        _compilation[_curLibrary.id] = _curLibrary;

        if (hasOwnNamespace) {
          for (final module in compilation.modules.values) {
            final nsp = _curLibrary.declarations[module.fullName]!;
            for (final info in module.imports) {
              final importFullName =
                  sourceProvider.resolveFullName(info.key, module.fullName);
              final importNamespace = _curLibrary.declarations[importFullName]!;
              if (info.alias == null) {
                if (info.showList.isEmpty) {
                  nsp.import(importNamespace);
                } else {
                  for (final id in info.showList) {
                    HTDeclaration decl =
                        importNamespace.memberGet(id, recursive: false);
                    nsp.define(id, decl);
                  }
                }
              } else {
                if (info.showList.isEmpty) {
                  final aliasNamespace =
                      HTNamespace(id: info.alias!, closure: global);
                  aliasNamespace.import(importNamespace);
                  nsp.define(info.alias!, aliasNamespace);
                } else {
                  final aliasNamespace =
                      HTNamespace(id: info.alias!, closure: global);
                  for (final id in info.showList) {
                    HTDeclaration decl =
                        importNamespace.memberGet(id, recursive: false);
                    aliasNamespace.define(id, decl);
                  }
                  nsp.define(info.alias!, aliasNamespace);
                }
              }
            }
          }
        }

        for (final namespace in _curLibrary.declarations.values) {
          for (final decl in namespace.declarations.values) {
            decl.resolve();
          }
        }

        if (_curConfig.sourceType == SourceType.module && invokeFunc != null) {
          result = invoke(invokeFunc,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              errorHandled: true);
        }
      } else {
        throw HTError.sourceType();
      }

      return result;
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error,
            dartStackTrace: stackTrace, parser: parser, compiler: compiler);
      }
    }
  }

  /// Call a function within current [HTNamespace].
  @override
  dynamic invoke(String funcName,
      {String? classId,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      HTFunction func;
      if (classId != null) {
        HTClass klass = _curNamespace.memberGet(classId);
        func = klass.memberGet(funcName, recursive: false);
      } else {
        func = _curNamespace.memberGet(funcName);
      }
      if (func is HTFunction) {
        return func.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        HTError.notCallable(funcName);
      }
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, dartStackTrace: stackTrace);
      }
    }
  }

  /// Compile a script content into bytecode for later use.
  Future<Uint8List> compile(String content,
      {ParserConfigImpl config = const ParserConfigImpl()}) async {
    throw HTError(ErrorCode.extern, ErrorType.externalError,
        message: 'compile is currently unusable');
  }

  /// Load a pre-compiled bytecode in to module library.
  /// If [run] is true, then execute the bytecode immediately.
  dynamic load(Uint8List code, String libraryName,
      {bool import = true, bool run = false, int ip = 0}) {}

  /// Interpret a loaded module with the key of [moduleFullName]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current value when encountered [OpCode.endOfExec] or [OpCode.endOfFunc].
  /// If [moduleFullName] != null, will return to original [HTBytecodeModule] module.
  /// If [ip] != null, will return to original [_curLibrary.ip].
  /// If [namespace] != null, will return to original [HTNamespace]
  ///
  /// Once changed into a new module, will open a new area of register space
  /// Every register space holds its own temporary values.
  /// Such as currrent value, current symbol, current line & column, etc.
  dynamic execute(
      {String? moduleFullName,
      String? libraryName,
      HTNamespace? namespace,
      HTFunction? function,
      int? ip,
      int? line,
      int? column}) {
    final savedLibraryName = _curLibrary.id;
    final savedModuleFullName = _curModuleFullName;
    final savedIp = _curLibrary.ip;
    final savedNamespace = _curNamespace;
    final savedFunction = _curFunction;

    var codeChanged = false;
    var ipChanged = false;
    var namespaceChanged = false;
    var functionChanged = false;
    if (libraryName != null && (_curLibrary.id != libraryName)) {
      _curLibrary = _compilation[libraryName]!;
      codeChanged = true;
      ipChanged = true;
    }
    if (moduleFullName != null && (_curModuleFullName != moduleFullName)) {
      _curModuleFullName = moduleFullName;
    }
    if (ip != null && _curLibrary.ip != ip) {
      _curLibrary.ip = ip;
      ipChanged = true;
    }
    if (namespace != null && _curNamespace != namespace) {
      _curNamespace = namespace;
      namespaceChanged = true;
    }
    if (function != null && _curFunction != function) {
      _curFunction = function;
      functionChanged = true;
    }

    ++_regIndex;
    if (_registers.length <= _regIndex * HTRegIdx.length) {
      _registers.length += HTRegIdx.length;
    }
    _curLine = line ?? 0;
    _curColumn = column ?? 0;

    final result = _execute();

    if (codeChanged) {
      _curLibrary = _compilation[savedLibraryName]!;
    }
    if (namespaceChanged) {
      _curModuleFullName = savedModuleFullName;
    }
    if (ipChanged) {
      _curLibrary.ip = savedIp;
    }
    if (namespaceChanged) {
      _curNamespace = savedNamespace;
    }
    if (functionChanged) {
      _curFunction = savedFunction;
    }

    --_regIndex;

    return result;
  }

  dynamic _execute() {
    var instruction = _curLibrary.read();
    while (instruction != HTOpCode.endOfFile) {
      switch (instruction) {
        case HTOpCode.signature:
          _curLibrary.readUint32();
          break;
        case HTOpCode.version:
          final major = _curLibrary.read();
          final minor = _curLibrary.read();
          final patch = _curLibrary.readUint16();
          if (major != verMajor) {
            throw HTError.version(
                '$major.$minor.$patch', '$verMajor.$verMinor.$verPatch');
          }
          // _curCode.version = Version(major, minor, patch);
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          _storeLocal();
          break;
        // 将本地变量存入下一个字节代表的寄存器位置中
        case HTOpCode.register:
          final index = _curLibrary.read();
          _setRegVal(index, _curValue);
          break;
        case HTOpCode.skip:
          final distance = _curLibrary.readInt16();
          _curLibrary.ip += distance;
          break;
        case HTOpCode.anchor:
          _curAnchor = _curLibrary.ip;
          break;
        case HTOpCode.goto:
          final distance = _curLibrary.readInt16();
          _curLibrary.ip = _curAnchor + distance;
          break;
        case HTOpCode.module:
          final id = _curLibrary.readShortUtf8String();
          _curModuleFullName = id;
          _curNamespace = HTNamespace(id: id, closure: global);
          break;
        case HTOpCode.lineInfo:
          _curLine = _curLibrary.readUint16();
          _curColumn = _curLibrary.readUint16();
          break;
        case HTOpCode.loopPoint:
          final continueLength = _curLibrary.readUint16();
          final breakLength = _curLibrary.readUint16();
          _loops.add(_LoopInfo(_curLibrary.ip, _curLibrary.ip + continueLength,
              _curLibrary.ip + breakLength, _curNamespace));
          ++_curLoopCount;
          break;
        case HTOpCode.breakLoop:
          _curLibrary.ip = _loops.last.breakIp;
          _curNamespace = _loops.last.namespace;
          _loops.removeLast();
          --_curLoopCount;
          break;
        case HTOpCode.continueLoop:
          _curLibrary.ip = _loops.last.continueIp;
          _curNamespace = _loops.last.namespace;
          break;
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case HTOpCode.block:
          final id = _curLibrary.readShortUtf8String();
          _curNamespace = HTNamespace(id: id, closure: _curNamespace);
          break;
        case HTOpCode.endOfBlock:
          _curNamespace = _curNamespace.closure!;
          break;
        // 语句结束
        case HTOpCode.endOfStmt:
          _curValue = null;
          _curSymbol = null;
          _curLeftValue = null;
          _curTypeArgs = [];
          break;
        case HTOpCode.endOfExec:
          return _curValue;
        case HTOpCode.endOfFunc:
          final loopCount = _curLoopCount;
          for (var i = 0; i < loopCount; ++i) {
            _loops.removeLast();
          }
          _curLoopCount = 0;
          return _curValue;
        case HTOpCode.endOfModule:
          return _curNamespace;
        case HTOpCode.constTable:
          final int64Length = _curLibrary.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            _curLibrary.addInt(_curLibrary.readInt64());
          }
          final float64Length = _curLibrary.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            _curLibrary.addFloat(_curLibrary.readFloat64());
          }
          final utf8StringLength = _curLibrary.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            _curLibrary.addString(_curLibrary.readUtf8String());
          }
          break;
        case HTOpCode.typeAliasDecl:
          _handleTypeAliasDecl();
          break;
        case HTOpCode.enumDecl:
          _handleEnumDecl();
          break;
        case HTOpCode.funcDecl:
          _handleFuncDecl();
          break;
        case HTOpCode.classDecl:
          _handleClassDecl();
          break;
        case HTOpCode.varDecl:
          _handleVarDecl();
          break;
        case HTOpCode.ifStmt:
          bool condition = _curValue;
          final thenBranchLength = _curLibrary.readUint16();
          if (!condition) {
            _curLibrary.skip(thenBranchLength);
          }
          break;
        case HTOpCode.whileStmt:
          if (!_curValue) {
            _curLibrary.ip = _loops.last.breakIp;
            _loops.removeLast();
            --_curLoopCount;
          }
          break;
        case HTOpCode.doStmt:
          final hasCondition = _curLibrary.readBool();
          if (hasCondition && _curValue) {
            _curLibrary.ip = _loops.last.startIp;
          }
          break;
        case HTOpCode.whenStmt:
          _handleWhenStmt();
          break;
        case HTOpCode.assign:
          final value = _getRegVal(HTRegIdx.assign);
          _curNamespace.memberSet(curSymbol!, value);
          _curValue = value;
          break;
        case HTOpCode.memberSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final key = _getRegVal(HTRegIdx.postfixKey);
          final encap = encapsulate(object);
          encap.memberSet(key, _curValue);
          break;
        case HTOpCode.subSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final key = execute();
          final value = execute();
          if (object == null || object == HTObject.NULL) {
            // TODO: object symbol?
            throw HTError.nullObject(object);
          }
          if ((object is List) || (object is Map)) {
            object[key] = value;
          } else if (object is HTObject) {
            object.subSet(key, value);
          } else {
            final typeString = object.runtimeType.toString();
            final id = HTType.parseBaseType(typeString);
            final externClass = fetchExternalClass(id);
            externClass.instanceSubSet(object, key!, value);
          }
          _curValue = value;
          break;
        case HTOpCode.logicalOr:
        case HTOpCode.logicalAnd:
        case HTOpCode.equal:
        case HTOpCode.notEqual:
        case HTOpCode.lesser:
        case HTOpCode.greater:
        case HTOpCode.lesserOrEqual:
        case HTOpCode.greaterOrEqual:
        case HTOpCode.typeAs:
        case HTOpCode.typeIs:
        case HTOpCode.typeIsNot:
        case HTOpCode.add:
        case HTOpCode.subtract:
        case HTOpCode.multiply:
        case HTOpCode.devide:
        case HTOpCode.modulo:
          _handleBinaryOp(instruction);
          break;
        case HTOpCode.negative:
        case HTOpCode.logicalNot:
        case HTOpCode.typeOf:
          _handleUnaryPrefixOp(instruction);
          break;
        case HTOpCode.memberGet:
        case HTOpCode.subGet:
        case HTOpCode.call:
          _handleUnaryPostfixOp(instruction);
          break;
        default:
          throw HTError.unknownOpCode(instruction);
      }

      instruction = _curLibrary.read();
    }
  }

  // void _resolve() {}

  void _storeLocal() {
    final valueType = _curLibrary.read();
    switch (valueType) {
      case HTValueTypeCode.NULL:
        _curValue = null;
        break;
      case HTValueTypeCode.boolean:
        (_curLibrary.read() == 0) ? _curValue = false : _curValue = true;
        break;
      case HTValueTypeCode.constInt:
        final index = _curLibrary.readUint16();
        _curValue = _curLibrary.getInt64(index);
        break;
      case HTValueTypeCode.constFloat:
        final index = _curLibrary.readUint16();
        _curValue = _curLibrary.getFloat64(index);
        break;
      case HTValueTypeCode.constString:
        final index = _curLibrary.readUint16();
        _curValue = _curLibrary.getUtf8String(index);
        break;
      case HTValueTypeCode.stringInterpolation:
        var literal = _curLibrary.readUtf8String();
        final interpolationLength = _curLibrary.read();
        for (var i = 0; i < interpolationLength; ++i) {
          final value = execute();
          literal = literal.replaceAll('{$i}', value.toString());
        }
        _curValue = literal;
        break;
      case HTValueTypeCode.symbol:
        final symbol = _curSymbol = _curLibrary.readShortUtf8String();
        final isLocal = _curLibrary.readBool();
        if (isLocal) {
          _curValue = _curNamespace.memberGet(symbol);
          _curLeftValue = _curNamespace;
        } else {
          _curValue = symbol;
        }
        final hasTypeArgs = _curLibrary.readBool();
        if (hasTypeArgs) {
          final typeArgsLength = _curLibrary.read();
          final typeArgs = <HTType>[];
          for (var i = 0; i < typeArgsLength; ++i) {
            final arg = _handleTypeExpr();
            typeArgs.add(arg);
          }
          _curTypeArgs = typeArgs;
        }
        break;
      case HTValueTypeCode.group:
        _curValue = execute();
        break;
      case HTValueTypeCode.list:
        final list = [];
        final length = _curLibrary.readUint16();
        for (var i = 0; i < length; ++i) {
          final listItem = execute();
          list.add(listItem);
        }
        _curValue = list;
        break;
      case HTValueTypeCode.map:
        final map = {};
        final length = _curLibrary.readUint16();
        for (var i = 0; i < length; ++i) {
          final key = execute();
          final value = execute();
          map[key] = value;
        }
        _curValue = map;
        break;
      case HTValueTypeCode.function:
        final internalName = _curLibrary.readShortUtf8String();
        final hasExternalTypedef = _curLibrary.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = _curLibrary.readShortUtf8String();
        }

        final hasParamDecls = _curLibrary.readBool();
        final isVariadic = _curLibrary.readBool();
        final minArity = _curLibrary.read();
        final maxArity = _curLibrary.read();
        final paramDecls = _getParams(_curLibrary.read());

        int? line, column, definitionIp;
        final hasDefinition = _curLibrary.readBool();

        if (hasDefinition) {
          line = _curLibrary.readUint16();
          column = _curLibrary.readUint16();
          final length = _curLibrary.readUint16();
          definitionIp = _curLibrary.ip;
          _curLibrary.skip(length);
        }

        final func = HTFunction(
            internalName, _curModuleFullName, _curLibrary.id, this,
            closure: _curNamespace,
            definitionIp: definitionIp,
            definitionLine: line,
            definitionColumn: column,
            category: FunctionCategory.literal,
            externalTypeId: externalTypedef,
            isVariadic: isVariadic,
            hasParamDecls: hasParamDecls,
            paramDecls: paramDecls,
            minArity: minArity,
            maxArity: maxArity,
            context: _curNamespace);

        if (!hasExternalTypedef) {
          _curValue = func;
        } else {
          final externalFunc = unwrapExternalFunctionType(func);
          _curValue = externalFunc;
        }
        // } else {
        //   _curValue = HTFunctionType(
        //       parameterTypes:
        //           paramDecls.values.map((param) => param.declType).toList(),
        //       returnType: returnType);
        // }

        break;
      case HTValueTypeCode.type:
        _curValue = _handleTypeExpr();
        break;
      default:
        throw HTError.unkownValueType(valueType);
    }
  }

  void _handleWhenStmt() {
    var condition = _curValue;
    final hasCondition = _curLibrary.readBool();

    final casesCount = _curLibrary.read();
    final branchesIpList = <int>[];
    final cases = <dynamic, int>{};
    for (var i = 0; i < casesCount; ++i) {
      branchesIpList.add(_curLibrary.readUint16());
    }
    final elseBranchIp = _curLibrary.readUint16();
    final endIp = _curLibrary.readUint16();

    for (var i = 0; i < casesCount; ++i) {
      final value = execute();
      cases[value] = branchesIpList[i];
    }

    if (hasCondition) {
      if (cases.containsKey(condition)) {
        final distance = cases[condition]!;
        _curLibrary.skip(distance);
      } else if (elseBranchIp > 0) {
        _curLibrary.skip(elseBranchIp);
      } else {
        _curLibrary.skip(endIp);
      }
    } else {
      var condition = false;
      for (final key in cases.keys) {
        if (key) {
          final distance = cases[key]!;
          _curLibrary.skip(distance);
          condition = true;
          break;
        }
      }
      if (!condition) {
        if (elseBranchIp > 0) {
          _curLibrary.skip(elseBranchIp);
        } else {
          _curLibrary.skip(endIp);
        }
      }
    }
  }

  void _handleBinaryOp(int opcode) {
    switch (opcode) {
      case HTOpCode.logicalOr:
        final bool leftValue = _getRegVal(HTRegIdx.andLeft);
        final rightValueLength = _curLibrary.readUint16();
        if (leftValue) {
          _curLibrary.skip(rightValueLength);
          _curValue = true;
        } else {
          final bool rightValue = execute();
          _curValue = rightValue;
        }
        break;
      case HTOpCode.logicalAnd:
        final bool leftValue = _getRegVal(HTRegIdx.andLeft);
        final rightValueLength = _curLibrary.readUint16();
        if (leftValue) {
          final bool rightValue = execute();
          _curValue = leftValue && rightValue;
        } else {
          _curLibrary.skip(rightValueLength);
          _curValue = false;
        }
        break;
      case HTOpCode.equal:
        final left = _getRegVal(HTRegIdx.equalLeft);
        _curValue = left == _curValue;
        break;
      case HTOpCode.notEqual:
        final left = _getRegVal(HTRegIdx.equalLeft);
        _curValue = left != _curValue;
        break;
      case HTOpCode.lesser:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _curValue = left < _curValue;
        break;
      case HTOpCode.greater:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _curValue = left > _curValue;
        break;
      case HTOpCode.lesserOrEqual:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _curValue = left <= _curValue;
        break;
      case HTOpCode.greaterOrEqual:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _curValue = left >= _curValue;
        break;
      case HTOpCode.typeAs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final HTType type = _curValue;
        final HTClass klass = curNamespace.memberGet(type.id);
        _curValue = HTCast(object, klass, this);
        break;
      case HTOpCode.typeIs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final HTType type = _curValue;
        final encapsulated = encapsulate(object);
        _curValue = encapsulated.valueType.isA(type);
        break;
      case HTOpCode.typeIsNot:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final HTType type = _curValue;
        final encapsulated = encapsulate(object);
        _curValue = encapsulated.valueType.isNotA(type);
        break;
      case HTOpCode.add:
        _curValue = _getRegVal(HTRegIdx.addLeft) + _curValue;
        break;
      case HTOpCode.subtract:
        _curValue = _getRegVal(HTRegIdx.addLeft) - _curValue;
        break;
      case HTOpCode.multiply:
        _curValue = _getRegVal(HTRegIdx.multiplyLeft) * _curValue;
        break;
      case HTOpCode.devide:
        _curValue = _getRegVal(HTRegIdx.multiplyLeft) / _curValue;
        break;
      case HTOpCode.modulo:
        _curValue = _getRegVal(HTRegIdx.multiplyLeft) % _curValue;
        break;
    }
  }

  void _handleUnaryPrefixOp(int op) {
    final object = _curValue;
    switch (op) {
      case HTOpCode.negative:
        _curValue = -object;
        break;
      case HTOpCode.logicalNot:
        _curValue = !object;
        break;
      case HTOpCode.typeOf:
        final encap = encapsulate(object);
        _curValue = encap.valueType;
        break;
    }
  }

  void _handleCallExpr() {
    var callee = _getRegVal(HTRegIdx.postfixObject);

    final positionalArgs = [];
    final positionalArgsLength = _curLibrary.read();
    for (var i = 0; i < positionalArgsLength; ++i) {
      final arg = execute();
      // final arg = execute(moveRegIndex: true);
      positionalArgs.add(arg);
    }

    final namedArgs = <String, dynamic>{};
    final namedArgsLength = _curLibrary.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = _curLibrary.readShortUtf8String();
      final arg = execute();
      // final arg = execute(moveRegIndex: true);
      namedArgs[name] = arg;
    }

    final typeArgs = _curTypeArgs;

    if (callee is HTFunction) {
      _curValue = callee.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    }
    // calle is a dart function
    else if (callee is Function) {
      if (callee is HTExternalFunction) {
        _curValue = callee(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        _curValue = Function.apply(
            callee,
            positionalArgs,
            namedArgs.map<Symbol, dynamic>(
                (key, value) => MapEntry(Symbol(key), value)));
      }
    } else if ((callee is HTClass) || (callee is HTType)) {
      late HTClass klass;
      if (callee is HTType) {
        final resolvedType = callee.resolve(_curNamespace);
        if (resolvedType is! HTNominalType) {
          throw HTError.notCallable(callee.toString());
        }
        klass = resolvedType.klass as HTClass;
      } else {
        klass = callee;
      }

      if (klass.isAbstract) {
        throw HTError.abstracted();
      }

      if (!klass.isExternal) {
        final constructor =
            klass.memberGet(SemanticNames.constructor) as HTFunction;
        _curValue = constructor.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        final constructor = klass.memberGet(callee.internalName) as HTFunction;
        _curValue = constructor.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      }
    } else {
      throw HTError.notCallable(callee.toString());
    }
  }

  void _handleUnaryPostfixOp(int op) {
    switch (op) {
      case HTOpCode.memberGet:
        final object = _getRegVal(HTRegIdx.postfixObject);
        final key = _getRegVal(HTRegIdx.postfixKey);
        final encap = encapsulate(object);
        _curLeftValue = encap;
        _curValue = encap.memberGet(key);
        break;
      case HTOpCode.subGet:
        final object = _getRegVal(HTRegIdx.postfixObject);
        _curLeftValue = object;
        final key = execute();
        // final key = execute(moveRegIndex: true);
        _setRegVal(HTRegIdx.postfixKey, key);
        if (object is HTObject) {
          _curValue = object.subGet(key);
        } else {
          _curValue = object[key];
        }
        // _curRefType = _RefType.sub;
        break;
      case HTOpCode.call:
        _handleCallExpr();
        break;
    }
  }

  HTType _handleTypeExpr() {
    final index = _curLibrary.read();
    final typeType = TypeType.values.elementAt(index);

    switch (typeType) {
      case TypeType.normal:
        final typeName = _curLibrary.readShortUtf8String();
        final typeArgsLength = _curLibrary.read();
        final typeArgs = <HTType>[];
        for (var i = 0; i < typeArgsLength; ++i) {
          typeArgs.add(_handleTypeExpr());
        }
        final isNullable = (_curLibrary.read() == 0) ? false : true;
        return HTType(typeName, typeArgs: typeArgs, isNullable: isNullable);
      case TypeType.function:
        final paramsLength = _curLibrary.read();
        final parameterTypes = <HTParameterDeclaration>[];
        for (var i = 0; i < paramsLength; ++i) {
          final typeId = _curLibrary.readShortUtf8String();
          final typeArgLength = _curLibrary.read();
          final typeArgs = <HTType>[];
          for (var i = 0; i < typeArgLength; ++i) {
            typeArgs.add(_handleTypeExpr());
          }
          final isNullable = _curLibrary.read() == 0 ? false : true;
          final isOptional = _curLibrary.read() == 0 ? false : true;
          final isNamed = _curLibrary.read() == 0 ? false : true;
          String? paramId;
          if (isNamed) {
            paramId = _curLibrary.readShortUtf8String();
          }
          final isVariadic = _curLibrary.read() == 0 ? false : true;
          final decl = HTParameterDeclaration(paramId ?? '',
              declType:
                  HTType(typeId, typeArgs: typeArgs, isNullable: isNullable),
              isOptional: isOptional,
              isNamed: isNamed,
              isVariadic: isVariadic);
          parameterTypes.add(decl);
        }
        final returnType = _handleTypeExpr();
        return HTFunctionType(
            parameterDeclarations: parameterTypes, returnType: returnType);
      case TypeType.struct:
      case TypeType.interface:
      case TypeType.union:
        return HTType(_curLibrary.readShortUtf8String());
    }
  }

  void _handleTypeAliasDecl() {
    final id = _curLibrary.readShortUtf8String();
    String? classId;
    final hasClassId = _curLibrary.readBool();
    if (hasClassId) {
      classId = _curLibrary.readShortUtf8String();
    }
    final isExported = _curLibrary.readBool();
    final value = _handleTypeExpr();

    final decl = HTVariable(id, this, classId: classId, value: value);

    _curNamespace.define(id, decl);
  }

  void _handleVarDecl() {
    final id = _curLibrary.readShortUtf8String();
    String? classId;
    final hasClassId = _curLibrary.readBool();
    if (hasClassId) {
      classId = _curLibrary.readShortUtf8String();
    }
    final isExternal = _curLibrary.readBool();
    final isStatic = _curLibrary.readBool();
    final isConst = _curLibrary.readBool();
    final isMutable = _curLibrary.readBool();
    final isExported = _curLibrary.readBool();
    final lateInitialize = _curLibrary.readBool();

    HTType? declType;
    final hasTypeDecl = _curLibrary.readBool();
    if (hasTypeDecl) {
      declType = _handleTypeExpr();
    }

    late final HTVariable decl;
    final hasInitializer = _curLibrary.readBool();
    if (hasInitializer) {
      if (lateInitialize) {
        final definitionLine = _curLibrary.readUint16();
        final definitionColumn = _curLibrary.readUint16();
        final length = _curLibrary.readUint16();
        final definitionIp = _curLibrary.ip;
        _curLibrary.skip(length);

        decl = HTVariable(id, this,
            classId: classId,
            closure: _curNamespace,
            declType: declType,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);
      } else {
        final initValue = execute();

        decl = HTVariable(id, this,
            classId: classId,
            closure: _curNamespace,
            declType: declType,
            value: initValue,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable);
      }
    } else {
      decl = HTVariable(id, this,
          classId: classId,
          closure: _curNamespace,
          declType: declType,
          isExternal: isExternal,
          isStatic: isStatic,
          isConst: isConst,
          isMutable: isMutable);
    }

    if (!hasClassId || isStatic) {
      _curNamespace.define(id, decl);
    } else {
      _curClass!.defineInstanceMember(id, decl);
    }
  }

  Map<String, HTParameter> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTParameter>{};

    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = _curLibrary.readShortUtf8String();
      final isOptional = _curLibrary.readBool();
      final isNamed = _curLibrary.readBool();
      final isVariadic = _curLibrary.readBool();

      HTType? declType;
      final hasTypeDecl = _curLibrary.readBool();
      if (hasTypeDecl) {
        declType = _handleTypeExpr();
      }

      int? definitionIp;
      int? definitionLine;
      int? definitionColumn;
      final hasInitializer = _curLibrary.readBool();
      if (hasInitializer) {
        definitionLine = _curLibrary.readUint16();
        definitionColumn = _curLibrary.readUint16();
        final length = _curLibrary.readUint16();
        definitionIp = _curLibrary.ip;
        _curLibrary.skip(length);
      }

      paramDecls[id] = HTParameter(id, this,
          declType: declType,
          definitionIp: definitionIp,
          definitionLine: definitionLine,
          definitionColumn: definitionColumn,
          isOptional: isOptional,
          isNamed: isNamed,
          isVariadic: isVariadic);
    }

    return paramDecls;
  }

  void _handleFuncDecl() {
    final internalName = _curLibrary.readShortUtf8String();
    String? id;
    final hasId = _curLibrary.readBool();
    if (hasId) {
      id = _curLibrary.readShortUtf8String();
    }
    String? classId;
    final hasClassId = _curLibrary.readBool();
    if (hasClassId) {
      classId = _curLibrary.readShortUtf8String();
    }
    String? externalTypeId;
    final hasExternalTypedef = _curLibrary.readBool();
    if (hasExternalTypedef) {
      externalTypeId = _curLibrary.readShortUtf8String();
    }
    final category = FunctionCategory.values[_curLibrary.read()];
    final isExternal = _curLibrary.readBool();
    final isStatic = _curLibrary.readBool();
    final isConst = _curLibrary.readBool();
    final isExported = _curLibrary.readBool();
    final hasParamDecls = _curLibrary.readBool();
    final isVariadic = _curLibrary.readBool();
    final minArity = _curLibrary.read();
    final maxArity = _curLibrary.read();
    final paramLength = _curLibrary.read();
    final paramDecls = _getParams(paramLength);

    ReferConstructor? referConstructor;
    final positionalArgIps = <int>[];
    final namedArgIps = <String, int>{};
    if (category == FunctionCategory.constructor) {
      final hasRefCtor = _curLibrary.readBool();
      if (hasRefCtor) {
        final isSuper = _curLibrary.readBool();
        final hasCtorName = _curLibrary.readBool();
        String? name;
        if (hasCtorName) {
          name = _curLibrary.readShortUtf8String();
        }
        final positionalArgIpsLength = _curLibrary.read();
        for (var i = 0; i < positionalArgIpsLength; ++i) {
          final argLength = _curLibrary.readUint16();
          positionalArgIps.add(_curLibrary.ip);
          _curLibrary.skip(argLength);
        }
        final namedArgsLength = _curLibrary.read();
        for (var i = 0; i < namedArgsLength; ++i) {
          final argName = _curLibrary.readShortUtf8String();
          final argLength = _curLibrary.readUint16();
          namedArgIps[argName] = _curLibrary.ip;
          _curLibrary.skip(argLength);
        }
        referConstructor = ReferConstructor(
            isSuper: isSuper,
            name: name,
            positionalArgsIp: positionalArgIps,
            namedArgsIp: namedArgIps);
      }
    }

    int? line, column, definitionIp;
    final hasDefinition = _curLibrary.readBool();
    if (hasDefinition) {
      line = _curLibrary.readUint16();
      column = _curLibrary.readUint16();
      final length = _curLibrary.readUint16();
      definitionIp = _curLibrary.ip;
      _curLibrary.skip(length);
    }

    final func = HTFunction(
        internalName, _curModuleFullName, _curLibrary.id, this,
        id: id,
        classId: classId,
        definitionIp: definitionIp,
        definitionLine: line,
        definitionColumn: column,
        category: category,
        isExternal: isExternal,
        externalTypeId: externalTypeId,
        hasParamDecls: hasParamDecls,
        paramDecls: paramDecls,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isVariadic,
        minArity: minArity,
        maxArity: maxArity,
        closure: _curNamespace,
        referConstructor: referConstructor);

    if (!isStatic &&
        (category == FunctionCategory.method ||
            category == FunctionCategory.getter ||
            category == FunctionCategory.setter)) {
      // final decl = HTVariable(id, _curModuleFullName, _curLibraryName, this,
      //     value: func);
      _curClass!.defineInstanceMember(func.internalName, func);
    } else {
      // constructor are defined in class's namespace,
      // however its context is on instance.
      if (category != FunctionCategory.constructor) {
        func.context = _curNamespace;
      }
      // static methods are defined in class's namespace,
      // final decl = HTVariable(id, _curModuleFullName, _curLibraryName, this,
      //     value: func);
      _curNamespace.define(func.internalName, func);
    }
  }

  void _handleClassDecl() {
    final id = _curLibrary.readShortUtf8String();
    final isExternal = _curLibrary.readBool();
    final isAbstract = _curLibrary.readBool();
    final isExported = _curLibrary.readBool();
    HTType? superType;
    final hasSuperClass = _curLibrary.readBool();
    if (hasSuperClass) {
      superType = _handleTypeExpr();
    } else {
      if (!isExternal && (id != HTLexicon.object)) {
        superType = HTType.object;
      }
    }
    final klass = HTClass(this,
        id: id,
        closure: _curNamespace,
        superType: superType,
        isExternal: isExternal,
        isAbstract: isAbstract);
    _curNamespace.define(id, klass);
    final savedClass = _curClass;
    _curClass = klass;
    final hasDefinition = _curLibrary.readBool();
    if (hasDefinition) {
      execute(namespace: klass.namespace);
    }
    // Add default constructor if non-exist.
    if (!isAbstract) {
      if (!isExternal) {
        if (!klass.namespace.declarations
            .containsKey(SemanticNames.constructor)) {
          final ctor = HTFunction(SemanticNames.constructor, _curModuleFullName,
              _curLibrary.id, this,
              classId: klass.id,
              category: FunctionCategory.constructor,
              closure: klass.namespace);
          // final decl = HTVariable(
          //     ctor.id, _curModuleFullName, _curLibraryName, this,
          //     value: ctor);
          klass.namespace.define(SemanticNames.constructor, ctor);
        }
      }
      // else {
      //   if (!klass.namespace.contains(klass.id)) {
      //     klass.namespace.define(HTBytecodeFunction(
      //         klass.id, this, _curModuleFullName,
      //         klass: klass, category: FunctionType.constructor));
      //   }
      // }
    }
    if (_curConfig.sourceType == SourceType.script || _curFunction != null) {
      klass.resolve();
    }

    _curClass = savedClass;
  }

  void _handleEnumDecl({String? classId}) {
    final id = _curLibrary.readShortUtf8String();
    final isExternal = _curLibrary.readBool();
    final length = _curLibrary.readUint16();

    var defs = <String, HTEnumItem>{};
    for (var i = 0; i < length; i++) {
      final enumId = _curLibrary.readShortUtf8String();
      defs[enumId] = HTEnumItem<int>(i, enumId, HTType(id));
    }

    final enumClass =
        HTEnum(id, defs, this, classId: classId, isExternal: isExternal);
    // final decl = HTVariable(id, _curModuleFullName, _curLibraryName, this,
    //     value: enumClass);
    _curNamespace.define(id, enumClass);
  }
}
