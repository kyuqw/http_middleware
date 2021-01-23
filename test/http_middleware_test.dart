import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http_middleware/http_middleware.dart';

void main() {
  test('middleware client', () {
    // TODO: middleware client tests implementation.
    final client = MiddlewareClient.build(http.Client(), []);
    expect(client != null, true);
    // expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  });
}
