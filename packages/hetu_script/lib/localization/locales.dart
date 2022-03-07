part 'locales/english.dart';
part 'locales/simplified_chinese.dart';

abstract class HTLocale {
  String get errorBytecode;
  String get errorVersion;
  String get errorAssertionFailed;
  String get errorUnkownSourceType;
  String get errorImportListOnNonHetuSource;
  String get errorExportNonHetuSource;

  // syntactic errors
  String get errorUnexpected;
  String get errorDelete;
  String get errorExternal;
  String get errorNestedClass;
  String get errorConstInClass;
  String get errorOutsideReturn;
  String get errorSetterArity;
  String get errorExternalMember;
  String get errorEmptyTypeArgs;
  String get errorEmptyImportList;
  String get errorExtendsSelf;
  String get errorMissingFuncBody;
  String get errorExternalCtorWithReferCtor;
  String get errorNonCotrWithReferCtor;
  String get errorSourceProviderError;
  String get errorNotAbsoluteError;
  String get errorInvalidLeftValue;
  String get errorNullableAssign;
  String get errorPrivateMember;
  String get errorConstMustBeStatic;
  String get errorConstMustInit;
  String get errorDuplicateLibStmt;
  String get errorNotConstValue;

  // compile time errors
  String get errorDefined;
  String get errorOutsideThis;
  String get errorNotMember;
  String get errorNotClass;
  String get errorAbstracted;
  String get errorInterfaceCtor;
  String get errorConstValue;

  // runtime errors
  String get errorUnsupported;
  String get errorUnknownOpCode;
  String get errorNotInitialized;
  String get errorUndefined;
  String get errorUndefinedExternal;
  String get errorUnknownTypeName;
  String get errorUndefinedOperator;
  String get errorNotCallable;
  String get errorUndefinedMember;
  String get errorUninitialized;
  String get errorCondition;
  String get errorNullObject;
  String get errorNullSubSetKey;
  String get errorSubGetKey;
  String get errorOutOfRange;
  String get errorAssignType;
  String get errorImmutable;
  String get errorNotType;
  String get errorArgType;
  String get errorArgInit;
  String get errorReturnType;
  String get errorStringInterpolation;
  String get errorArity;
  String get errorExternalVar;
  String get errorBytesSig;
  String get errorCircleInit;
  String get errorNamedArg;
  String get errorIterable;
  String get errorUnkownValueType;
  String get errorTypeCast;
  String get errorCastee;
  String get errorNotSuper;
  String get errorStructMemberId;
  String get errorUnresolvedNamedStruct;
  String get errorBinding;
}
