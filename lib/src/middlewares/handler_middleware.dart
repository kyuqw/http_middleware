import 'package:http/http.dart' show BaseRequest, BaseResponse, Response, StreamedResponse;

import '../middleware.dart';

/// [HandlersMiddleware] is used to add [Middleware] logic without creating new class.
class HandlersMiddleware extends Middleware with SeparatedResponseMiddlewareMixin {
  final FutureOr<BaseRequest> Function(BaseRequest request)? requestHandler;
  final FutureOr<BaseResponse> Function(BaseResponse response)? baseResponseHandler;
  final FutureOr<BaseResponse> Function(BaseResponse response)? nonStreamedResponseHandler;
  final FutureOr<BaseResponse> Function(BaseResponse response)? streamedResponseHandler;

  HandlersMiddleware({
    this.requestHandler,
    this.baseResponseHandler,
    this.nonStreamedResponseHandler,
    this.streamedResponseHandler,
  }) : assert(requestHandler != null ||
            baseResponseHandler != null ||
            nonStreamedResponseHandler != null ||
            streamedResponseHandler != null);

  @override
  FutureOr<BaseRequest> interceptRequest(BaseRequest request) {
    if (requestHandler != null) return requestHandler!(request);
    return super.interceptRequest(request);
  }

  @override
  FutureOr<BaseResponse> interceptResponse(BaseResponse response) {
    if (baseResponseHandler != null) return baseResponseHandler!(response);
    return super.interceptResponse(response);
  }

  @override
  FutureOr<BaseResponse> interceptNonStreamedResponse(Response response) {
    if (nonStreamedResponseHandler != null) return nonStreamedResponseHandler!(response);
    return super.interceptNonStreamedResponse(response);
  }

  @override
  FutureOr<BaseResponse> interceptStreamResponse(StreamedResponse response) {
    if (streamedResponseHandler != null) return streamedResponseHandler!(response);
    return super.interceptStreamResponse(response);
  }
}
