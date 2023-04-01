
import 'package:flutter_test/flutter_test.dart';
import 'package:vajra/vajra.dart';

void main() {

  test("geting set-cookie header format", () async {
    Vajra client = Vajra("<directory.path>",basePath: "http://127.0.0.1:8000");
    // await client.initialize();
    final VajraResponse response = await client.get("/setcookie");
    expect(response.statusCode, 200);
  });
}
