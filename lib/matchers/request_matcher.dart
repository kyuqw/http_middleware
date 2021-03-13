import 'package:http/http.dart' show BaseRequest;

import '../src/http_extensions.dart';
import '../src/utils.dart';
import 'matcher.dart';

class RequestDomainMatcher extends Matcher<BaseRequest> {
  final String domain;
  final bool allowSubdomains;

  /// [url] must be [String] or [Uri].
  RequestDomainMatcher(dynamic url, {this.allowSubdomains = false})
      : assert(url != null),
        this.domain = _normalizeDomain(_prepareUrl(url));

  static dynamic _prepareUrl(url) {
    if (url is String && url.isNotEmpty && !url.contains('//')) url = '//$url';
    return urlFromUriOrString(url);
  }

  static String _normalizeDomain(Uri url) {
    return url.host;
  }

  @override
  bool match(BaseRequest request) {
    final other = _normalizeDomain(request.url);
    if (domain == other) return true;
    if (allowSubdomains) return other.endsWith('.$domain');
    return false;
  }
}

class RequestUrlMatcher extends Matcher<BaseRequest> {
  final Uri url;
  final bool withQueryParams;

  /// [url] must be [String] or [Uri].
  RequestUrlMatcher(dynamic url, {this.withQueryParams = false})
      : assert(url != null),
        this.url = _normalizeUrl(urlFromUriOrString(url), withQueryParams);

  static Uri _normalizeUrl(Uri url, bool withQueryParams) {
    var val = withQueryParams ? url.sortQueryParams() : url.replace(queryParameters: {}, fragment: '');
    if (val.path == '/') val = val.replace(path: '');
    if (!val.hasQuery) val = val.replace(query: '');
    return val.removeFragment();
  }

  @override
  bool match(BaseRequest request) {
    return url == _normalizeUrl(request.url, withQueryParams);
  }
}

class RequestMethodMatcher extends Matcher<BaseRequest> {
  final Set<String> _methods;

  RequestMethodMatcher(List<HttpMethod> methods)
      : assert(methods.isNotEmpty),
        _methods = methods.map((i) => i.string).toSet();

  @override
  bool match(BaseRequest request) => _methods.isEmpty || _methods.contains(request.method);
}
