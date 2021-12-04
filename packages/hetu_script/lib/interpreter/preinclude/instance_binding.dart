part of '../abstract_interpreter.dart';

extension IntBinding on int {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'remainder':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remainder(positionalArgs[0]);
      case 'compareTo':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            compareTo(positionalArgs[0]);
      case 'isNaN':
        return isNaN;
      case 'isNegative':
        return isNegative;
      case 'isInfinite':
        return isInfinite;
      case 'isFinite':
        return isFinite;
      case 'clamp':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clamp(positionalArgs[0], positionalArgs[1]);
      case 'toStringAsFixed':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsPrecision(positionalArgs[0]);

      case 'modPow':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            modPow(positionalArgs[0], positionalArgs[1]);
      case 'modInverse':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            modInverse(positionalArgs[0]);
      case 'gcd':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            gcd(positionalArgs[0]);
      case 'isEven':
        return isEven;
      case 'isOdd':
        return isOdd;
      case 'bitLength':
        return bitLength;
      case 'toUnsigned':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toUnsigned(positionalArgs[0]);
      case 'toSigned':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toSigned(positionalArgs[0]);
      case 'abs':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            abs();
      case 'sign':
        return sign;
      case 'round':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            round();
      case 'floor':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            floor();
      case 'ceil':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ceil();
      case 'truncate':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            truncate();
      case 'roundToDouble':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            roundToDouble();
      case 'floorToDouble':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            floorToDouble();
      case 'ceilToDouble':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ceilToDouble();
      case 'truncateToDouble':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            truncateToDouble();
      case 'toRadixString':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toRadixString(positionalArgs[0]);
      default:
        throw HTError.undefined(varName);
    }
  }
}

extension DoubleBinding on double {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'remainder':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remainder(positionalArgs[0]);
      case 'compareTo':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            compareTo(positionalArgs[0]);
      case 'isNaN':
        return isNaN;
      case 'isNegative':
        return isNegative;
      case 'isInfinite':
        return isInfinite;
      case 'isFinite':
        return isFinite;
      case 'clamp':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clamp(positionalArgs[0], positionalArgs[1]);
      case 'toStringAsFixed':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsFixed(positionalArgs[0]);
      case 'toStringAsExponential':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsExponential(positionalArgs[0]);
      case 'toStringAsPrecision':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toStringAsPrecision(positionalArgs[0]);

      case 'abs':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            abs();
      case 'sign':
        return sign;
      case 'round':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            round();
      case 'floor':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            floor();
      case 'ceil':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ceil();
      case 'truncate':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            truncate();
      case 'roundToDouble':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            roundToDouble();
      case 'floorToDouble':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            floorToDouble();
      case 'ceilToDouble':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            ceilToDouble();
      case 'truncateToDouble':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            truncateToDouble();
      default:
        throw HTError.undefined(varName);
    }
  }
}

extension StringBinding on String {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'compareTo':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            compareTo(positionalArgs[0]);
      case 'codeUnitAt':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            codeUnitAt(positionalArgs[0]);
      case 'length':
        return length;
      case 'endsWith':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            endsWith(positionalArgs[0]);
      case 'startsWith':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            startsWith(positionalArgs[0], positionalArgs[1]);
      case 'indexOf':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'substring':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            substring(positionalArgs[0], positionalArgs[1]);
      case 'trim':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            trim();
      case 'trimLeft':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            trimLeft();
      case 'trimRight':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            trimRight();
      case 'padLeft':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            padLeft(positionalArgs[0], positionalArgs[1]);
      case 'padRight':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            padRight(positionalArgs[0], positionalArgs[1]);
      case 'contains':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            contains(positionalArgs[0], positionalArgs[1]);
      case 'replaceFirst':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceFirst(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceAll':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceAll(positionalArgs[0], positionalArgs[1]);
      case 'replaceRange':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            replaceRange(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'split':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            split(positionalArgs[0]);
      case 'toLowerCase':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toLowerCase();
      case 'toUpperCase':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toUpperCase();
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart list.
extension ListBinding on List {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'contains':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            contains(positionalArgs.first);
      case 'elementAt':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            elementAt(positionalArgs.first);
      case 'join':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            join(positionalArgs.first);
      case 'first':
        return first;
      case 'last':
        return last;
      case 'length':
        return length;
      case 'add':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            add(positionalArgs.first);
      case 'addAll':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            addAll(positionalArgs.first);
      case 'reversed':
        return reversed;
      case 'indexOf':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'insert':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            insert(positionalArgs[0], positionalArgs[1]);
      case 'insertAll':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            insertAll(positionalArgs[0], positionalArgs[1]);
      case 'clear':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clear();
      case 'remove':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remove(positionalArgs.first);
      case 'removeAt':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeAt(positionalArgs.first);
      case 'removeLast':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            removeLast();
      case 'sublist':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            sublist(positionalArgs[0], positionalArgs[1]);
      case 'asMap':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            asMap();
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart map.
extension MapBinding on Map {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'length':
        return length;
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'keys':
        return keys.toList();
      case 'values':
        return values.toList();
      case 'containsKey':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            containsKey(positionalArgs.first);
      case 'containsValue':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            containsValue(positionalArgs.first);
      case 'addAll':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            addAll(positionalArgs.first);
      case 'clear':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            clear();
      case 'remove':
        return (HTNamespace context,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            remove(positionalArgs.first);
      default:
        throw HTError.undefined(varName);
    }
  }
}

/// Binding object for dart future.
extension FutureBinding on Future {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'then':
        return (HTNamespace context,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          HTFunction func = positionalArgs[0];
          then((value) {
            func.call(positionalArgs: [value]);
          });
        };
      default:
        throw HTError.undefined(varName);
    }
  }
}
