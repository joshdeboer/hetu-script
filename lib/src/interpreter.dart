import 'dart:io';

import 'package:path/path.dart' as path;

import 'errors.dart';
import 'common.dart';
import 'expression.dart';
import 'statement.dart';
import 'namespace.dart';
import 'class.dart';
import 'function.dart';
import 'external.dart';
import 'lexer.dart';
import 'parser.dart';
import 'resolver.dart';

var globalInterpreter = Interpreter();

/// 负责对语句列表进行最终解释执行
class Interpreter implements ExprVisitor, StmtVisitor {
  static String _sdkDir;
  String workingDir;

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  final _locals = <Expr, int>{};

  ///
  final _literals = <dynamic>[];

  /// 保存当前语句所在的命名空间
  Namespace _curSpace;

  /// 全局命名空间
  final _global = Namespace();

  /// external函数的空间
  final _external = Namespace();

  Interpreter() {
    _curSpace = _global;
  }

  init({
    String hetuSdkDir,
    String workingDir,
    String language = 'enUS',
    Map<String, HS_External> bindMap,
    Map<String, HS_External> linkMap,
  }) {
    try {
      _sdkDir = hetuSdkDir ?? 'hetu_core';
      this.workingDir = workingDir ?? path.current;

      // Directory dirObj;
      // List<FileSystemEntity> fileList;
      String libpath;

      // 必须在绑定函数前加载河图基础类，因为函数本身也是对象
      print('Hetu: Core library path set to [${HS_Common.coreLibPath}].');
      libpath = path.join(_sdkDir, 'object.ht');
      evalf(libpath);

      // 绑定外部函数
      bindAll(HS_Extern.bindmap);
      bindAll(bindMap);
      linkAll(HS_Extern.linkmap);
      linkAll(linkMap);

      // // 加载核心库
      // for (var lib in _coreLib) {
      //   libpath = path.join(_sdkDir, lib);
      //   evalf(libpath);
      // }

      // TODO：使用import关键字决定加载顺序，而不是现在这样简单粗暴的遍历
      // 加载本次脚本文件需要的库
      // if (importDir != null) {
      //   for (var dir in importDir) {
      //     dirObj = Directory(dir);
      //     fileList = dirObj.listSync();
      //     for (var file in fileList) {
      //       if (file is File) {
      //         eval(file.readAsStringSync());
      //         print('Hetu: Impoted file [${path.basename(file.path)}].');
      //       }
      //     }
      //   }
      // }
    } catch (e) {
      print(e);
      print('Hetu init failed!');
    }
  }

  void eval(String script, {ParseStyle style = ParseStyle.library, String invokeFunc = null, List<dynamic> args}) {
    HS_Error.clear();
    try {
      final _lexer = Lexer();
      final _parser = Parser();
      final _resolver = Resolver();
      var tokens = _lexer.lex(script);
      var statements = _parser.parse(tokens, interpreter: this, style: style);
      _resolver.resolve(statements, interpreter: this);
      interpreter(
        statements,
        invokeFunc: invokeFunc,
        args: args,
      );
    } catch (e) {
      print(e);
    } finally {
      HS_Error.output();
    }
  }

  /// 解析文件
  void evalf(String filepath, {ParseStyle style = ParseStyle.library, String invokeFunc = null, List<dynamic> args}) {
    print('Hetu: Loading $filepath...');
    eval(File(filepath).readAsStringSync(), style: style, invokeFunc: invokeFunc, args: args);
  }

  /// 解析多个文件
  void evalfs(Iterable<String> paths,
      {ParseStyle style = ParseStyle.library, String invokeFunc = null, List<dynamic> args}) {
    String chunk = '';
    for (var file in paths) {
      chunk += File(file).readAsStringSync();
    }
    eval(chunk, style: style, invokeFunc: invokeFunc, args: args);
  }

  /// 解析多个文件
  void evalfs2(Iterable<FileSystemEntity> paths,
      {ParseStyle style = ParseStyle.library, String invokeFunc = null, List<dynamic> args}) {
    String chunk = '';
    for (var file in paths) {
      if (file is File) chunk += file.readAsStringSync();
    }
    eval(chunk, style: style, invokeFunc: invokeFunc, args: args);
  }

