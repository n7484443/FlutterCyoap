import 'dart:collection';

import 'package:cyoap_flutter/viewModel/vm_variable_table.dart';

import 'grammar/value_type.dart';

class VariableDataBase {
  static final VariableDataBase _instance = VariableDataBase._init();

  factory VariableDataBase() {
    return _instance;
  }

  VariableDataBase._init();

  var varMap = HashMap<String, ValueTypeWrapper>();
  VMVariableTable? viewModel;

  void setValue(String name, ValueTypeWrapper value) {
    varMap[name] = value;
    viewModel?.update();
  }

  void deleteValue(String name) {
    varMap.remove(name);
  }

  bool hasValue(String name) {
    return varMap.containsKey(name);
  }

  ValueTypeWrapper? getValueTypeWrapper(String name) {
    return varMap[name];
  }

  ValueType? getValueType(String name) {
    return varMap[name]?.valueType;
  }

  @override
  String toString() {
    return varMap.toString();
  }

  void clear() {
    varMap.clear();
    viewModel?.update();
  }

  void clearLocalVariable() {
    varMap.removeWhere((key, value) => !value.isGlobal);
  }
}
