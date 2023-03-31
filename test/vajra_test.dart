import 'package:flutter_test/flutter_test.dart';
import 'package:vajra/vajra.dart';

void main() {
  test('adds one to input values', () {
    final calculator = Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
  });

  // test("geting set-cookie header format", () async {
  //   Vajra client = Vajra("",basePath: "http://127.0.0.1:8000");
  //   // await client.initialize();
  //   final VajraResponse response = await client.get("/setcookie", false, false);
  //   print(response.body);
  //   print(response.errorMessage);
  //   print(response.statusCode);
  // });
}
