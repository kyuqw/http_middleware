import '../../http_middleware.dart';
import '../../matchers/matcher.dart';
import '../response_parser.dart';

const String AuthorizationHeader = 'Authorization';

typedef UnauthorizedHandler = Function(BaseResponse response);

abstract class AuthMiddleware extends Middleware {
  final Matcher<BaseRequest> listenableRequests;
  final Matcher<BaseRequest> authEndpointsMatcher;
  final UnauthorizedHandler? onUnauthorized;

  AuthMiddleware({
    this.listenableRequests = const ConstMatcher.always(),
    this.authEndpointsMatcher = const ConstMatcher.always(),
    this.onUnauthorized,
  });

  @override
  FutureOr<BaseRequest> interceptRequest(BaseRequest request) async {
    if (isListenableRequest(request)) request = await addAuthorizationData(request);
    return super.interceptRequest(request);
  }

  @override
  FutureOr<BaseResponse> interceptResponse(BaseResponse response) async {
    if (response.request != null && isListenableRequest(response.request!)) {
      if (isUnauthorizedResponse(response)) {
        await handleUnauthorized(response);
      } else if (isAuthEndpointResponse(response)) {
        await handleAuthorization(response);
      }
    }
    return super.interceptResponse(response);
  }

  bool isListenableRequest(BaseRequest request) {
    return listenableRequests.match(request);
  }

  bool isAuthEndpointResponse(BaseResponse response) {
    if (!response.ok || response.request == null) return false;
    return authEndpointsMatcher.match(response.request!);
  }

  bool isUnauthorizedResponse(BaseResponse response) {
    return response.statusCode == 401;
  }

  FutureOr<BaseRequest> addAuthorizationData(BaseRequest request);

  FutureOr<void> handleAuthorization(BaseResponse response);

  FutureOr<void> handleUnauthorized(BaseResponse response) {
    onUnauthorized?.call(response);
  }
}

class JwtAuthMiddleware extends AuthMiddleware {
  final AuthTokenStorage storage;
  final String authorizationHeader;
  final String prefix;
  final BaseResponseParser<String?> tokenParser;

  JwtAuthMiddleware(
    this.storage, {
    Matcher<BaseRequest> listenableRequests = const ConstMatcher.always(),
    Matcher<BaseRequest> authEndpointsMatcher = const ConstMatcher.always(),
    this.prefix = 'Bearer ',
    this.tokenParser = const JsonResponseTokenParser(),
    UnauthorizedHandler? onUnauthorized,
    this.authorizationHeader = AuthorizationHeader,
  }) : super(
          listenableRequests: listenableRequests,
          authEndpointsMatcher: authEndpointsMatcher,
          onUnauthorized: onUnauthorized,
        );

  FutureOr<BaseRequest> addAuthorizationData(BaseRequest request) async {
    if (request.headers.containsKey(authorizationHeader)) return request;
    final token = await storage.getAuthToken();
    if (token == null || token.isEmpty) return request;
    request.headers[authorizationHeader] = createAuthorizationValue(token);
    return request;
  }

  String createAuthorizationValue(String token) {
    if (token.startsWith(prefix)) return token;
    return '$prefix$token';
  }

  FutureOr<void> handleAuthorization(BaseResponse response) async {
    final token = tokenParser.parse(response);
    if (token == null) return;
    await storage.setAuthToken(token);
  }

  FutureOr<void> handleUnauthorized(BaseResponse response) async {
    await storage.clearAuthToken();
    super.handleUnauthorized(response);
  }
}

mixin AuthTokenStorage {
  FutureOr<String?> getAuthToken();

  FutureOr<void> setAuthToken(String? token);

  FutureOr<void> clearAuthToken();
}

class InMemoryTokenStorage with AuthTokenStorage {
  String? token;

  InMemoryTokenStorage({this.token});

  @override
  FutureOr<String?> getAuthToken() => token;

  @override
  FutureOr<void> setAuthToken(String? token) => this.token = token;

  @override
  FutureOr<void> clearAuthToken() => token = null;
}

class JsonResponseTokenParser extends BaseResponseParser<String?> {
  final String tokenKey;
  final JsonDecoderReviver? reviver;

  const JsonResponseTokenParser({this.tokenKey = 'token', this.reviver});

  @override
  String? parse(BaseResponse response) {
    if (response is! Response) return null;
    final data = JsonResponseParser(reviver: reviver).parse(response);
    if (data == null || data is! Map || !data.containsKey(tokenKey)) return null;
    return data[tokenKey];
  }
}
