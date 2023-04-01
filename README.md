<div align="center">
  <img src="https://github.com/ShikharY10/vajra/raw/main/assets/images/logo.png" alt="Magator Logo" width="320">
  <h1>VAJRA</h1>
  <strong>A HTTP Client Library Written In Dart👩🏽‍💻</strong>
  <h6>Made with ❤️ &nbsp;by developers for developers</h6>
</div>
<br>

A browser like HTTP Client library for flutter applications. It supports automatic cookie saving and attaching, supports automatic attachement of authorization token.

## Usage

TO use this package, add `vajra` as a dependency in your pubspec.yaml file.

### Example

```dart
// Initilize Vajra class in main function and use it anywhere in your app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory directory = await getApplicationDocumentsDirectory();

  // Initializing Vajra class
  Vajra client = Vajra(directory.path, basePath: "http://10.0.2.2:8000");
  await client.initialize();
  client.setDefaultAuthorization(SecurityScheme.bearer, "body", "token");

  runApp(MyApp(directory.path));
}

.
.
.
// access the vajra client anywhere in your application.
Vajra vajraClient = getVajra();
final VajraResponse vajraResponse = await client.get(
  "/testget",
  secured: true,
  sendCookie: true,
  expectAuthorization: true,
  headers: {"service": "vajra"}
);
print(vajraResponse.body);
.
.
.

```

## Features

Use this package in your Flutter app to:

- To automatically save and attach cookies to and from request and response respectively.
- You can also switch off automatic attaching of cookies in request.
- Automatically save and attach authorization scheme/token.
- Initialize once and use it anywhere in your flutter app.
