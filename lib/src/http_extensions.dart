import 'dart:convert' as convert;

import 'package:http/http.dart' as http;

import 'base_client_mixin.dart';
import 'response_parser.dart';
import 'utils.dart' as utils;

enum HttpMethod { head, get, post, put, patch, delete }

extension HttpMethodExtensions on HttpMethod {
  String get string => _httpMethodToString(this);
}

extension ClientExtensions on http.BaseClient {
  /// [url] must be a [String] or [Uri].
  Future<http.Response> fetch(
    Uri url, {
    HttpMethod? method,
    Map<String, String>? headers,
    body,
    Map<String, dynamic /*String|Iterable<String>*/ >? queryParameters,
  }) {
    final _url = utils.mergeUrlQueryParameters(url, queryParameters);
    return _sendUnstreamed((method ?? HttpMethod.get).string, _url, headers, body);
  }

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<http.Response> _sendUnstreamed(String method, url, Map<String, String>? headers,
      [body, convert.Encoding? encoding]) async {
    if (this is BaseClientMixin) {
      return (this as BaseClientMixin).sendNonStreamed(method, url, headers, body, encoding);
    }
    final request = createRequest(method, url, headers, body, encoding);
    return http.Response.fromStream(await send(request));
  }
}

extension BaseResponseExtensions on http.BaseResponse {
  bool get ok => utils.isResponseOk(this.statusCode);

  bool get isClientError => utils.isResponseClientError(this.statusCode);

  bool get isServerError => utils.isResponseServerError(this.statusCode);
}

extension ResponseExtensions on http.Response {
  T? jsonModel<T>(JsonModelFactory<T> factoryMethod, {T? defaultValue, JsonDecoderReviver? reviver}) {
    return JsonModelResponseParser<T>().parse(this, factoryMethod, defaultValue: defaultValue, reviver: reviver);
  }

  List<T>? listJsonModel<T>(JsonModelFactory<T> factoryMethod, {List<T>? defaultValue, JsonDecoderReviver? reviver}) {
    return ListJsonModelResponseParser<T>().parse(this, factoryMethod, defaultValue: defaultValue, reviver: reviver);
  }
}

extension StreamedResponseExtensions on http.StreamedResponse {
  static http.StreamedResponse fromResponse(http.Response response) {
    final stream = Stream.value(response.bodyBytes);
    return http.StreamedResponse(stream, response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase);
  }
}

String _httpMethodToString(HttpMethod method) {
  final value = method.toString().split('.').last;
  return value.toUpperCase();
}
