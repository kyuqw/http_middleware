import 'package:meta/meta.dart';

import '../middleware.dart';

/// [LogMiddleware] is used to log [BaseRequest] & [Response] info during network requests.
class LogMiddleware extends Middleware {
  final bool logRequest;
  final bool logRequestHeaders;
  final bool logRequestBody;
  final bool logResponse;
  final bool logResponseHeaders;
  final bool logResponseBody;
  final Function(Object?) logMethod;

  LogMiddleware({
    this.logRequest = true,
    this.logRequestHeaders = true,
    this.logRequestBody = false,
    this.logResponse = true,
    this.logResponseHeaders = false,
    this.logResponseBody = true,
    this.logMethod = print,
  });

  @override
  FutureOr<BaseRequest> interceptRequest(BaseRequest request) {
    if (logRequest) printRequest(request);
    return request;
  }

  @override
  FutureOr<BaseResponse> interceptResponse(BaseResponse response) {
    if (logResponse) printResponse(response);
    return super.interceptResponse(response);
  }

  @protected
  void printRequest(BaseRequest request) {
    final sb = StringBuffer();
    sb.writeln('${request.method} ${request.url}');
    if (logRequestHeaders && request.headers.isNotEmpty) sb.writeln('headers: ${request.headers}');
    if (logRequestBody && request is Request && request.contentLength > 0) sb.writeln('body: ${request.body}');
    logMethod(sb.toString());
  }

  @protected
  void printResponse(BaseResponse response) {
    final sb = StringBuffer();
    final request = response.request;
    sb.writeln('${response.statusCode} ${request?.method} ${request?.url}');
    if (logResponseHeaders && response.headers.isNotEmpty) sb.writeln('headers: ${response.headers}');
    if (logResponseBody && response is Response && response.contentLength != null && response.contentLength! > 0)
      sb.writeln('body: ${response.body}');
    logMethod(sb.toString());
  }
}
