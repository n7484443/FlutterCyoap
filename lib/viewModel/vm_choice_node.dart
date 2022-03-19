import 'dart:convert';
import 'dart:math';

import 'package:cyoap_flutter/viewModel/vm_draggable_nested_map.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';

import '../model/choiceNode/choice_node.dart';
import '../model/platform_system.dart';
import '../util/tuple.dart';

const double nodeBaseWidth = 176;
const double nodeBaseHeight = 24;

class VMChoiceNode extends GetxController {
  late QuillController quillController;
  ChoiceNodeBase node;
  int x;
  int y;
  var size = Tuple<int, int>(0, 0).obs;
  var realSize = Tuple<double, double>(0, 0).obs;
  var imageString = ''.obs;
  var titleString = ''.obs;
  var isDrag = false.obs;
  var isCardMode = false.obs;
  var status = SelectableStatus.open.obs;

  VMChoiceNode({this.x = -10, this.y = -10}) : node = getNode(x, y)!;

  @override
  void onInit() {
    super.onInit();
    quillController = initQuillController();
    size.listen((data) {
      realSize.update((val) {
        if (data.data1 == 0) {
          val!.data1 = double.infinity;
        } else {
          val!.data1 = data.data1 * nodeBaseWidth;
        }
        val.data2 = data.data2 * nodeBaseHeight;
      });
    });
    isDrag.listen((data) {
      var vmDraggable = Get.find<VMDraggableNestedMap>();
      if (size.value.data1 == 0) {
        realSize.update((val) {
          val!.data1 = data ? vmDraggable.getMaxWidth() : double.infinity;
        });
      }
    });
    size.value = Tuple(node.width, node.height);
    titleString.value = node.title;
    imageString.value = node.imageString;
    isCardMode.value = node.isCard;
    status.value = node.status;
  }

  QuillController initQuillController() {
    if (node.contentsString.isEmpty) {
      return QuillController.basic();
    } else {
      var json = jsonDecode(node.contentsString);
      var document = Document.fromJson(json);
      return QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0));
    }
  }

  static ChoiceNodeBase? getNode(int x, int y) {
    if (x == -10 && y == -10) {
      return VMDraggableNestedMap.createNodeForTemp();
    } else if (y < 0 || y >= getPlatform().choiceNodes.length) {
      return null;
    } else if (x < 0 || x >= getPlatform().choiceNodes[y].length) {
      return null;
    }
    return getPlatform().getChoiceNode(x, y);
  }

  static String getTag(int x, int y) {
    return '$x:$y';
  }

  void sizeChange(int x, int y) {
    size.update((val) {
      val!.data1 += x;
      val.data2 += y;
      val.data1 = max(val.data1, 0);
      val.data2 = max(val.data2, 0);
      node.width = val.data1;
      node.height = val.data2;
    });
  }

  void updateFromEditor() {
    titleString.value = node.title;
    imageString.value = node.imageString;
    isCardMode.value = node.isCard;
  }

  void updateFromNode() {
    node = getNode(x, y)!;
    onInit();
  }

  static VMChoiceNode? getVMChoiceNode(int x, int y) {
    if (!Get.isRegistered<VMChoiceNode>(tag: VMChoiceNode.getTag(x, y))) {
      return null;
    }
    return Get.find<VMChoiceNode>(tag: VMChoiceNode.getTag(x, y));
  }

  bool isSelect() {
    if (x == -10 && y == -10) return false;
    return getPlatform().isSelect(x, y);
  }

  bool isIgnorePointer() {
    return status.value.isPointerInteractive(node.isSelectable);
  }

  void select() {
    getPlatform().setSelect(x, y);
    VMChoiceNode.doAllVMChoiceNode((vm) {
      vm.status.value = vm.node.status;
    });
  }

  double get opacity{
    if(isEditable())return 1;

    if(node.isSelectable){
      if(isIgnorePointer()) {
        return 1;
      }else if(status.value == SelectableStatus.hide) {
        return 0;
      }else {
        return 0.5;
      }
    }else{
      if(status.value == SelectableStatus.selected) {
        return 1;
      }else{
        return 0;
      }
    }
  }

  static void doAllVMChoiceNode(void Function(VMChoiceNode vm) action) {
    getPlatform().doAllChoiceNode((node) {
      var vm = getVMChoiceNode(node.x, node.y);
      if (vm != null) {
        action(vm);
      }
    });
  }
}