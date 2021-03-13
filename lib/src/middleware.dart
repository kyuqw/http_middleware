import 'dart:async';

import 'package:http/http.dart'
    show BaseRequest, Request, StreamedRequest, MultipartRequest, BaseResponse, Response, StreamedResponse;

export 'dart:async' show FutureOr;

export 'package:http/http.dart'
    show BaseRequest, Request, StreamedRequest, MultipartRequest, BaseResponse, Response, StreamedResponse;

typedef MiddlewareNextHandler = FutureOr<BaseResponse> Function(BaseRequest);

/// A base middleware class used by [MiddlewareClient] to intercept [BaseRequest] and [BaseResponse].
abstract class Middleware {
  /// main method to interact with [Middleware] class.
  FutureOr<BaseResponse> send(BaseRequest request, MiddlewareNextHandler next) async {
    final req = await interceptRequest(request);
    return interceptResponse(await interceptNextCall(req, next));
  }

  FutureOr<BaseRequest> interceptRequest(BaseRequest request) {
    return request;
  }

  FutureOr<BaseResponse> interceptNextCall(BaseRequest request, MiddlewareNextHandler next) {
    return next(request);
  }

  FutureOr<BaseResponse> interceptResponse(BaseResponse response) {
    return response;
  }
}

/// Generic class to intercept [Req] type requests and [Res] type responses.
abstract class GenericMiddleware<Req extends BaseRequest, Res extends BaseResponse> extends Middleware {
  @override
  FutureOr<BaseRequest> interceptRequest(BaseRequest request) {
    if (request is Req) return interceptRequestHandler(request);
    return super.interceptRequest(request);
  }

  @override
  FutureOr<BaseResponse> interceptResponse(BaseResponse response) {
    if (response is Res) return interceptResponseHandler(response);
    return super.interceptResponse(response);
  }

  FutureOr<BaseRequest> interceptRequestHandler(Req request) async {
    return super.interceptRequest(request);
  }

  FutureOr<BaseResponse> interceptResponseHandler(Res response) {
    return super.interceptResponse(response);
  }
}

mixin SeparatedRequestMiddlewareMixin on Middleware {
  @override
  FutureOr<BaseRequest> interceptRequest(BaseRequest request) {
    if (request is Request) return interceptNonStreamedRequest(request);
    if (request is StreamedRequest) return interceptStreamedRequest(request);
    if (request is MultipartRequest) return interceptMultipartRequest(request);
    return super.interceptRequest(request);
  }

  FutureOr<BaseRequest> interceptNonStreamedRequest(Request request) {
    return super.interceptRequest(request);
  }

  FutureOr<BaseRequest> interceptStreamedRequest(StreamedRequest request) {
    return super.interceptRequest(request);
  }

  FutureOr<BaseRequest> interceptMultipartRequest(MultipartRequest request) {
    return super.interceptRequest(request);
  }
}

mixin SeparatedResponseMiddlewareMixin on Middleware {
  @override
  FutureOr<BaseResponse> interceptResponse(BaseResponse response) {
    if (response is Response) return interceptNonStreamedResponse(response);
    if (response is StreamedResponse) return interceptStreamResponse(response);
    return super.interceptResponse(response);
  }

  FutureOr<BaseResponse> interceptNonStreamedResponse(Response response) {
    return super.interceptResponse(response);
  }

  FutureOr<BaseResponse> interceptStreamResponse(StreamedResponse response) {
    return super.interceptResponse(response);
  }
}

abstract class SeparatedRequestMiddleware extends Middleware with SeparatedRequestMiddlewareMixin {}

abstract class SeparatedResponseMiddleware extends Middleware with SeparatedResponseMiddlewareMixin {}
