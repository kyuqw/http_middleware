import 'package:http/http.dart' show BaseRequest, Request, BaseResponse, Response;
import 'package:meta/meta.dart';

import '../middleware.dart';


/// [LogMiddleware] is used to log [BaseRequest] & [Response] info during network requests.
class LogMiddleware extends SeparatedResponseMiddleware {
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
  FutureOr<BaseResponse> interceptNonStreamedResponse(Response response) {
    if (logResponse) printResponse(response);
    return super.interceptNonStreamedResponse(response);
  }

  @protected
  void printRequest(BaseRequest request) {
    final sb = StringBuffer();
    sb.writeln('${request.method} ${request.url}');
    if (logRequestHeaders && (request.headers?.isNotEmpty ?? false)) sb.writeln('headers: ${request.headers}');
    if (logRequestBody && request is Request && request.contentLength > 0) sb.writeln('body: ${request.body}');
    logMethod(sb.toString());
  }

  @protected
  void printResponse(Response response) {
    final sb = StringBuffer();
    final request = response.request;
    sb.writeln('${response.statusCode} ${request.method} ${request.url}');
    if (logResponseHeaders && (response.headers?.isNotEmpty ?? false)) sb.writeln('headers: ${response.headers}');
    if (logResponseBody && response.contentLength > 0) sb.writeln('body: ${response.body}');
    logMethod(sb.toString());
  }
}
