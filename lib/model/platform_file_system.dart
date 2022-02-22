import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:path/path.dart';

import '../util/tuple.dart';
import 'abstract_platform.dart';
import 'choiceNode/choice_node.dart';
import 'choiceNode/line_setting.dart';

//platformFileSystem - abstractPlatform
class PlatformFileSystem {
  late AbstractPlatform platform;
  final Map<String, Uint8List> _dirImage = {};
  Image noImage = Image.asset('images/noImage.png');
  bool openAsFile = false;

  PlatformFileSystem();

  Future<void> createFromFolder(String path) async {
    openAsFile = false;
    var dirImages = Directory(path + '/images');
    var dirNodes = Directory(path + '/nodes');
    var platformJson = File(path + '/platform.json');

    var existImages = await dirImages.exists();
    if (!existImages) {
      dirImages.create();
    } else {
      var dirList = await dirImages.list().toList();
      for (FileSystemEntity f in dirList) {
        var name = basename(f.path);
        var type = isImageFile(name);
        if (f is File && type != -1) {
          if (type == 1) {
            var bytes = await f.readAsBytes();
            _dirImage.putIfAbsent(name, () => bytes);
          } else {
            //지원 아직 x
          }
        }
      }
    }
    var existJson = await platformJson.exists();
    if (existJson) {
      var data = await platformJson.readAsString();
      if (data.isNotEmpty) {
        platform = AbstractPlatform.fromJson(jsonDecode(data));
      } else {
        platform = AbstractPlatform.none();
      }
    } else {
      platform = AbstractPlatform.none();
    }

    var existNodes = await dirNodes.exists();
    List<ChoiceNodeBase> nodeList = List.empty(growable: true);
    if (!existNodes) {
      dirNodes.create();
    } else {
      var dirList = await dirNodes.list().toList();
      for (FileSystemEntity f in dirList) {
        if (f is File) {
          var value = await f.readAsString();
          if(f.path.contains('lineSetting_')){
            var lineSetting = LineSetting.fromJson(jsonDecode(value));
            platform.addLineSettingData(lineSetting);
          }else{
            var node = ChoiceNodeBase.fromJson(jsonDecode(value));
            nodeList.add(node);
          }
        }
      }
    }

    platform.addDataAll(nodeList);
    platform.init();
  }

  Future<void> createFromZip(Archive archive) async{
    openAsFile = true;
    String? platformJson;

    List<ChoiceNodeBase> nodeList = List.empty(growable: true);
    List<LineSetting> lineSettingList = List.empty(growable: true);
    for (var file in archive) {
      Uint8List data = file.content as Uint8List;
      if (file.isFile) {
        var fileName = file.name;
        if (fileName.startsWith('images')) {
          int type = isImageFile(fileName);
          if (type == 1) {
            _dirImage.putIfAbsent(fileName.split("/")[1], () => data);
          }else{
            //아직 지원 x
          }
        } else if (fileName.startsWith('nodes')) {
          if(fileName.contains('lineSetting_')){
            lineSettingList.add(LineSetting.fromJson(jsonDecode(utf8.decode(data))));
          }else{
            nodeList.add(ChoiceNodeBase.fromJson(jsonDecode(utf8.decode(data))));
          }
        } else if (fileName.endsWith('platform.json')) {
          platformJson = utf8.decode(data);
        }
      }
    }
    if (platformJson != null) {
      platform = AbstractPlatform.fromJson(jsonDecode(platformJson));
    } else {
      platform = AbstractPlatform.none();
    }

    platform.addDataAll(nodeList);
    for(var lineSetting in lineSettingList){
      platform.addLineSettingData(lineSetting);
    }
    platform.init();
  }
  void createFromVoid() {
    platform = AbstractPlatform.none();
  }
  Configuration config = const Configuration(
    outputType: ImageOutputType.webpThenPng,
    quality: 100,
  );

