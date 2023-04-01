/// Contains main `Vajra` class
library vajra;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'src/security_scheme.dart';
import 'src/db/config.dart';
import 'src/db/models.dart';
import 'package:get_it/get_it.dart';

/// Http Client class which contains methods and attributes used to make http requests.
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
    GetIt.I.registerSingleton<Vajra>(this, instanceName: "vajra");
  }

  Map<String, String> _attachHeaders(bool secured, bool sendCookie, Map<String, String>? headers) {

    Map<String, String> header = {};

    header.addAll(_headers);

    if (secured) {
      String? authorizationType = _db.configBox.get("authorization.type");
      String? authorizationValue = _db.configBox.get("authorization.value");
      if (authorizationType != null) {
        if (authorizationType == "bearer") {
          if (authorizationValue != null) {
            header["Authorization"] = "bearer $authorizationValue";
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

  String? _extractAuthorizationValue(Map<String, dynamic> target, String expectIn) {
    String? name = _db.configBox.get("authorization.name");
    if (name != null) {
      if (expectIn == "body") {
        String token = target[name];
        return token;
      }
    }
    return null;
  }

  /// Initilize the client before doing any further operation. It is a compulsory step
  Future<void> initialize() async {
    await _initiateDB();
  }

  /// returns false if client is not initialized and true if client is initialized.
  bool get isInitialized => _isInitialized;

  /// returns all saved and valid cookies
  Map<String, CookieModel> get cookies => _cookie;

  /// set headers that will be attached to every request you make
  setDefaultHeaders(Map<String, String> headers) {
    _headers.addAll(headers);
  }

  /// set basePath for the client. It can also be set while initializing Vajra class
  setBasePath(String basePath) {
    _basePath = basePath;
  }

  /// set default authorization scheme that will be used with every request which will be marked as secured.
  setDefaultAuthorization(Scheme scheme, String expectIn, String name) {
    _db.configBox.put("authorization.type", scheme.name);
    _db.configBox.put("authorization.expectIn", expectIn);
    _db.configBox.put("authorization.name", name);
  }

  /// Make Get Request.
  /// 
  /// ### Parameters:
  /// 
  /// `endPoint` -> API end point
  /// 
  /// `secured` -> Set it to `true` if this is a secure endpoint. It will send the default authorization secheme to get authorized
  /// 
  /// `sendCookie` -> Set it to `true` if you want to send cookie to server.
  /// 
  /// `expectAuthorization` -> Set it to `true` if you expect any kind of authorization token in resposne body.
  /// 
  /// `headers` -> Set headers
  /// 
  /// `queries` -> Set query parameter
  /// 
  /// ### Example
  /// ```dart
  /// 
  /// client.get("/testget", true, true, expectAuthorization: true, headers: {"service": "vajra"})
  /// 
  /// ```
  Future<VajraResponse> get(String endPoint, {bool secured = false, bool sendCookie = false, bool expectAuthorization = false, Map<String, String>? headers, Map<String, String>? queries}) async {
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

        for (CookieModel c in cookies) {
          if (c.name != null) {
            savedCookies.cookies.add(c.name!);
            _db.configBox.put(c.name, c.toJson());
            _cookie[c.name!] = c;
            
          }
        }
        _db.configBox.put("cookies", savedCookies.toJson());

        body = json.decode(String.fromCharCodes(response.bodyBytes));

        if (expectAuthorization) {
          String? expectIn = _db.configBox.get("authorization.expectIn");
          if (expectIn != null) {
            if (expectIn == "body") {
              String? token = _extractAuthorizationValue(body, expectIn);
              if (token != null) {
                _db.configBox.put("authorization.value", token);
              }
            }
          }
        }

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

  /// Make Post Request
  /// 
  /// ### Parameters:
  /// 
  /// `endPoint` -> API end point
  /// 
  /// `body` -> request body
  /// 
  /// `secured` -> Set it to `true` if this is a secure endpoint. It will send the default authorization secheme to get authorized
  /// 
  /// `sendCookie` -> Set it to `true` if you want to send cookie to server.
  /// 
  /// `expectAuthorization` -> Set it to `true` if you expect any kind of authorization token in resposne body.
  /// 
  /// `headers` -> Set headers
  /// 
  /// `queries` -> Set query parameter
  /// 
  /// ### Example
  /// ```dart
  /// 
  /// client.post("/testpost", {"test": "post"}, secured: true, sendCookie: true, expectAuthorization: true, headers: {"service": "vajra"})
  /// 
  /// ```
  Future<VajraResponse> post(String endPoint, Map<String, dynamic> body, {bool secured = false, bool sendCookie = false, bool expectAuthorization = false, Map<String, String>? headers, Map<String, String>? queries}) async {

    String uri = _basePath + endPoint;

    Map<String, String> header = _attachHeaders(secured, sendCookie, headers);

    uri = _attachQueries(uri, queries);

    bool isError = true;
    int responseCode = -1;
    dynamic responseBody;
    String errorMsg = "";

    try {

      String jsonBody = json.encode(body);
      http.Response response = await http.post(
        Uri.parse(uri),
        headers: header,
        body: jsonBody
      );

      responseCode = response.statusCode;
      if (response.statusCode >= 200 && response.statusCode <= 204) {
        isError = false;

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

        for (CookieModel c in cookies) {
          if (c.name != null) {
            savedCookies.cookies.add(c.name!);
            _db.configBox.put(c.name, c.toJson());
            _cookie[c.name!] = c;
            
          }
        }
        _db.configBox.put("cookies", savedCookies.toJson());

        responseBody = json.decode(String.fromCharCodes(response.bodyBytes));

        if (expectAuthorization) {
          String? expectIn = _db.configBox.get("authorization.expectIn");
          if (expectIn != null) {
            if (expectIn == "body") {
              String? token = _extractAuthorizationValue(responseBody, expectIn);
              if (token != null) {
                _db.configBox.put("authorization.value", token);
              }
            }
          }
        }

      } else {
        responseBody = json.decode(String.fromCharCodes(response.bodyBytes));
        if (responseBody is String) {
          errorMsg = responseBody;
        }
      }

    } catch (e) {
      errorMsg = "local error";
    }
    
    return VajraResponse(
      responseCode,
      responseBody,
      isError,
      errorMsg
    );
  }

  /// Make Put Request
  /// 
  /// ### Parameters:
  /// 
  /// `endPoint` -> API end point
  /// 
  /// `body` -> request body
  /// 
  /// `secured` -> Set it to `true` if this is a secure endpoint. It will send the default authorization secheme to get authorized
  /// 
  /// `sendCookie` -> Set it to `true` if you want to send cookie to server.
  /// 
  /// `expectAuthorization` -> Set it to `true` if you expect any kind of authorization token in resposne body.
  /// 
  /// `headers` -> Set headers
  /// 
  /// `queries` -> Set query parameter
  /// 
  /// ### Example
  /// ```dart
  /// 
  /// client.put("/testput", {"test": "put"}, secured: true, sendCookie: true, expectAuthorization: true, headers: {"service": "vajra"});
  /// 
  /// ```
  Future<VajraResponse>put(String endPoint, Map<String, dynamic> body, {bool secured = false, bool sendCookie = false, bool expectAuthorization = false, Map<String, String>? headers, Map<String, String>? queries}) async {
    String uri = _basePath + endPoint;

    Map<String, String> header = _attachHeaders(secured, sendCookie, headers);

    uri = _attachQueries(uri, queries);

    bool isError = true;
    int responseCode = -1;
    dynamic responseBody;
    String errorMsg = "";

    try {
      String jsonBody = json.encode(body);
      http.Response response = await http.put(
        Uri.parse(uri),
        headers: header,
        body: jsonBody
      );
      responseCode = response.statusCode;
      if (response.statusCode >= 200 && response.statusCode <= 204) {
        isError = false;

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

        for (CookieModel c in cookies) {
          if (c.name != null) {
            savedCookies.cookies.add(c.name!);
            _db.configBox.put(c.name, c.toJson());
            _cookie[c.name!] = c;
            
          }
        }
        _db.configBox.put("cookies", savedCookies.toJson());

        responseBody = json.decode(String.fromCharCodes(response.bodyBytes));

        if (expectAuthorization) {
          String? expectIn = _db.configBox.get("authorization.expectIn");
          if (expectIn != null) {
            if (expectIn == "body") {
              String? token = _extractAuthorizationValue(responseBody, expectIn);
              if (token != null) {
                _db.configBox.put("authorization.value", token);
              }
            }
          }
        }
      } else {
        responseBody = json.decode(String.fromCharCodes(response.bodyBytes));
        if (responseBody is String) {
          errorMsg = responseBody;
        }
      }
    } catch (e) {
      errorMsg = "local error";
    }
    
    return VajraResponse(
      responseCode,
      responseBody,
      isError,
      errorMsg
    );
  }

  /// Make Delete Request
  /// 
  /// ### Parameters:
  /// 
  /// `endPoint` -> API end point
  /// 
  /// `body` -> request body
  /// 
  /// `secured` -> Set it to `true` if this is a secure endpoint. It will send the default authorization secheme to get authorized
  /// 
  /// `sendCookie` -> Set it to `true` if you want to send cookie to server.
  /// 
  /// `expectAuthorization` -> Set it to `true` if you expect any kind of authorization token in resposne body.
  /// 
  /// `headers` -> Set headers
  /// 
  /// `queries` -> Set query parameter
  /// 
  /// ### Example
  /// ```dart
  /// 
  /// client.delete("/testdelete", {"test": "delete"}, secured: true, sendCookie: true, expectAuthorization: true, headers: {"service": "vajra"});
  /// 
  /// ```
  Future<VajraResponse>delete(String endPoint, Map<String, dynamic> body,  {bool secured = false, bool sendCookie = false, bool expectAuthorization = false, Map<String, String>? headers, Map<String, String>? queries}) async {
    String uri = _basePath + endPoint;

    Map<String, String> header = _attachHeaders(secured, sendCookie, headers);

    uri = _attachQueries(uri, queries);

    bool isError = true;
    int responseCode = -1;
    dynamic responseBody;
    String errorMsg = "";

    try {
      String jsonBody = json.encode(body);
      http.Response response = await http.delete(
        Uri.parse(uri),
        headers: header,
        body: jsonBody
      );
      responseCode = response.statusCode;
      if (response.statusCode >= 200 && response.statusCode <= 204) {
        isError = false;

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

        for (CookieModel c in cookies) {
          if (c.name != null) {
            savedCookies.cookies.add(c.name!);
            _db.configBox.put(c.name, c.toJson());
            _cookie[c.name!] = c;
            
          }
        }
        _db.configBox.put("cookies", savedCookies.toJson());

        responseBody = json.decode(String.fromCharCodes(response.bodyBytes));

        if (expectAuthorization) {
          String? expectIn = _db.configBox.get("authorization.expectIn");
          if (expectIn != null) {
            if (expectIn == "body") {
              String? token = _extractAuthorizationValue(responseBody, expectIn);
              if (token != null) {
                _db.configBox.put("authorization.value", token);
              }
            }
          }
        }
      } else {
        responseBody = json.decode(String.fromCharCodes(response.bodyBytes));
        if (responseBody is String) {
          errorMsg = responseBody;
        }
      }
    } catch (e) {
      errorMsg = "local error";
    }
    
    return VajraResponse(
      responseCode,
      responseBody,
      isError,
      errorMsg
    );
  }
}

Vajra getVajra() {
  return GetIt.I.get<Vajra>(instanceName: "vajra");
}

/// response class for request that you make.
class VajraResponse {
  int statusCode;
  dynamic body;
  bool isError;
  String errorMessage;

  VajraResponse(this.statusCode, this.body, this.isError, this.errorMessage);

  @override
  String toString() {
    Map<String, dynamic> mapData = {
      "statusCode": statusCode,
      "body": body,
      "isError": isError,
      "errorMessage": errorMessage
    };
    return json.encode(mapData);
  }
}
