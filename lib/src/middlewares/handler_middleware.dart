import 'package:http/http.dart'
    show BaseRequest, Request, StreamedRequest, MultipartRequest, BaseResponse, Response, StreamedResponse;

import '../middleware.dart';

typedef RequestHandler<T extends BaseRequest> = FutureOr<BaseRequest>? Function(T request);
typedef ResponseHandler<T extends BaseResponse> = FutureOr<BaseResponse>? Function(T response);

/// [HandlersMiddleware] is used to add [Middleware] logic without creating new class.
class HandlersMiddleware<Req extends BaseRequest, Res extends BaseResponse> extends GenericMiddleware<Req, Res> {
  final RequestHandler<Req>? requestHandler;
  final ResponseHandler<Res>? responseHandler;

  HandlersMiddleware({this.requestHandler, this.responseHandler})
      : assert(requestHandler != null || responseHandler != null);

  @override
  FutureOr<BaseRequest> interceptRequestHandler(Req request) async {
    return requestHandler?.call(request) ?? super.interceptRequestHandler(request);
  }

  @override
  FutureOr<BaseResponse> interceptResponseHandler(Res response) {
    return responseHandler?.call(response) ?? super.interceptResponseHandler(response);
  }
}

class SeparatedHandlersMiddleware extends Middleware
    with SeparatedRequestMiddlewareMixin, SeparatedResponseMiddlewareMixin {
  final RequestHandler<BaseRequest>? requestHandler;
  final RequestHandler<Request>? nonStreamedRequestHandler;
  final RequestHandler<StreamedRequest>? streamedRequestHandler;
  final RequestHandler<MultipartRequest>? multipartRequestHandler;
  final ResponseHandler<BaseResponse>? baseResponseHandler;
  final ResponseHandler<Response>? nonStreamedResponseHandler;
  final ResponseHandler<StreamedResponse>? streamedResponseHandler;

  SeparatedHandlersMiddleware({
    this.requestHandler,
    this.nonStreamedRequestHandler,
    this.streamedRequestHandler,
    this.multipartRequestHandler,
    this.baseResponseHandler,
    this.nonStreamedResponseHandler,
    this.streamedResponseHandler,
  }) : assert(requestHandler != null ||
            nonStreamedRequestHandler != null ||
            streamedRequestHandler != null ||
            multipartRequestHandler != null ||
            baseResponseHandler != null ||
            nonStreamedResponseHandler != null ||
            streamedResponseHandler != null);

  @override
  FutureOr<BaseRequest> interceptRequest(BaseRequest request) {
    return requestHandler?.call(request) ?? super.interceptRequest(request);
  }

  @override
  FutureOr<BaseRequest> interceptNonStreamedRequest(Request request) {
    return nonStreamedRequestHandler?.call(request) ?? super.interceptNonStreamedRequest(request);
  }

  @override
  FutureOr<BaseRequest> interceptStreamedRequest(StreamedRequest request) {
    return streamedRequestHandler?.call(request) ?? super.interceptStreamedRequest(request);
  }

  @override
  FutureOr<BaseRequest> interceptMultipartRequest(MultipartRequest request) {
    return multipartRequestHandler?.call(request) ?? super.interceptMultipartRequest(request);
  }

  @override
  FutureOr<BaseResponse> interceptResponse(BaseResponse response) {
    return baseResponseHandler?.call(response) ?? super.interceptResponse(response);
  }

  @override
  FutureOr<BaseResponse> interceptNonStreamedResponse(Response response) {
    return nonStreamedResponseHandler?.call(response) ?? super.interceptNonStreamedResponse(response);
  }

  @override
  FutureOr<BaseResponse> interceptStreamResponse(StreamedResponse response) {
    return streamedResponseHandler?.call(response) ?? super.interceptStreamResponse(response);
  }
}
