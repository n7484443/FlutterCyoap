import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../model/image_db.dart';

class ViewImageLoading extends StatelessWidget {
  final String name;
  ViewImageLoading(this.name) : super(key: GlobalKey());

  @override
  Widget build(BuildContext context) {
    if (ConstList.isDistributed) {
      return ExtendedImage.network(
        '/dist/images/$name',
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        fit: BoxFit.scaleDown,
      );
    }
    var image = ImageDB().getImage(name);
    if (image != null) {
      var output = ExtendedImage.memory(
        image,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        fit: BoxFit.scaleDown,
      );
      return output;
    }
    return ImageDB().noImage;
  }
}
