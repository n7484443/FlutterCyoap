import 'package:english_words/english_words.dart';

class ChoiceNodeBase {
  //grid 단위로 설정
  int x;
  int y;
  int width; //-1 = 무한대
  int height;
  bool isCard;
  String title;
  String contentsString;
  String imageString;

  ChoiceNodeBase(this.x, this.y, this.width, this.height, this.isCard,
      this.title, this.contentsString, this.imageString);

  ChoiceNodeBase.origin(this.width, this.height, this.isCard, this.title,
      this.contentsString, this.imageString)
      : x = 0,
        y = 0;

  ChoiceNodeBase.noTitle(this.width, this.height, this.isCard,
      this.contentsString, this.imageString)
      : x = 0,
        y = 0,
        title = '' {
    for (int i = 0; i < 2; i++) {
      title += WordPair.random().asPascalCase;
    }
  } //랜덤 문자로 제목 중복 방지

  int getType() {
    if (!isCard) {
      return 0;
    }
    if (imageString.isEmpty) {
      return 1;
    }
    if (contentsString.isEmpty) {
      return 2;
    }
    return 3;
  }

  Map<String, dynamic> toJson() => {
    'x' : x,
    'y' : y,
    'width' : width,
    'height' : height,
    'isCard' : isCard,
    'title' : title,
    'contentsString' : contentsString,
    'imageString' : imageString,
  };
}
