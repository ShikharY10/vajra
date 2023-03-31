library vajra;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'src/db/config.dart';
import 'src/db/models.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

class Vajra {

  late DataBase _db;
  String _directoryPath = "";

  bool _isInitialized = false;

  final Map<String, CookieModel> _cookie = {};
  final Map<String, String> _headers = {};
  String _basePath = "";

  Vajra(String directoryPath, {String? basePath}) {
    _directoryPath = directoryPath;
    if (basePath != null) {
      _basePath = basePath;
    }
  }

  _initiateDB() async {
    _db = DataBase();
    await _db.flutterInit(_directoryPath);
    _isInitialized = true;
  }

  Map<String, String> _attachHeaders(bool secured, bool sendCookie, Map<String, String>? headers) {
    Map<String, String> header = {};

    header.addAll(_headers);

    if (secured) {
      String? securitySchemeType = _db.configBox.get("defaultSecurityScheme.type");
      if (securitySchemeType != null) {
        String? securityScheme = _db.configBox.get("defaultSecurityScheme.$securitySchemeType");
        if (securityScheme != null) {
          if (securitySchemeType == "bearer") {
            header["Authorization"] = "bearer $securityScheme";
          }
        }
      }
    }

    if (sendCookie) {
      String cookie = "";
      _cookie.forEach((key, value) {
        if (value.expires!.isAfter(DateTime.now())) {
          if (cookie.isEmpty) {
            cookie = "$key=${value.value}";
          } else {
            cookie = "$cookie;$key=${value.value}";
          }
        } else {
          _cookie.remove(key);
        }
      });

      header["Cookie"] = cookie;
    }

    if (headers != null) {
      header.addAll(headers);
    }

    return header;
  }

  String _attachQueries(String uri, Map<String, String>? queries) {
    if (queries != null) {
      uri = "$uri?";
      int count = 0;
      queries.forEach((key, value) {
        if (count == 0) {
          uri = "$uri$key=$value";
        } else {
          uri = "&$uri$key=$value";
        }
      });
    }
    return uri;
  }

  List<CookieModel> _extractCookies(String setCookies) {
    List<CookieModel> cookieModels = [];

    for (String setCookie in  setCookies.split(",")) {

      CookieModel cookie = CookieModel();

      for (String cookieParts in setCookie.split(";")) {

        if (cookieParts.contains("=")) {

          List<String>keyValue = cookieParts.split("=");
          String key = keyValue[0].trim();
          String value = keyValue[1].trim();
          if (key == "Path") {
            cookie.path = value;
          } else if (key == "Max-Age") {
            cookie.expires = DateTime.now().add(Duration(minutes: int.parse(value)));
            // cookie.expires = DateTime.parse(value);
          } else {
            cookie.name = key;
            cookie.value = value;
          }
        } else {
          if (cookieParts.trim() == "Secure") {
            cookie.isSecure = true;
          } else {
            cookie.isSecure = false;
          }

          if (cookieParts == "HttpOnly") {
            cookie.isHttpOnly = true;
          } else {
            cookie.isHttpOnly = false;
          }
        }
      }
      cookieModels.add(cookie);
    }
    return cookieModels;
  }

  initialize() async {
    await _initiateDB();
  }

  bool get isInitialized => _isInitialized;
  Map<String, CookieModel> get cookies => _cookie;

  setDefaultHeaders(Map<String, String> headers) {
    _headers.addAll(headers);
  }

  setBasePath(String basePath) {
    _basePath = basePath;
  }

