import 'package:http/http.dart' show BaseRequest;
import 'package:meta/meta.dart';

import '../middleware.dart';
import '../utils.dart' as utils;

/// [HeadersMiddleware] is used to add custom headers to [BaseRequest].
class HeadersMiddleware extends Middleware {
  final Map<String, String> headers;

  HeadersMiddleware(this.headers);

  @override
  FutureOr<BaseRequest> interceptRequest(BaseRequest request) {
    return super.interceptRequest(mergeHeaders(request, headers));
  }

  @protected
  BaseRequest mergeHeaders(BaseRequest request, Map<String, String>? headers) {
    return utils.mergeHeaders(request, headers);
  }
}