  Future<Tuple<String, Uint8List>> convertImage(String name, Uint8List data) async{
    if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg')) {
      name = name.replaceAll(RegExp('[.](png|jpg|jpeg)'), '.webp');
      ImageFile input = ImageFile(rawBytes: data, filePath: name);
      final param = ImageFileConfiguration(input: input, config: config);
      final output = await compressor.compress(param);
      data = output.rawBytes;
    }
    return Tuple(name, data);
  }


  Future<Archive> saveToZip() async{
    var archive = Archive();
    for(var imageName in _dirImage.keys) {
      var converted = await convertImage(imageName, _dirImage[imageName]!);
      archive.addFile(ArchiveFile(
          'images/${converted.data1}', converted.data2.length, converted.data2));
    }
    for(int i = 0; i < platform.choiceNodes.length; i++){
      var tuple = platform.choiceNodes[i];
      var data = utf8.encode(jsonEncode(tuple.data2.toJson()));
      archive.addFile(ArchiveFile('nodes/lineSetting_${tuple.data2.y}.json', data.length, data));

      for (int j = 0; j < tuple.data1.length; j++) {
        var node = platform.choiceNodes[i].data1[j];
        var utf = utf8.encode(jsonEncode(node.toJson()));
        archive.addFile(ArchiveFile('nodes/${node.title}.json', utf.length, utf));
      }
    }
    var platformJson = utf8.encode(jsonEncode(platform.toJson()));
    archive.addFile(
        ArchiveFile('platform.json', platformJson.length, platformJson));

    return archive;
  }

  bool hasImageNameNotWebp(String name){
    return basename(name).contains(RegExp('[.](png|jpg|jpeg)'));
  }

  Future<void> saveToFolder(String path) async {
    var dirImages = Directory(path + '/images');
    var dirNodes = Directory(path + '/nodes');
    var platformJson = File(path + '/platform.json');

    List<String> skipImage = List.empty(growable: true);
    if(dirImages.existsSync()){
      for(var existImage in await dirImages.list().toList()){
        var name = basename(existImage.path);
        if(!_dirImage.containsKey(name) && hasImageNameNotWebp(name)){
          await existImage.delete();
        }else{
          skipImage.add(name);
        }
      }
    }else{
      dirImages.create();
    }
    for(var imageName in _dirImage.keys){
      if(skipImage.contains(imageName))continue;
      var converted = await convertImage(imageName, _dirImage[imageName]!);
      var file = File('$path/images/${converted.data1}');
      file.createSync();
      file.writeAsBytes(converted.data2);
    }

    if(dirNodes.existsSync()) {
      dirNodes.deleteSync(recursive: true);
    }
    dirNodes.create();
    for(var x = 0; x < platform.choiceNodes.length; x++){
      var tuple = platform.choiceNodes[x];
      var file = File('$path/nodes/lineSetting_${tuple.data2.y}.json');
      file.createSync();
      file.writeAsString(jsonEncode(tuple.data2.toJson()));

      for(var nodes in tuple.data1){
        var file = File('$path/nodes/${nodes.title}.json');
        file.createSync();
        file.writeAsString(jsonEncode(nodes.toJson()));
      }
    }
    if(platformJson.existsSync()) {
      platformJson.deleteSync(recursive: true);
    }
    platformJson.create();
    platformJson.writeAsString(jsonEncode(platform.toJson()));
  }

  //1 = 일반 이미지, 0 = 웹 이미지, -1 = 이미지 아님.
  int isImageFile(String path) {
    var name = basename(path).toLowerCase();
    if (name.startsWith('http')) {
      return 0;
    }
    if (name.endsWith('.webp')) {
      return 1;
    }
    if (name.endsWith('.png')) {
      return 1;
    }
    if (name.endsWith('.jpg')) {
      return 1;
    }
    if (name.endsWith('.bmp')) {
      return 1;
    }
    if (name.endsWith('.gif')) {
      return 1;
    }
    return -1;
  }

  Image getImage(String name) {
    if (_dirImage[name] != null) {
      return Image.memory(_dirImage[name]!);
    } else {
      return noImage;
    }
  }
  List<Uint8List> getImageList(){
    return _dirImage.values.toList();
  }
  String getImageName(int index){
    return _dirImage.keys.toList()[index];
  }

  void addImage(String name, Uint8List data) {
    _dirImage.putIfAbsent(name, () => data);
  }

  int getImageIndex(String name) {
    return _dirImage.keys.toList().indexOf(name);
  }

}
