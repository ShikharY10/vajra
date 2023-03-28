library vajra;

import 'src/db/config.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

class Vajra {
  final String path;

  late DataBase _db;

  Vajra(this.path) {
    _initiateDB();
  }

  _initiateDB() async {
    _db = DataBase();
    _db.init(path);
  }

  setDefaultHeader(String key, value) {}

  setBasePath(String basePath) {}

  get(String endPoint, Map<String, String>? headers, Map<String, String>? queries) {}

  post(String endPoint, Map<String, String> body, Map<String, String>? headers, Map<String, String>? queries) {}

  put(String endPoint, Map<String, String> body, Map<String, String>? headers, Map<String, String>? queries) {}

  delete(String endPoint, Map<String, String> body, Map<String, String>? headers, Map<String, String>? queries) {}

}
