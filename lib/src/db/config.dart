// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DataBase {
  late Box<String> configBox;

  flutterInit(String path, String name) async {
    await Hive.initFlutter(path);
    configBox = await Hive.openBox<String>("$name.config");
  }
}