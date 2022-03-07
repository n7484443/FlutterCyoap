import 'dart:ffi';
import 'dart:io' ;
import 'dart:typed_data';
import 'package:cyoap_flutter/util/tuple.dart';
import 'package:cyoap_flutter/util/platform_specified_util/webp_converter.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart';

class WebpConverterImp extends WebpConverter {
  @override
  WebpConverter getWebpConverterImp(){
    if(Platform.isWindows){
      return WebpConverterImpWindows();
    }
    return WebpConverterImpAndroid();
  }
}
class WebpConverterImpWindows extends WebpConverter {
  late final DynamicLibrary nativeWebp;
  late final int Function(Pointer<Uint8> rgb,
      int width,
      int height,
      int stride,
      double qualityFactor,
      Pointer<Pointer<Uint8>> output) webPEncodeRGB;
  late final Function(Pointer<Uint8> rgb, int width, int height, int stride,
      Pointer<Pointer<Uint8>> output) webPEncodeLosslessRGB;
  late final Function(Pointer<Uint8> rgb, int width, int height, int stride,
      Pointer<Pointer<Uint8>> output) webPEncodeLosslessRGBA;
  @override
  void init(){
    var startPath = Platform.script.resolve("libwebp.dll").toFilePath();
    // 'windows/libwebp.dll'
    File f = File(startPath);
    if(!f.existsSync()){
      startPath = "libwebp.dll";
    }
    nativeWebp = DynamicLibrary.open(startPath);

    webPEncodeRGB = nativeWebp.lookupFunction<
        Size Function(
            Pointer<Uint8>, Int, Int, Int, Float, Pointer<Pointer<Uint8>>),
        int Function(
            Pointer<Uint8> rgb,
            int width,
            int height,
            int stride,
            double qualityFactor,
            Pointer<Pointer<Uint8>> output)>('WebPEncodeRGB');
    webPEncodeLosslessRGB = nativeWebp.lookupFunction<
        Size Function(Pointer<Uint8>, Int, Int, Int, Pointer<Pointer<Uint8>>),
        int Function(Pointer<Uint8> rgb, int width, int height, int stride,
            Pointer<Pointer<Uint8>> output)>('WebPEncodeLosslessRGB');
    webPEncodeLosslessRGBA = nativeWebp.lookupFunction<
        Size Function(Pointer<Uint8>, Int, Int, Int, Pointer<Pointer<Uint8>>),
        int Function(Pointer<Uint8> rgb, int width, int height, int stride,
            Pointer<Pointer<Uint8>> output)>('WebPEncodeLosslessRGBA');
  }

  @override
  Future<Tuple<Uint8List, String>> convert(Uint8List input, String name, int width, int height) async {
    Image decodeImage;
    if(name.endsWith(".png")){
      decodeImage = PngDecoder().decodeImage(input)!;
    }else if(name.endsWith(".jpg") | name.endsWith(".jpeg")){
      decodeImage = JpegDecoder().decodeImage(input)!;
    }else{
      return Tuple(input, name);
    }

    Pointer<Pointer<Uint8>> outputBuff = malloc.allocate<Pointer<Uint8>>(0);
    Pointer<Uint8> inputBuff;
    Uint8List output;
    dynamic outputSize;
    if(decodeImage.channels == Channels.rgb){
      int size = decodeImage.width * decodeImage.height * 3;
      inputBuff = malloc.allocate<Uint8>(size);
      var inputBuffered = decodeImage.getBytes(format: Format.rgb);
      for(int i = 0; i < size; i++){
        inputBuff[i] = inputBuffered[i];
      }
      outputSize = webPEncodeLosslessRGB(inputBuff, decodeImage.width, decodeImage.height, decodeImage.width*3, outputBuff);
    }else{//rgba
      int size = decodeImage.width * decodeImage.height * 4;
      inputBuff = malloc.allocate<Uint8>(size);
      var inputBuffered = decodeImage.getBytes(format: Format.rgba);
      for(int i = 0; i < size; i++){
        inputBuff[i] = inputBuffered[i];
      }
      outputSize = webPEncodeLosslessRGBA(inputBuff, decodeImage.width, decodeImage.height, decodeImage.width*4, outputBuff);
    }
    output = outputBuff.value.asTypedList(outputSize);
    malloc.free(inputBuff);
    malloc.free(outputBuff);
    return Tuple(output, name.replaceAll(RegExp('[.](png|jpg|jpeg)'), '.webp'));
  }
  @override
  bool canConvert() => true;
}
class WebpConverterImpAndroid extends WebpConverter{
  @override
  Future<Tuple<Uint8List, String>> convert(Uint8List input, String name, int width, int height) async {
    if(name.endsWith(".png") || name.endsWith(".jpg") || name.endsWith(".jpeg")){
      var output = await FlutterImageCompress.compressWithList(input,
        format:CompressFormat.webp,
        quality: 100,
        minWidth: width,
        minHeight: height,
      );
      return Tuple(output, name.replaceAll(RegExp('[.](png|jpg|jpeg)'), '.webp'));
    }
    return Tuple(input, name);
  }

  @override
  void init() {}

  @override
  bool canConvert() => true;
}