  var clReg = RegExp(r"('(\\'|[^'])*')|(\S+)");

  /// 解析命令行
  dynamic evalc(String input) {
    var matches = clReg.allMatches(input);
    var function = matches.first.group(3);
    String classname;
    if (function == null) throw Exception('命令行错误：无效的调用。');
    if (function.contains('.')) {
      var split = function.split('.');
      function = split.last;
      classname = split.first;
    }
    var args = <String>[];
    for (var i = 1; i < matches.length; ++i) {
      var word = matches.elementAt(i);
      if (word.group(1) != null) {
        String literal = word.group(1);
        literal = literal.substring(1).substring(0, literal.length - 2);
        args.add(literal);
      } else {
        args.add(word.group(0));
      }
    }
    return invoke(function, classname: classname, args: args);
  }

  void addLocal(Expr expr, int distance) {
    _locals[expr] = distance;
  }

  /// 定义一个常量，然后返回数组下标
  /// 相同值的常量不会重复定义
  int addLiteral(dynamic literal) {
    for (var i = 0; i < _literals.length; ++i) {
      if (_literals[i] == literal) {
        return i;
      }
    }

    _literals.add(literal);
    return _literals.length - 1;
  }

  void define(String name, dynamic value) {
    if (_global.contains(name)) {
      throw HSErr_Defined(name);
    } else {
      _global.define(name, value.type, value: value);
    }
  }

  /// 绑定外部函数
  void bind(String name, HS_External function) {
    if (_global.contains(name)) {
      throw HSErr_Defined(name);
    } else {
      var func_obj = HS_Function(name, extern: function);
      _global.define(name, HS_Common.Function, value: func_obj);
    }
  }

  void bindAll(Map<String, HS_External> bindMap) {
    if (bindMap != null) {
      for (var key in bindMap.keys) {
        bind(key, bindMap[key]);
      }
    }
  }

  /// 链接外部函数
  void link(String name, HS_External function) {
    if (_external.contains(name)) {
      throw HSErr_Defined(name);
    } else {
      _external.define(name, HS_Common.Dynamic, value: function);
    }
  }

  void linkAll(Map<String, HS_External> linkMap) {
    if (linkMap != null) {
      for (var key in linkMap.keys) {
        link(key, linkMap[key]);
      }
    }
  }

  dynamic fetchGlobal(String name) => _global.fetch(name);
  dynamic fetchExternal(String name) => _external.fetch(name);

  dynamic _getVar(String name, Expr expr) {
    var distance = _locals[expr];
    if (distance != null) {
      // 尝试获取当前环境中的本地变量
      return _curSpace.fetchAt(distance, name);
    } else {
      try {
        // 尝试获取当前实例中的类成员变量
        HS_Instance instance = _curSpace.fetch(HS_Common.This);
        return instance.get(name);
      } catch (e) {
        if ((e is HSErr_UndefinedMember) || (e is HSErr_Undefined)) {
          // 尝试获取全局变量
          return _global.fetch(name);
        } else {
          throw e;
        }
      }
    }
  }

