import 'dart:convert' as convert;

import 'package:http/http.dart' show BaseResponse, Response;

import 'http_extensions.dart';

typedef JsonModelFactory<T> = T Function(dynamic json);
typedef JsonDecoderReviver = Object? Function(Object? key, Object? value);

abstract class BaseResponseParser<T> {
  // TODO: pass args?
  T parse(BaseResponse response) => throw UnimplementedError();
}

mixin NonStreamedResponseParserMixin<T> on BaseResponseParser<T> {
  @override
  T parse(BaseResponse response) {
    if (response is Response) return parseNonStreamedResponse(response);
    throw UnsupportedError('Unsupported response type: ${response.runtimeType}.');
  }

  T parseNonStreamedResponse(Response response);
}

class JsonResponseParser extends BaseResponseParser with NonStreamedResponseParserMixin {
  @override
  dynamic parse(BaseResponse response, {JsonDecoderReviver? reviver}) {
    if (response is Response) return parseNonStreamedResponse(response, reviver: reviver);
    return super.parse(response);
  }

  @override
  dynamic parseNonStreamedResponse(Response response, {JsonDecoderReviver? reviver}) {
    return convert.jsonDecode(response.body, reviver: reviver);
  }
}

/// TODO: move parse args to constructor and extents from [BaseResponseParser] ???
class JsonModelResponseParser<T> {
  T? parse(BaseResponse response, JsonModelFactory<T> factoryMethod, {T? defaultValue, JsonDecoderReviver? reviver}) {
    if (response is Response)
      return parseNonStreamedResponse(response, factoryMethod, defaultValue: defaultValue, reviver: reviver);
    throw UnsupportedError('Unsupported response type: ${response.runtimeType}.');
  }

  T? parseNonStreamedResponse(Response response, JsonModelFactory<T> factoryMethod,
      {T? defaultValue, JsonDecoderReviver? reviver}) {
    if (!response.ok) return defaultValue;
    final jsonResponse = JsonResponseParser().parse(response, reviver: reviver);
    return factoryMethod(jsonResponse);
  }
}

class ListJsonModelResponseParser<T> {
  List<T>? parse(BaseResponse response, JsonModelFactory<T> factoryMethod,
      {List<T>? defaultValue, JsonDecoderReviver? reviver}) {
    if (response is Response)
      return parseNonStreamedResponse(response, factoryMethod, defaultValue: defaultValue, reviver: reviver);
    throw UnsupportedError('Unsupported response type: ${response.runtimeType}.');
  }

  List<T>? parseNonStreamedResponse(Response response, JsonModelFactory<T> factoryMethod,
      {List<T>? defaultValue, JsonDecoderReviver? reviver}) {
    if (!response.ok) return defaultValue;
    JsonModelFactory<List<T>> listFactory = (dynamic jsonArrayResponse) {
      return List<T>.from(jsonArrayResponse.map(factoryMethod));
    };
    return JsonModelResponseParser<List<T>>().parse(response, listFactory, reviver: reviver);
  }
}
