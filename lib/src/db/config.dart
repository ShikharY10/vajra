// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DataBase {
  late Box<String> configBox;

  init(String path) async {
    await Hive.initFlutter(path);
    configBox = await Hive.openBox<String>("config");
  }
}