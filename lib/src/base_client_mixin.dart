import 'dart:convert';

import 'package:http/http.dart' show BaseClient, BaseRequest, Request, Response;

import 'utils.dart';

/// [BaseClientMixin] extents [BaseClient] and override basic request methods throw [sendNonStreamed].
mixin BaseClientMixin implements BaseClient {
  @override
  Future<Response> head(url, {Map<String, String>? headers}) => sendNonStreamed('HEAD', url, headers);

  @override
  Future<Response> get(url, {Map<String, String>? headers}) => sendNonStreamed('GET', url, headers);

  @override
  Future<Response> post(url, {Map<String, String>? headers, body, Encoding? encoding}) =>
      sendNonStreamed('POST', url, headers, body, encoding);

  @override
  Future<Response> put(url, {Map<String, String>? headers, body, Encoding? encoding}) =>
      sendNonStreamed('PUT', url, headers, body, encoding);

  @override
  Future<Response> patch(url, {Map<String, String>? headers, body, Encoding? encoding}) =>
      sendNonStreamed('PATCH', url, headers, body, encoding);

  @override
  Future<Response> delete(url, {Map<String, String>? headers}) => sendNonStreamed('DELETE', url, headers);

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  ///
  /// [BaseClient] _sendUnstreamed method public implementation.
  Future<Response> sendNonStreamed(String method, url, Map<String, String>? headers, [body, Encoding? encoding]) async {
    final request = createRequest(method, url, headers, body, encoding);
    return sendNonStreamedResponse(request);
  }

  /// Sends [BaseRequest] and returns a non-streaming [Response].
  Future<Response> sendNonStreamedResponse(BaseRequest request) async {
    return Response.fromStream(await send(request));
  }
}

/// Create a non-streaming [Request] from params.
Request createRequest(String method, url, [Map<String, String>? headers, body, Encoding? encoding]) {
  final request = Request(method, urlFromUriOrString(url));

  if (headers != null) request.headers.addAll(headers);
  if (encoding != null) request.encoding = encoding;
  if (body != null) {
    if (body is String) {
      request.body = body;
    } else if (body is List) {
      request.bodyBytes = body.cast<int>();
    } else if (body is Map) {
      request.bodyFields = body.cast<String, String>();
    } else {
      throw ArgumentError('Invalid request body "$body".');
    }
  }
  return request;
}
