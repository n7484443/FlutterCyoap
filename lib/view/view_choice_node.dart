import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:cyoap_flutter/model/choiceNode/choice_node.dart';
import 'package:cyoap_flutter/model/choiceNode/generable_parser.dart';
import 'package:cyoap_flutter/view/util/view_image_loading.dart';
import 'package:cyoap_flutter/view/util/view_text_outline.dart';
import 'package:cyoap_flutter/view/util/view_wrap_custom.dart';
import 'package:cyoap_flutter/view/view_draggable_nested_map.dart';
import 'package:cyoap_flutter/viewModel/vm_choice_node.dart';
import 'package:cyoap_flutter/viewModel/vm_draggable_nested_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../main.dart';
import '../model/abstract_platform.dart';
import '../model/platform_system.dart';
import '../viewModel/vm_variable_table.dart';

class ViewChoiceNode extends GetView<VMDraggableNestedMap> {
  final ChoiceNode? node;

  ViewChoiceNode(int posX, int posY, {Key? key})
      : node = posX <0 && posY < 0
            ? null
            : getPlatform.getChoiceNode([posY, posX])!,
        super(key: key);

  const ViewChoiceNode.fromNode(this.node, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (node == null) {
      return Card(
        child: SizedBox(
          width: controller.maxWidth /
              defaultMaxSize *
              3 *
              controller.scale(context),
          height: nodeBaseHeight * controller.scale(context),
        ),
      );
    }
    var nodeController = Get.put(VMChoiceNode.fromNode(node!), tag: node!.tag);

    var editor = Obx(() {
      return IgnorePointer(
        child: QuillEditor(
          controller: nodeController.quillController,
          focusNode: FocusNode(),
          readOnly: true,
          autoFocus: false,
          expands: false,
          padding: const EdgeInsets.only(top: 4),
          scrollController: ScrollController(),
          scrollable: false,
          customStyles: ConstList.getDefaultThemeData(
              context, controller.scale(context),
              fontStyle: ConstList.getFont(controller.mainFont.value)),
        ),
      );
    });

    var mainBox = Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            if (nodeController.imageString.value.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: nodeController.maximizingImage.value ? double.infinity : MediaQuery.of(context).size.height / 3.5,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  child: ViewImageLoading(nodeController.imageString.value),
                ),
              ),
            if (nodeController.titleString.value.isNotEmpty)
              TextOutline(
                nodeController.titleString.value,
                18 * controller.scale(context),
                ConstList.getFont(controller.titleFont.value),
              ),
          ],
        ),
        editor,
        ViewWrapCustom(
          node!.children,
          (child) => isEditable
              ? NodeDraggable(child)
              : ViewChoiceNode.fromNode(child),
          maxSize: node!.width,
          builderDraggable: isEditable
              ? (i) =>
                  NodeDragTarget(List.from(node!.pos(), growable: true)..add(i))
              : null,
          isAllVisible: isEditable,
        )
      ],
    );

    var baseColor = node!.isCard ? Colors.white : baseNodeColor;
    var mainNode = Ink(
      color: baseColor,
      child: InkWell(
        onDoubleTap: isEditable
            ? () {
                controller.editNode = node!;
                Get.toNamed('/viewEditor', id: 1);
              }
            : null,
        onTap: !isEditable
            ? () async {
                nodeController.select();
                if (nodeController.isRandom.value) {
                  if (nodeController.isSelect) {
                    nodeController.startRandom();
                    await showDialog(
                      context: context,
                      builder: (builder) => RandomDialog(node),
                      barrierDismissible: false,
                    );
                  } else {
                    node!.random = -1;
                  }
                }
                VMChoiceNode.updateStatusAll();
              }
            : null,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            mainBox,
            if (controller.isVisibleOnlyEdit()) ...[
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<int>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (result) {
                    if (result == 0) {
                      showDialog(
                        context: context,
                        builder: (builder) => SizeDialog(node),
                      );
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem(
                        value: 0,
                        child: Text('크기 수정'),
                      ),
                    ];
                  },
                ),
              )
            ] else if (getPlatformFileSystem
                    .hasSource(nodeController.imageString.value) &&
                Get.find<VMVariableTable>().isVisibleSource) ...[
              Positioned(
                bottom: 0,
                left: 0,
                child: TextButton(
                  child: const Text(
                    '출처',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    var url = getPlatformFileSystem
                        .getSource(nodeController.imageString.value);
                    if (url != null && url.isNotEmpty) {
                      launchUrlString(url);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Obx(
      () {
        var isSelectedCheck = nodeController.status.value.isSelected() &&
            nodeController.node.isSelectable;
        return Opacity(
          opacity: nodeController.opacity,
          child: Card(
            shape: nodeController.isRound.value
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(
                      color: isSelectedCheck
                          ? Colors.lightBlueAccent
                          : Colors.transparent,
                      width: 4,
                    ),
                  )
                : Border.fromBorderSide(
                    BorderSide(
                      color: isSelectedCheck
                          ? Colors.lightBlueAccent
                          : Colors.transparent,
                      width: 4,
                    ),
                  ),
            color: baseColor,
            clipBehavior: Clip.antiAlias,
            margin: ConstList.isSmallDisplay(context)
                ? const EdgeInsets.all(1.4)
                : null,
            elevation: nodeController.isCard.value ? ConstList.elevation : 0,
            child: Padding(
              padding: ConstList.isSmallDisplay(context)
                  ? const EdgeInsets.all(2.0)
                  : const EdgeInsets.all(4.0),
              child: isEditable
                  ? mainNode
                  : IgnorePointer(
                      ignoring: !nodeController.isIgnorePointer,
                      child: mainNode,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class SizeDialog extends StatelessWidget {
  final ChoiceNode? node;

  const SizeDialog(this.node, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = VMChoiceNode.getVMChoiceNodeFromNode(node!)!;
    return AlertDialog(
      scrollable: true,
      alignment: Alignment.center,
      title: const Text('크기 수정'),
      content: Obx(
        () => Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('길이'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    controller.sizeChange(-1);
                  },
                ),
                Text(
                    '${controller.size.value == 0 ? 'max' : controller.size.value}'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    controller.sizeChange(1);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RandomDialog extends StatelessWidget {
  final ChoiceNode? node;

  const RandomDialog(this.node, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = VMChoiceNode.getVMChoiceNodeFromNode(node!)!;
    return Obx(
      () => AlertDialog(
          scrollable: true,
          title: const Text('랜덤'),
          content: AnimatedFlipCounter(
              value: controller.randomValue.value,
              duration: const Duration(milliseconds: 500),
              textStyle: const TextStyle(
                fontSize: 40,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              )),
          actions: [
            Visibility(
              visible: !controller.randomProcess.value,
              child: TextButton(
                onPressed: () {
                  Get.back();
                },
                child: const Text('확인'),
              ),
            )
          ]),
    );
  }
}

class NodeDraggable extends GetView<VMDraggableNestedMap> {
  final ChoiceNode node;

  const NodeDraggable(this.node, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var widget = ViewChoiceNode.fromNode(node);
    var pos = node.pos();
    if (ConstList.isSmallDisplay(context)) {
      return LongPressDraggable<List<int>>(
        onDragUpdate: (details) => controller.dragUpdate(details, context),
        data: pos,
        feedback: Opacity(
          opacity: 0.5,
          child: SizedBox(
              width: controller.maxWidth /
                  (defaultMaxSize + 3) *
                  (widget.node!.width == 0
                      ? defaultMaxSize
                      : widget.node!.width),
              child: widget),
        ),
        onDragStarted: () {
          controller.dragStart(pos);
        },
        child: Opacity(
          child: widget,
          opacity: listEquals(controller.drag, pos) ? 0.2 : 1.0,
        ),
        onDragEnd: (DraggableDetails data) {
          controller.dragEnd();
        },
        onDraggableCanceled: (Velocity velocity, Offset offset) {
          controller.dragEnd();
        },
      );
    } else {
      return Draggable<List<int>>(
        onDragUpdate: (details) => controller.dragUpdate(details, context),
        data: pos,
        feedback: Opacity(
          opacity: 0.5,
          child: SizedBox(
              width: controller.maxWidth /
                  (defaultMaxSize + 3) *
                  (widget.node!.width == 0
                      ? defaultMaxSize
                      : widget.node!.width),
              child: widget),
        ),
        onDragStarted: () {
          controller.dragStart(pos);
        },
        child: Opacity(
          child: widget,
          opacity: listEquals(controller.drag, pos) ? 0.2 : 1.0,
        ),
        onDragEnd: (DraggableDetails data) {
          controller.dragEnd();
        },
        onDraggableCanceled: (Velocity velocity, Offset offset) {
          controller.dragEnd();
        },
      );
    }
  }
}
