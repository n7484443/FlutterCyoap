import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:cyoap_flutter/model/platform_file_system.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' show Format, PngEncoder;
import 'package:image/image.dart' as im;

import '../main.dart';
import 'abstract_platform.dart';
import 'package:cyoap_flutter/util/platform_specified_util/save_non_js.dart'
  if(dart.library.js) 'package:cyoap_flutter/util/platform_specified_util/save_js.dart';

class PlatformSystem{
  static PlatformSystem instance = PlatformSystem();
  PlatformFileSystem platformFileSystem = PlatformFileSystem();
  String? path;

  Future<void> openPlatformZip(PlatformFile file) async{
    var bytes = file.bytes;
    if(bytes == null)return;

    var archiveBytes = ZipDecoder().decodeBytes(bytes);
    await platformFileSystem.createFromZip(archiveBytes);
  }

  Future<void> openPlatformZipFromFile(File file) async{
    var bytes = await file.readAsBytes();
    path = file.parent.path;

    var archiveBytes = ZipDecoder().decodeBytes(bytes);
    await platformFileSystem.createFromZip(archiveBytes);
  }

  Future<void> openPlatformFolder(String path) async {
    this.path = path;
    await platformFileSystem.createFromFolder(path);
  }

  void openPlatformVoid(){
    platformFileSystem.createFromVoid();
  }

  Future<void> saveFile(Map<String, dynamic> input) async{
    if(input['bool'] as bool){
      await saveZip('exported.zip', input);
    }else{
      await saveZip(path!, input);
    }
  }
  Future<void> saveFolder(PlatformFileSystem platformFileSystem) async{
    await saveRaw(path!, platformFileSystem);
  }

  static List<Uint8List> getImageList() {
    return instance.platformFileSystem.getImageList();
  }

  static String getImageName(int index) {
    return instance.platformFileSystem.getImageName(index);
  }

  static Image getImage(String image){
    return instance.platformFileSystem.getImage(image);
  }

  static void addImage(String name, Uint8List data){
    instance.platformFileSystem.addImage(name, data);
  }

  void saveCapture(ui.Image image) async{
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if(byteData == null)return;
    var decodeOutput = im.Image.fromBytes(image.width, image.height, byteData.buffer.asUint8List(), format: Format.rgba);
    var out = PngEncoder().encodeImage(decodeOutput);
    var converted = await getPlatformFileSystem().convertCapturedImage('exported.png', out as Uint8List, image.width, image.height);
    if(ConstList.isOnlyFileAccept()) {
      downloadCapture(converted.data2, converted.data1);
    }else{
      downloadCapture('$path/${converted.data2}', converted.data1);
    }
  }

  static int getImageIndex(String name) {
    return instance.platformFileSystem.getImageIndex(name);
  }
}

AbstractPlatform getPlatform(){
  return getPlatformFileSystem().platform;
}

PlatformFileSystem getPlatformFileSystem(){
  return PlatformSystem.instance.platformFileSystem;
}
