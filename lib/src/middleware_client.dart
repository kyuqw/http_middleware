import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../http_middleware.dart';
import 'base_client_mixin.dart';
import 'http_extensions.dart';
import 'middleware.dart';

/// [MiddlewareClient] allow add [Middleware] logic and intercept [http.Client] network requests.
class MiddlewareClient extends http.BaseClient with BaseClientMixin {
  @protected
  final http.Client client;
  @protected
  @visibleForTesting
  final List<Middleware> middlewares;
  @protected
  final BaseMiddlewareChain middlewareChain;

  MiddlewareClient._(this.client, this.middlewares, this.middlewareChain);

  factory MiddlewareClient.build(http.Client client, List<Middleware> middlewares) {
    var _client = client;
    var _middlewares = middlewares;
    if (client is MiddlewareClient && client.runtimeType == MiddlewareClient) {
      _client = client.client;
      _middlewares = List.from(middlewares);
      _middlewares.addAll(client.middlewares);
    }
    BaseMiddlewareChain middlewareChain = ClientMiddlewareChain(_client);
    // TODO: MiddlewareClient.build make optional NonStreamedResponseMiddleware??
    middlewareChain = MiddlewareChain(NonStreamedResponseMiddleware(), middlewareChain);
    for (final m in _middlewares.reversed) {
      middlewareChain = MiddlewareChain(m, middlewareChain);
    }
    return MiddlewareClient._(_client, List.unmodifiable(_middlewares), middlewareChain);
  }

  /// call [client] send method without [middlewares].
  Future<http.StreamedResponse> sendClient(http.BaseRequest request) {
    return client.send(request);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await innerSend(request);
    if (response is http.Response) return StreamedResponseExtensions.fromResponse(response);
    return response as http.StreamedResponse;
  }

  @override
  Future<http.Response> sendNonStreamedResponse(http.BaseRequest request) async {
    final response = await innerSend(NonStreamedResponseMiddleware.createNonStreamedRequest(request));
    if (response is http.Response) return response;
    return http.Response.fromStream(response as http.StreamedResponse);
  }

  @protected
  FutureOr<http.BaseResponse> innerSend(http.BaseRequest request) async {
    var r = request;
    if (client is HeadersClient) {
      final c = (client as HeadersClient);
      r = c.mergeHeaders(r, c.headers);
    }
    return middlewareChain.send(r);
  }

  @override
  void close() {
    middlewareChain.close();
  }
}

abstract class BaseMiddlewareChain {
  FutureOr<http.BaseResponse> send(http.BaseRequest request);

  void close() {}
}

class ClientMiddlewareChain extends BaseMiddlewareChain {
  final http.Client client;

  ClientMiddlewareChain(this.client);

  @override
  FutureOr<http.BaseResponse> send(http.BaseRequest request) {
    return client.send(request);
  }

  @override
  void close() {
    client.close();
  }
}

class MiddlewareChain extends BaseMiddlewareChain {
  @protected
  final Middleware middleware;
  @protected
  final BaseMiddlewareChain nextHandler;

  MiddlewareChain(this.middleware, this.nextHandler);

  @override
  FutureOr<http.BaseResponse> send(http.BaseRequest request) {
    return middleware.send(request, nextHandler.send);
  }

  @override
  void close() {
    middleware.close();
    nextHandler.close();
  }
}

/// A [Middleware] that convert [http.StreamedResponse] to [http.Response] when it is necessary.
class NonStreamedResponseMiddleware extends Middleware {
  static String header = 'NonStreamedResponseMiddleware';

  @override
  FutureOr<http.BaseResponse> interceptNextCall(http.BaseRequest request, next) async {
    final needNonStreamed = needNonStreamedResponse(request);
    if (needNonStreamed) request.headers.remove(header);
    final response = await super.interceptNextCall(request, next);
    if (needNonStreamed && response is http.StreamedResponse) return http.Response.fromStream(response);
    return response;
  }

  @protected
  bool needNonStreamedResponse(http.BaseRequest request) {
    return isNonStreamedRequest(request);
  }

  static http.BaseRequest createNonStreamedRequest(http.BaseRequest request) {
    request.headers[header] = 'true';
    return request;
  }

  static bool isNonStreamedRequest(http.BaseRequest request) {
    return request.headers[header] == 'true';
  }
}
