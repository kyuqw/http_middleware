import 'package:http/http.dart' as http;

/// [url] must be a [String] or [Uri].
/// [queryParameters] [Map.values] must be a [String] or [Iterable] of [String].
Uri mergeUrlQueryParameters(dynamic url, Map<String, dynamic /*String|Iterable<String>*/ >? queryParameters) {
  final _url = urlFromUriOrString(url);
  if (queryParameters == null || queryParameters.isEmpty) return _url;

  final parameters = Map<String, List<String>>.from(_url.queryParametersAll); // parameters is unmodifiable
  queryParameters.forEach((key, value) {
    final values = List<String>.from(parameters[key] ?? []);
    parameters[key] = values;
    if (value == null || value is String) {
      values.add(value ?? '');
    } else {
      Iterable list = value;
      for (final val in list) {
        values.add(val ?? '');
      }
    }
    if (values.isEmpty) values.add('');
  });
  return _url.replace(queryParameters: parameters);
}

Uri urlFromUriOrString(uri) => uri is String ? Uri.parse(uri) : uri as Uri;

extension UriExtensions on Uri {
  /// Return Uri that differs from this only sorted queryParameters.
  ///
  /// If this [Uri] does not have a queryParameters, it is itself returned.
  Uri sortQueryParams() {
    final uri = this;
    final params = uri.queryParametersAll;
    if (params.isEmpty) return uri;

    final data = <String, List<String>>{};
    for (final key in params.keys.toList()..sort()) {
      var values = params[key]!;
      if (values.length > 1) {
        values = List.from(values)..sort();
      }
      data[key] = values;
    }
    return uri.replace(queryParameters: data);
  }
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
