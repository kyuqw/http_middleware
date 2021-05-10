import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_middleware/http_middleware.dart';
import 'package:http_middleware/matchers/matcher.dart' as match;
import 'package:http_middleware/matchers/request_matcher.dart';
import 'package:http_middleware/src/base_client_mixin.dart';
import 'package:http_middleware/src/middlewares/auth_middleware.dart';
import 'package:test/test.dart';

void main() {
  const base = 'http://example.com';
  group('auth middleware', () {
    var catchAddAuthorizationData = false;
    var catchOnAuthorization = false;
    var catchOnUnauthorized = false;
    var reset = () {
      catchAddAuthorizationData = false;
      catchOnAuthorization = false;
      catchOnUnauthorized = false;
    };

    final authUrl = '$base/auth';
    final m = _TestAuthMiddleware(
      listenableRequests: RequestDomainMatcher(base),
      authEndpointsMatcher: RequestUrlMatcher(authUrl),
      onAddAuthorizationData: (r) {
        catchAddAuthorizationData = true;
        return r;
      },
      onAuthorization: (_) => catchOnAuthorization = true,
      onUnauthorized: (_) => catchOnUnauthorized = true,
    );

    final listenableRequest = createRequest('GET', base);
    final nonListenableRequest = createRequest('GET', 'http://another.example.com');
    test('addAuthorizationData', () async {
      reset();

      await m.interceptRequest(nonListenableRequest);
      expect(catchAddAuthorizationData, false);
      await m.interceptRequest(listenableRequest);
      expect(catchAddAuthorizationData, true);

      expect(catchOnAuthorization, false);
      expect(catchOnUnauthorized, false);
    });

    test('handleAuthorization', () async {
      reset();

      await m.interceptResponse(http.Response('', 200, request: listenableRequest));
      await m.interceptResponse(http.Response('', 200, request: nonListenableRequest));
      await m.interceptResponse(http.Response('', 400, request: listenableRequest));
      await m.interceptResponse(http.Response('', 500, request: listenableRequest));
      expect(catchOnAuthorization, false);

      final authRequest = createRequest('GET', authUrl);
      await m.interceptResponse(http.Response('', 400, request: authRequest));
      expect(catchOnAuthorization, false);

      await m.interceptResponse(http.Response('', 200, request: authRequest));
      expect(catchOnAuthorization, true);

      expect(catchAddAuthorizationData, false);
      expect(catchOnUnauthorized, false);
    });

    test('handleUnauthorized', () async {
      reset();

      await m.interceptResponse(http.Response('', 200, request: listenableRequest));
      await m.interceptResponse(http.Response('', 401, request: nonListenableRequest));
      expect(catchOnUnauthorized, false);

      await m.interceptResponse(http.Response('', 401, request: listenableRequest));
      expect(catchOnUnauthorized, true);

      expect(catchAddAuthorizationData, false);
      expect(catchOnAuthorization, false);
    });
  });

  group('jwt auth middleware', () {
    test('listenable requests matcher', () async {
      const token = '123123123';
      final storage = InMemoryTokenStorage(token: token);
      final m = JwtAuthMiddleware(storage, listenableRequests: RequestDomainMatcher(base));

      var request = await m.interceptRequest(createRequest('GET', 'http://another.example.com'));
      expect(request.headers[m.authorizationHeader], null);
      request = await m.interceptRequest(
        createRequest('GET', 'http://another.example.com', {m.authorizationHeader: token}),
      );
      expect(request.headers[m.authorizationHeader], token);
      await m.interceptResponse(http.Response(jsonEncode({'token': '123'}), 200, request: request));
      expect(await storage.getAuthToken(), token);
      await m.interceptResponse(http.Response(jsonEncode({'token': '123'}), 401, request: request));
      expect(await storage.getAuthToken(), token);

      request = await m.interceptRequest(createRequest('GET', base, {m.authorizationHeader: token}));
      expect(request.headers[m.authorizationHeader], token);
      request = await m.interceptRequest(createRequest('GET', base));
      expect(request.headers[m.authorizationHeader], m.createAuthorizationValue(token));
      await m.interceptResponse(http.Response(jsonEncode({'token': '123'}), 200, request: request));
      expect(await storage.getAuthToken(), '123');
      await m.interceptResponse(http.Response(jsonEncode({'token': '123'}), 401, request: request));
      expect(await storage.getAuthToken(), null);
    });

    test('createAuthorizationValue', () async {
      const token = '123123123';
      var m = JwtAuthMiddleware(InMemoryTokenStorage(token: token));
      expect(m.createAuthorizationValue(token), 'Bearer $token');
      m = JwtAuthMiddleware(InMemoryTokenStorage(token: token), prefix: '');
      expect(m.createAuthorizationValue(token), token);
      m = JwtAuthMiddleware(InMemoryTokenStorage(token: token), prefix: 'qwe');
      expect(m.createAuthorizationValue(token), 'qwe$token');
    });
  });
}

class _TestAuthMiddleware extends AuthMiddleware {
  final FutureOr<http.BaseRequest> Function(http.BaseRequest request) onAddAuthorizationData;
  final Function(http.BaseResponse response) onAuthorization;
  final Function(http.BaseResponse response) onUnauthorized;

  _TestAuthMiddleware({
    match.Matcher<BaseRequest> listenableRequests = const match.ConstMatcher.always(),
    match.Matcher<BaseRequest> authEndpointsMatcher = const match.ConstMatcher.always(),
    required this.onAddAuthorizationData,
    required this.onAuthorization,
    required this.onUnauthorized,
  }) : super(
          listenableRequests: listenableRequests,
          authEndpointsMatcher: authEndpointsMatcher,
          onUnauthorized: onUnauthorized,
        );

  @override
  FutureOr<http.BaseRequest> addAuthorizationData(http.BaseRequest request) {
    return onAddAuthorizationData.call(request);
  }

  @override
  FutureOr<void> handleAuthorization(http.BaseResponse response) {
    onAuthorization(response);
  }
}
