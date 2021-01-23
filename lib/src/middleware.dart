import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http_middleware/http_middleware.dart';

export 'dart:async' show FutureOr;

// TODO: export Request and Response

typedef MiddlewareNextHandler = FutureOr<http.BaseResponse> Function(http.BaseRequest);

/// A base middleware class used by [MiddlewareClient] to intercept [http.BaseRequest] and [http.BaseResponse].
abstract class Middleware {
  FutureOr<http.BaseResponse> send(http.BaseRequest request, MiddlewareNextHandler next) async {
    final req = await interceptRequest(request);
    return interceptResponse(await interceptRequestCall(req, next));
  }

  FutureOr<http.BaseRequest> interceptRequest(http.BaseRequest request) {
    return request;
  }

  FutureOr<http.BaseResponse> interceptRequestCall(http.BaseRequest request, MiddlewareNextHandler next) {
    return next(request);
  }

  FutureOr<http.BaseResponse> interceptResponse(http.BaseResponse response) {
    return response;
  }
}

mixin SeparatedResponseMiddlewareMixin on Middleware {
  @override
  FutureOr<http.BaseResponse> interceptResponse(http.BaseResponse response) {
    if (response is http.Response) return interceptNonStreamedResponse(response);
    if (response is http.StreamedResponse) return super.interceptResponse(response);
    return super.interceptResponse(response);
  }

  FutureOr<http.BaseResponse> interceptNonStreamedResponse(http.Response response) {
    return super.interceptResponse(response);
  }

  FutureOr<http.BaseResponse> interceptStreamResponse(http.StreamedResponse response) {
    return super.interceptResponse(response);
  }
}

abstract class SeparatedResponseMiddleware extends Middleware with SeparatedResponseMiddlewareMixin {}
