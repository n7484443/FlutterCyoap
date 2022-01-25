import 'package:cyoap_flutter/view/view_code_editor.dart';
import 'package:cyoap_flutter/view/view_editor.dart';
import 'package:cyoap_flutter/view/view_make.dart';
import 'package:cyoap_flutter/view/view_play.dart';
import 'package:cyoap_flutter/view/view_start.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class ConstList{
  static double appBarSize = 40.0;
}
void main() {
  runApp(
    GetMaterialApp(
      title: 'CYOAP',
      home: const ViewStart(),
      getPages: [
        GetPage(name: '/viewMake', page: () => const ViewMake()),
        GetPage(name: '/viewPlay', page: () => const ViewPlay()),
        GetPage(name: '/viewStart', page: () => const ViewStart()),
        GetPage(name: '/viewEditor', page: () => const ViewEditor()),
        GetPage(name: '/viewCodeEditor', page: () => const ViewCodeEditor()),
      ],
    ),
  );
}
