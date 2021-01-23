import 'package:http/http.dart' as http;

/// [queryParameters] value must be a [String] or [Iterable] of [String].
String createUrl(String url, {Map<String, dynamic /*String|Iterable<String>*/ >? queryParameters}) {
  assert(queryParameters == null || queryParameters is String || queryParameters is Iterable<String>);
  var _url = Uri.parse(url);
  Map<String, List<String>>? parameters = _url.queryParametersAll;
  if (queryParameters != null && queryParameters.isNotEmpty) {
    parameters = Map<String, List<String>>.from(parameters); // parameters is unmodifiable

    queryParameters.forEach((key, value) {
      final values = parameters![key] ?? <String>[];
      if (value == null || value is String) {
        values.add(value);
      } else {
        values.addAll(value);
      }
    });
  }
  if (parameters.isEmpty) parameters = null;
  _url = Uri(scheme: _url.scheme, host: _url.host, path: _url.path, queryParameters: parameters, port: _url.port);
  return _url.toString();
}

bool isResponseOk(int statusCode) {
  return statusCode >= 200 && statusCode < 300;
}

bool isResponseClientError(int statusCode) {
  return statusCode >= 400 && statusCode < 500;
}

bool isResponseServerError(int statusCode) {
  return statusCode >= 500 && statusCode < 600;
}

http.BaseRequest mergeHeaders(http.BaseRequest request, Map<String, String>? headers, {bool override = false}) {
  if (headers == null || headers.isEmpty) return request;
  if (override) {
    request.headers.addAll(headers);
    return request;
  }
  headers.forEach((key, value) {
    if (!request.headers.containsKey(key)) request.headers[key] = value;
  });
  return request;
}
