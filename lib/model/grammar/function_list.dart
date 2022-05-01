import 'dart:math';

import 'package:cyoap_flutter/model/grammar/value_type.dart';
import 'package:cyoap_flutter/model/variable_db.dart';

class Functions {
  Map<String, ValueType Function(List<ValueType> input)> functionMap = {};

  void init() {
    functionMap['if'] = funcIf;
    functionMap['floor'] = funcFloor;
    functionMap['round'] = funcRound;
    functionMap['ceil'] = funcCeil;
    functionMap['+'] = funcPlus;
    functionMap['-'] = funcMinus;
    functionMap['*'] = funcMulti;
    functionMap['/'] = funcDiv;
    functionMap['='] = funcSet;
    functionMap['=='] = funcEqual;
    functionMap['!='] = funcNotEqual;
    functionMap['>'] = funcBigger;
    functionMap['<'] = funcSmaller;
    functionMap['>='] = funcBiggerEqual;
    functionMap['<='] = funcSmallerEqual;
    functionMap['and'] = funcAnd;
    functionMap['or'] = funcOr;
    functionMap['not'] = funcNot;
    functionMap['random'] = funcRandom;
    functionMap['none'] = funcNone;
    functionMap['exist'] = funcExist;
  }

  Function getFunction(String name) {
    if (functionMap[name] == null) {
      for (var f in functionMap.values) {
        if (f.toString().contains(name)) {
          return f;
        }
      }
      return funcNone;
    }
    return functionMap[name]!;
  }

  String getFunctionName(Function function) {
    for (var key in functionMap.keys) {
      if (functionMap[key] == function) {
        return key;
      }
    }
    return 'none';
  }

  ValueType funcNone(List<ValueType> input) {
    return input[0];
  }

  ValueType funcIf(List<ValueType> input) {
    if (input[0].data is bool && input[0].data) {
      return input[1];
    } else {
      return input[2];
    }
  }

  ValueType funcFloor(List<ValueType> input) {
    if (input[0].data is num) {
      return ValueType((input[0].data as num).floor());
    } else {
      return input[0];
    }
  }

  ValueType funcRound(List<ValueType> input) {
    if (input[0].data is num) {
      return ValueType((input[0].data as num).round());
    } else {
      return input[0];
    }
  }

  ValueType funcCeil(List<ValueType> input) {
    if (input[0].data is num) {
      return ValueType((input[0].data as num).ceil());
    } else {
      return input[0];
    }
  }

  ValueType funcPlus(List<ValueType> input) {
    if (input[0].data is num && input[1].data is num) {
      return ValueType(input[0].data + input[1].data);
    } else {
      return ValueType(input[0].data.toString() + input[1].data.toString());
    }
  }

  ValueType funcMinus(List<ValueType> input) {
    if (input[0].data is num && input[1].data is num) {
      return ValueType(input[0].data - input[1].data);
    } else {
      return input[0];
    }
  }

  ValueType funcMulti(List<ValueType> input) {
    if (input[0].data is num && input[1].data is num) {
      return ValueType(input[0].data * input[1].data);
    } else {
      return input[0];
    }
  }

  ValueType funcDiv(List<ValueType> input) {
    if (input[0].data is num && input[1].data is num) {
      return ValueType(input[0].data / input[1].data);
    } else {
      return input[0];
    }
  }

  ValueType funcSet(List<ValueType> input) {
    return input[0];
  }

  var epsilon = 0.000001;

  ValueType funcEqual(List<ValueType> input) {
    if (input[0].data is num && input[1].data is num) {
      return ValueType((input[0].data - input[1].data as num).abs() <= epsilon);
    } else {
      return ValueType(false);
    }
  }

  ValueType funcNotEqual(List<ValueType> input) {
    return ValueType(!funcEqual(input).data);
  }

  ValueType funcBigger(List<ValueType> input) {
    if (input[0].data is num && input[1].data is num) {
      return ValueType(input[0].data > input[1].data);
    } else {
      return ValueType(false);
    }
  }

  ValueType funcSmaller(List<ValueType> input) {
    if (input[0].data is num && input[1].data is num) {
      return ValueType(input[0].data < input[1].data);
    } else {
      return ValueType(false);
    }
  }

  ValueType funcBiggerEqual(List<ValueType> input) {
    return ValueType(!funcSmaller(input).data);
  }

  ValueType funcSmallerEqual(List<ValueType> input) {
    return ValueType(!funcBigger(input).data);
  }

  ValueType funcRandom(List<ValueType> input) {
    if (input[0].data is int) {
      return ValueType(Random().nextInt(input[0].data as int));
    } else {
      return ValueType(Random().nextBool());
    }
  }

  ValueType funcAnd(List<ValueType> input) {
    for (var i in input) {
      if (!(i.data is bool && i.data == true)) {
        return ValueType(false);
      }
    }
    return ValueType(true);
  }

  ValueType funcOr(List<ValueType> input) {
    for (var i in input) {
      if (i.data is bool && i.data == true) {
        return ValueType(true);
      }
    }
    return ValueType(false);
  }

  ValueType funcNot(List<ValueType> input) {
    if (input[0].data is bool) {
      return ValueType(!input[0].data);
    } else {
      return ValueType(false);
    }
  }

  ValueType funcExist(List<ValueType> input) {
    var name = (input[0].data as VariableUnit).varName;
    return ValueType(VariableDataBase().hasValue(name));
  }
}
