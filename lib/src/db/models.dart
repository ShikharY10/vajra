import 'dart:convert';

class CookieModel {
  String? name;
  String? value;
  String? path;
  String? domain;
  DateTime? expires;
  bool? isSecure;
  bool? isHttpOnly;

  CookieModel({
    this.name, 
    this.value, 
    this.path, 
    this.domain,
    this.expires,
    this.isSecure,
    this.isHttpOnly
  });

  String toJson() {
    Map<String, dynamic> mapData = {
      "name": name,
      "value": value,
      "path": path,
      "domain": domain,
      "expires": expires!.toIso8601String(),
      "isSecure": isSecure,
      "isHttpOnly": isHttpOnly
    };
    return json.encode(mapData);
  }

  static CookieModel fromJson(String jsonEncoded) {
    Map<String, dynamic> mapData = json.decode(jsonEncoded);
    return CookieModel(
      name: mapData["name"],
      value: mapData["value"],
      path: mapData["path"],
      domain: mapData["domain"],
      expires: DateTime.parse(mapData["expires"]),
      isSecure: mapData["isSecure"],
      isHttpOnly: mapData["isHttpOnly"],
    );
  }

  @override
  String toString() {
    return toJson();
  }
}

class Cookies {
  final List<String> cookies = [];

  String toJson() {
    String jsonEncode = json.encode(cookies);
    return jsonEncode;
  }

  static Cookies fromJson(String jsonEncoded) {
    List<dynamic> newCookies = json.decode(jsonEncoded);

    List<String> cookies = [];
    
    for (var value in newCookies) {
      cookies.add(value);
    }

    Cookies c = Cookies();
    c.cookies.addAll(cookies);

    return c;
  }
}

class Header {
  final Map<String, String> headers = {};
  
  void add(String key, value) {
    headers[key] = value;
  }

  void remove(String key) {
    headers.remove(key);
  }

  String toJson() {
    return json.encode(headers);
  }

  static Header fromJson(String jsonData) {
    Header header = Header();

    Map<String, String> mapData = json.decode(jsonData);
    header.headers.addAll(mapData);

    return header;
  }
}