  Future<VajraResponse> get(String endPoint, bool secured, bool sendCookie, {Map<String, String>? headers, Map<String, String>? queries}) async {
    String url = _basePath + endPoint;


    Map<String, String> header = _attachHeaders(secured, sendCookie, headers);

    String uri = _attachQueries(url, queries);

    bool isError = true;
    int responseCode = -1;
    dynamic body;
    String errorMsg = "";

    try {
      http.Response response = await http.get(
        Uri.parse(uri),
        headers: header
      );
      responseCode = response.statusCode;
      if (response.statusCode >= 200 && response.statusCode <= 204) {
        isError = false;
        print("Headers: ${response.headers}");

        List<CookieModel> cookies = [];

        String? setCookies = response.headers["set-cookie"];
        if (setCookies != null) {
          cookies = _extractCookies(setCookies);
        }

        Cookies savedCookies = Cookies();
        String? strCookies = _db.configBox.get("cookies");
        if (strCookies != null) {
          savedCookies = Cookies.fromJson(strCookies);
        }

        for (var c in cookies) {
          if (c.name != null) {
            savedCookies.cookies.add(c.name!);
            _db.configBox.put(c.name, c.toJson());
            _cookie[c.name!] = c;
            print(c);
          }
        }
        _db.configBox.put("cookies", savedCookies.toJson());
        
        body = json.decode(String.fromCharCodes(response.bodyBytes));
      } else {
        body = json.decode(String.fromCharCodes(response.bodyBytes));
        if (body is String) {
          errorMsg = body;
        }
      }
    } catch (e) {
      print(e);
      errorMsg = "local error";
    }
    
    return VajraResponse(
      responseCode,
      body,
      isError,
      errorMsg
    );
  }

  post(String endPoint, bool secured, bool sendCookie, Map<String, String> body, Map<String, String>? headers, Map<String, String>? queries) async {

    String uri = _basePath + endPoint;

    Map<String, String> header = _attachHeaders(secured, sendCookie, headers);

    uri = _attachQueries(uri, queries);

    bool isError = true;
    int responseCode = -1;
    dynamic body;
    String errorMsg = "";

    try {
      http.Response response = await http.post(
        Uri.parse(endPoint),
        headers: header,
        body: body
      );
      responseCode = response.statusCode;
      if (response.statusCode >= 200 && response.statusCode <= 204) {
        isError = false;
        body = json.decode(String.fromCharCodes(response.bodyBytes));
        
      } else {
        body = json.decode(String.fromCharCodes(response.bodyBytes));
        if (body is String) {
          errorMsg = body;
        }
      }
    } catch (e) {
      errorMsg = "local error";
    }
    
    return VajraResponse(
      responseCode,
      body,
      isError,
      errorMsg
    );
  }

  put(String endPoint, bool secured, bool sendCookie, Map<String, String> body, Map<String, String>? headers, Map<String, String>? queries) async {
    String uri = _basePath + endPoint;

    Map<String, String> header = _attachHeaders(secured, sendCookie, headers);

    uri = _attachQueries(uri, queries);

    bool isError = true;
    int responseCode = -1;
    dynamic body;
    String errorMsg = "";

    try {
      http.Response response = await http.put(
        Uri.parse(endPoint),
        headers: header,
        body: body
      );
      responseCode = response.statusCode;
      if (response.statusCode >= 200 && response.statusCode <= 204) {
        isError = false;
        body = json.decode(String.fromCharCodes(response.bodyBytes));
      } else {
        body = json.decode(String.fromCharCodes(response.bodyBytes));
        if (body is String) {
          errorMsg = body;
        }
      }
    } catch (e) {
      errorMsg = "local error";
    }
    
    return VajraResponse(
      responseCode,
      body,
      isError,
      errorMsg
    );
  }

  delete(String endPoint, bool secured, bool sendCookie, Map<String, String> body, Map<String, String>? headers, Map<String, String>? queries) async {
    String uri = _basePath + endPoint;

    Map<String, String> header = _attachHeaders(secured, sendCookie, headers);

    uri = _attachQueries(uri, queries);

    bool isError = true;
    int responseCode = -1;
    dynamic body;
    String errorMsg = "";

    try {
      http.Response response = await http.put(
        Uri.parse(endPoint),
        headers: header,
        body: body
      );
      responseCode = response.statusCode;
      if (response.statusCode >= 200 && response.statusCode <= 204) {
        isError = false;
        body = json.decode(String.fromCharCodes(response.bodyBytes));
      } else {
        body = json.decode(String.fromCharCodes(response.bodyBytes));
        if (body is String) {
          errorMsg = body;
        }
      }
    } catch (e) {
      errorMsg = "local error";
    }
    
    return VajraResponse(
      responseCode,
      body,
      isError,
      errorMsg
    );
  }
}

class VajraResponse {
  int statusCode;
  dynamic body;
  bool isError;
  String errorMessage;

  VajraResponse(this.statusCode, this.body, this.isError, this.errorMessage);
}
