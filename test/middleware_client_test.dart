import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_middleware/http_middleware.dart';
import 'package:http_middleware/src/base_client_mixin.dart';
import 'package:http_middleware/src/middlewares/handler_middleware.dart';
import 'package:test/test.dart';

void main() {
  final mockClient = MockClient((request) async => http.Response('response: ${request.body}', 200, request: request));
  final url = Uri.parse('http://example.com');
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

    test('middleware close', () {
      var catchOnClose = 0;
      final client = MiddlewareClient.build(mockClient, [
        HandlersMiddleware(onClose: () => catchOnClose++),
        HandlersMiddleware(onClose: () => catchOnClose++),
      ]);
      client.close();
      expect(catchOnClose, 2);
    });
  });

  group('intercept send methods', () {
    test('send methods', () async {
      http.BaseResponse? interceptedResponse;
      final client = MiddlewareClient.build(mockClient, [
        HandlersMiddleware(responseHandler: (http.BaseResponse r) {
          interceptedResponse = r;
        }),
      ]);
      expect(await client.sendClient(createRequest('GET', url, null)), isA<http.StreamedResponse>());
      expect(interceptedResponse, null);

      await client.send(createRequest('GET', url, null));
      expect(interceptedResponse, isA<http.StreamedResponse>());
      await client.sendNonStreamedResponse(createRequest('GET', url, null));
      expect(interceptedResponse, isA<http.Response>());
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

    test('headers client', () async {
      Map<String, String>? headers;
      final client = MiddlewareClient.build(HeadersClient(headers: {'test': 'test'}, client: mockClient), [
        HandlersMiddleware(requestHandler: (http.BaseRequest r) {
          headers = r.headers;
        }),
      ]);
      await client.get(url);
      expect(headers, {'test': 'test'});
    });
  });
}
