# Example

```dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:vajra/pkg/security_scheme.dart';
import 'package:vajra/vajra.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory directory = await getApplicationDocumentsDirectory();

  Vajra client = Vajra(directory.path, basePath: "http://10.0.2.2:8000");
  await client.initialize();
  client.setDefaultAuthorization(SecurityScheme.bearer, "body", "token");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vajra Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late Vajra client;

  String response = "";

  @override
  void initState() {
    super.initState();

    client = getVajra();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Vajra"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_rounded),
            onPressed: () {
            },
          )
        ],
      ),

      body: Column(
        children: [
          ListTile(
            tileColor: Colors.green,
            title: const Text("Get"),
            trailing: IconButton(
              icon: const Icon(Icons.api_rounded),
              onPressed: () async {
                if (client.isInitialized) {
                  final VajraResponse vajraResponse = await client.get("/testget", secured: true, sendCookie: true, expectAuthorization: true, headers: {"service": "vajra"});
                  setState(() {
                    response = json.encode(vajraResponse.body);
                  });
                } else {
                  print("client is not initialized");
                }
              },
            ),
          ),
          ListTile(
            tileColor: Colors.orange,
            title: const Text("Post"),
            trailing: IconButton(
              icon: const Icon(Icons.api_rounded),
              onPressed: () async {
                if (client.isInitialized) {
                  final VajraResponse vajraResponse = await client.post("/testpost", {"test": "post"}, secured: true, sendCookie: true, expectAuthorization: true, headers: {"service": "vajra"});
                  setState(() {
                    response = json.encode(vajraResponse.body);
                  });
                } else {
                  print("client is not initialized");
                }
              },
            ),
          ),
          ListTile(
            tileColor: Colors.yellow,
            title: const Text("Put"),
            trailing: IconButton(
              icon: const Icon(Icons.api_rounded),
              onPressed: () async {
                if (client.isInitialized) {
                  final VajraResponse vajraResponse = await client.put("/testput", {"test": "put"}, secured: true, sendCookie: true, expectAuthorization: true, headers: {"service": "vajra"});
                  setState(() {
                    response = json.encode(vajraResponse.body);
                  });
                } else {
                  print("client is not initialized");
                }
              },
            ),
          ),
          ListTile(
            tileColor: Colors.red,
            title: const Text("Delete"),
            trailing: IconButton(
              icon: const Icon(Icons.api_rounded),
              onPressed: () async {
                if (client.isInitialized) {
                  final VajraResponse vajraResponse = await client.delete("/testdelete", {"test": "delete"}, secured: true, sendCookie: true, expectAuthorization: true, headers: {"service": "vajra"});
                  setState(() {
                    response = json.encode(vajraResponse.body);
                  });
                } else {
                  print("client is not initialized");
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(response),
          )
        ]
      )
    );
  }
}

```