  HS_Value convert(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is HS_Value) {
      return value;
    } else if (value is num) {
      return HSVal_Num(value);
    } else if (value is bool) {
      return HSVal_Bool(value);
    } else if (value is String) {
      return HSVal_String(value);
    } else {
      throw HSErr_Unsupport(value);
    }
  }

  void interpreter(List<Stmt> statements, {bool commandLine = false, String invokeFunc = null, List<dynamic> args}) {
    for (var stmt in statements) {
      evaluateStmt(stmt);
    }

    if ((!commandLine) && (invokeFunc != null)) {
      invoke(invokeFunc, args: args);
    }
  }

  dynamic invoke(String name, {String classname, List<dynamic> args}) {
    HS_Error.clear();
    try {
      if (classname == null) {
        var func = _global.fetch(name);
        if (func is HS_Function) {
          return func.call(args ?? []);
        } else {
          throw HSErr_Undefined(name);
        }
      } else {
        var klass = _global.fetch(classname);
        if (klass is HS_Class) {
          var func = klass.fetch(name);
          if (func is HS_Function) {
            return func.call(args ?? []);
          } else {
            throw HSErr_Callable(name);
          }
        } else {
          throw HSErr_Undefined(classname);
        }
      }
    } catch (e) {
      print(e);
    } finally {
      HS_Error.output();
    }
  }

  void executeBlock(List<Stmt> statements, Namespace environment) {
    var save = _curSpace;
    try {
      _curSpace = environment;
      for (var stmt in statements) {
        evaluateStmt(stmt);
      }
    } finally {
      _curSpace = save;
    }
  }

  dynamic evaluateStmt(Stmt stmt) => stmt.accept(this);

  dynamic evaluateExpr(Expr expr) => expr.accept(this); //convert(expr.accept(this));

  @override
  dynamic visitLiteralExpr(LiteralExpr expr) {
    return _literals[expr.constantIndex];
  }

  @override
  dynamic visitVarExpr(VarExpr expr) => _getVar(expr.name.lexeme, expr);

  @override
  dynamic visitGroupExpr(GroupExpr expr) => evaluateExpr(expr.expr);

  @override
  dynamic visitUnaryExpr(UnaryExpr expr) {
    var value = evaluateExpr(expr.value);

    switch (expr.op.lexeme) {
      case HS_Common.Subtract:
        {
          if (value is num) {
            return -value;
          } else {
            throw HSErr_UndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      case HS_Common.Not:
        {
          if (value is bool) {
            return !value;
          } else {
            throw HSErr_UndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      default:
        throw HSErr_UndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
        break;
    }
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    var left = evaluateExpr(expr.left);
    var right = evaluateExpr(expr.right);

    // TODO 操作符重载
    switch (expr.op.type) {
      case HS_Common.Or:
      case HS_Common.And:
        {
          if (left is bool) {
            if (right is bool) {
              if (expr.op.type == HS_Common.Or) {
                return left || right;
              } else if (expr.op.type == HS_Common.And) {
                return left && right;
              }
            } else {
              throw HSErr_UndefinedBinaryOperator(
                  left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
            }
          } else {
            throw HSErr_UndefinedBinaryOperator(
                left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      case HS_Common.Equal:
        return left == right;
        break;
      case HS_Common.NotEqual:
        return left != right;
        break;
      case HS_Common.Add:
      case HS_Common.Subtract:
        {
          if ((left is String) && (right is String)) {
            return left + right;
          } else if ((left is num) && (right is num)) {
            if (expr.op.lexeme == HS_Common.Add) {
              return left + right;
            } else if (expr.op.lexeme == HS_Common.Subtract) {
              return left - right;
            }
          } else {
            throw HSErr_UndefinedBinaryOperator(
                left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      case HS_Common.Multiply:
      case HS_Common.Devide:
      case HS_Common.Modulo:
      case HS_Common.Greater:
      case HS_Common.GreaterOrEqual:
      case HS_Common.Lesser:
      case HS_Common.LesserOrEqual:
        {
          if (left is num) {
            if (right is num) {
              if (expr.op.type == HS_Common.Multiply) {
                return left * right;
              } else if (expr.op.type == HS_Common.Devide) {
                return left / right;
              } else if (expr.op.type == HS_Common.Modulo) {
                return left % right;
              } else if (expr.op.type == HS_Common.Greater) {
                return left > right;
              } else if (expr.op.type == HS_Common.GreaterOrEqual) {
                return left >= right;
              } else if (expr.op.type == HS_Common.Lesser) {
                return left < right;
              } else if (expr.op.type == HS_Common.LesserOrEqual) {
                return left <= right;
              }
            } else {
              throw HSErr_UndefinedBinaryOperator(
                  left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
            }
          } else {
            throw HSErr_UndefinedBinaryOperator(
                left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      default:
        throw HSErr_UndefinedBinaryOperator(
            left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
        break;
    }
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {
    var callee = evaluateExpr(expr.callee);
    var args = <dynamic>[];
    for (var arg in expr.args) {
      //var value = convert(evaluate(arg));
      var value = evaluateExpr(arg);
      args.add(value);
    }

    if (callee is HS_Function) {
      if ((callee.arity >= 0) && (callee.arity != expr.args.length)) {
        throw HSErr_Arity(expr.args.length, callee.arity, expr.callee.line, expr.callee.column);
      } else if (callee.funcStmt != null) {
        for (var i = 0; i < callee.funcStmt.params.length; ++i) {
          var param_token = callee.funcStmt.params[i].typename;
          var arg_type = HS_TypeOf(args[i]);
          if ((param_token.lexeme != HS_Common.Dynamic) && (arg_type != param_token.lexeme)) {
            throw HSErr_ArgType(arg_type, param_token.lexeme, param_token.line, param_token.column);
          }
        }
      }

      if (!callee.isConstructor) {
        return callee.call(args);
      } else {
        //TODO命名构造函数
      }
    } else if (callee is HS_Class) {
      // for (var i = 0; i < callee.varStmts.length; ++i) {
      //   var param_type_token = callee.varStmts[i].typename;
      //   var arg = args[i];
      //   if (arg.type != param_type_token.lexeme) {
      //     throw HetuError(
      //         '(Interpreter) The argument type "${arg.type}" can\'t be assigned to the parameter type "${param_type_token.lexeme}".'
      //         ' [${param_type_token.line}, ${param_type_token.column}].');
      //   }
      // }

      return callee.createInstance(args: args);
    } else {
      throw HSErr_Callable(callee.toString(), expr.callee.line, expr.callee.column);
    }
  }

  @override
  dynamic visitAssignExpr(AssignExpr expr) {
    //var value = convert(evaluate(expr.value));
    var value = evaluateExpr(expr.value);

    var distance = _locals[expr];
    if (distance != null) {
      // 尝试设置当前环境中的本地变量
      _curSpace.assignAt(distance, expr.variable.lexeme, value);
    } else {
      try {
        // 尝试设置当前实例中的类成员变量
        HS_Instance instance = _curSpace.fetch(HS_Common.This);
        instance.set(expr.variable.lexeme, value);
      } catch (e) {
        if (e is HSErr_Undefined) {
          // 尝试设置全局变量
          _global.assign(expr.variable.lexeme, value);
        } else {
          throw e;
        }
      }
    }

    // 返回右值
    return value;
  }

  @override
  dynamic visitThisExpr(ThisExpr expr) {
    return _getVar(expr.keyword.lexeme, expr);
  }

  @override
  dynamic visitSubGetExpr(SubGetExpr expr) {}

  @override
  dynamic visitSubSetExpr(SubSetExpr expr) {}

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {
    var object = evaluateExpr(expr.collection);
    if (object is HS_Instance) {
      return object.get(expr.key.lexeme);
    } else if (object is HS_Class) {
      return object.fetch(expr.key.lexeme);
    } else if (object is num) {
      return HSVal_Num(object).get(expr.key.lexeme);
    } else if (object is bool) {
      return HSVal_Bool(object).get(expr.key.lexeme);
    } else if (object is String) {
      return HSVal_String(object).get(expr.key.lexeme);
    }

    throw HSErr_Get(object.toString(), expr.key.line, expr.key.column);
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    dynamic object = evaluateExpr(expr.collection);
    if (object is! HS_Instance) {}
    var value = evaluateExpr(expr.value);
    object.set(expr.key.lexeme, value);
    return value;
  }

  @override
  dynamic visitImportStmt(ImportStmt stmt) {
    String lib_name;
    if (stmt.filepath.startsWith('hetu:')) {
      lib_name = stmt.filepath.substring(5);
      lib_name = path.join(_sdkDir, lib_name + '.ht');
    } else {
      lib_name = path.join(workingDir, stmt.filepath);
    }
    evalf(lib_name);
  }

  @override
  void visitVarStmt(VarStmt stmt) {
    dynamic value;
    if (stmt.initializer != null) {
      //value = convert(evaluate(stmt.initializer));
      value = evaluateExpr(stmt.initializer);
    }

    if (stmt.typename.lexeme == HS_Common.Dynamic) {
      _curSpace.define(stmt.varname.lexeme, stmt.typename.lexeme, value: value);
    } else if (stmt.typename.lexeme == HS_Common.Var) {
      // 如果用了var关键字，则从初始化表达式推断变量类型
      if (value != null) {
        _curSpace.define(stmt.varname.lexeme, HS_TypeOf(value), value: value);
      } else {
        _curSpace.define(stmt.varname.lexeme, HS_Common.Dynamic);
      }
    } else {
      // 接下来define函数会判断类型是否符合声明
      _curSpace.define(stmt.varname.lexeme, stmt.typename.lexeme, value: value);
    }
  }

  @override
  void visitExprStmt(ExprStmt stmt) => evaluateExpr(stmt.expr);

  @override
  void visitBlockStmt(BlockStmt stmt) => executeBlock(stmt.block, Namespace(_curSpace));

  @override
  void visitReturnStmt(ReturnStmt stmt) {
    if (stmt.expr != null) {
      throw evaluateExpr(stmt.expr);
    }
    throw null;
  }

  @override
  void visitIfStmt(IfStmt stmt) {
    var value = evaluateExpr(stmt.condition);
    if (value is bool) {
      if (value) {
        evaluateStmt(stmt.thenBranch);
      } else if (stmt.elseBranch != null) {
        evaluateStmt(stmt.elseBranch);
      }
    } else {
      throw HSErr_Condition(stmt.condition.line, stmt.condition.column);
    }
  }

  @override
  void visitWhileStmt(WhileStmt stmt) {
    var value = evaluateExpr(stmt.condition);
    if (value is bool) {
      try {
        while ((value is bool) && (value)) {
          evaluateStmt(stmt.loop);
          value = evaluateExpr(stmt.condition);
        }
      } catch (error) {
        if (error is HS_Break) {
          return;
        } else {
          throw error;
        }
      }
    } else {
      throw HSErr_Condition(stmt.condition.line, stmt.condition.column);
    }
  }

  @override
  void visitBreakStmt(BreakStmt stmt) {
    throw HS_Break();
  }

  @override
  void visitFuncStmt(FuncStmt stmt) {
    // 构造函数本身不注册为变量
    if (!stmt.isConstructor) {
      if (stmt.isExtern) {
        var externFunc = _external.fetch(stmt.name.lexeme);
        _curSpace.define(stmt.name.lexeme, HS_Common.Dynamic, value: externFunc);
      } else {
        var function =
            HS_Function(stmt.name.lexeme, funcStmt: stmt, closure: _curSpace, isConstructor: false, arity: stmt.arity);
        _curSpace.define(stmt.name.lexeme, HS_Common.Function, value: function);
      }
    }
  }

  @override
  void visitClassStmt(ClassStmt stmt) {
    HS_Class superClass;

    if ((stmt.superClass != null)) {
      superClass = evaluateExpr(stmt.superClass);
      if (superClass is! HS_Class) {
        throw HSErr_Extends(superClass.name, stmt.superClass.line, stmt.superClass.column);
      }

      _curSpace = Namespace(_curSpace);
      _curSpace.define(HS_Common.Super, HS_Common.Class, value: superClass);
    }

    var methods = <String, HS_Function>{};
    var staticMethods = <String, HS_Function>{};
    for (var method in stmt.methods) {
      dynamic func;
      if (method.isExtern) {
        var externFunc = _external.fetch('${stmt.name.lexeme}.${method.name.lexeme}');
        func = HS_Function(method.name.lexeme, extern: externFunc);
      } else {
        func = HS_Function(stmt.name.lexeme,
            funcStmt: method, closure: _curSpace, isConstructor: method.isConstructor, arity: method.arity);
      }
      if (!method.isStatic) {
        methods[method.name.lexeme] = func;
      } else {
        staticMethods[method.name.lexeme] = func;
      }
    }

    var hetuClass = HS_Class(stmt.name.lexeme,
        superClassName: superClass?.name, variables: stmt.variables, methods: methods, staticMethods: staticMethods);

    if (superClass != null) {
      _curSpace = _curSpace.enclosing;
    }

    _curSpace.define(stmt.name.lexeme, HS_Common.Class, value: hetuClass);
  }
}
