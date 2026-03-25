import 'package:flutter/material.dart';

class WorkTypeState extends ChangeNotifier {
  String selectedCategory = '一次加工';
  String selectedProcess = '';

  // 分類リスト
  static const List<String> categoryList = ['一次加工', '柱', '梁・間柱', 'ブレース', '他'];

  // 工種リストgetter
  List<String> get processList {
    switch (selectedCategory) {
      case '一次加工':
        return ['孔あけ', '切断', '開先加工', 'ショットブラスト'];
      case '柱':
        return [
          'コア組立',
          'コア溶接',
          'コアＵＴ',
          '仕口組立',
          '仕口検品',
          '仕口溶接',
          '仕口仕上げ',
          '仕口ＵＴ',
          '柱組立',
          '柱溶接',
          '柱仕上げ',
          '柱ＵＴ',
          '二次部材組立',
          '二次部材検品',
          '二次部材溶接',
          '仕上げ',
          '柱ＵＴ',
          '第三者ＵＴ',
          '塗装',
          '積込',
        ];
      case '梁・間柱':
        return [
          '組立',
          '検品',
          '溶接',
          '検査',
          '塗装',
          '積込',
          for (int i = 7; i <= 20; i++) '',
        ];
      case 'ブレース':
        return ['ブレース工種1', 'ブレース工種2']; // 必要に応じて編集
      case '他':
        return ['その他工種1', 'その他工種2']; // 必要に応じて編集
      default:
        return [];
    }
  }

  void setCategory(String category) {
    selectedCategory = category;
    selectedProcess = '';
    notifyListeners();
  }

  void setProcess(String process) {
    selectedProcess = process;
    notifyListeners();
  }
}
