import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_middleware/http_middleware.dart';
import 'package:http_middleware/src/middlewares/handler_middleware.dart';
import 'package:test/test.dart';

void main() {
  final mockClient = MockClient((request) async => http.Response('response: ${request.body}', 200, request: request));
  const url = 'http://example.com';
  group('middleware()', () {
    test('middlewares list', () {
      expect(MiddlewareClient.build(mockClient, []).middlewares.length, 0);
      final m = HandlersMiddleware(requestHandler: (_) {});
      final mClient = MiddlewareClient.build(mockClient, [m, m, m]);
      expect(mClient.middlewares.length, 3);
      expect(() => mClient.middlewares[2] = m, throwsUnsupportedError);
      expect(() => mClient.middlewares.add(m), throwsUnsupportedError);
      expect(MiddlewareClient.build(mClient, [m, m]).middlewares.length, 5);
    });
  });

  group('intercepts order', () {
    final reqFn = (String name, List<String> list) => (_) {
          list.add('$name:request');
        };
    final resFn = (String name, List<String> list) => (_) {
          list.add('$name:response');
        };
    test('client', () async {
      final orderList = <String>[];
      final client = MiddlewareClient.build(mockClient, [
        HandlersMiddleware(requestHandler: reqFn('m1', orderList), responseHandler: resFn('m1', orderList)),
        HandlersMiddleware(requestHandler: reqFn('m2', orderList), responseHandler: resFn('m2', orderList)),
      ]);
      await client.get(url);
      expect(orderList, ['m1:request', 'm2:request', 'm2:response', 'm1:response']);
    });

    test('middleware client', () async {
      final orderList = <String>[];
      final client = MiddlewareClient.build(
        MiddlewareClient.build(mockClient, [
          HandlersMiddleware(requestHandler: reqFn('m1', orderList), responseHandler: resFn('m1', orderList)),
          HandlersMiddleware(requestHandler: reqFn('m2', orderList), responseHandler: resFn('m2', orderList)),
        ]),
        [HandlersMiddleware(requestHandler: reqFn('m3', orderList), responseHandler: resFn('m3', orderList))],
      );
      await client.get(url);
      expect(orderList, ['m3:request', 'm1:request', 'm2:request', 'm2:response', 'm1:response', 'm3:response']);
    });
  });
}
