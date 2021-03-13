import 'dart:convert' as convert;

import 'package:http/http.dart' show BaseResponse, Response;

import 'http_extensions.dart';

typedef JsonModelFactory<T> = T Function(dynamic json);
typedef JsonDecoderReviver = Object? Function(Object? key, Object? value);

abstract class BaseResponseParser<T> {
  const BaseResponseParser();

  // TODO: pass args?
  T parse(BaseResponse response) => throw UnimplementedError('Unsupported response type: ${response.runtimeType}.');
}

mixin NonStreamedResponseParserMixin<T> on BaseResponseParser<T> {
  @override
  T parse(BaseResponse response) {
    if (response is Response) return parseNonStreamedResponse(response);
    return super.parse(response);
  }

  T parseNonStreamedResponse(Response response);
}

class JsonResponseParser extends BaseResponseParser with NonStreamedResponseParserMixin {
  final JsonDecoderReviver? reviver;

  const JsonResponseParser({this.reviver});

  @override
  dynamic parseNonStreamedResponse(Response response) {
    return convert.jsonDecode(response.body, reviver: reviver);
  }
}

class JsonModelResponseParser<T> extends BaseResponseParser<T?> with NonStreamedResponseParserMixin {
  final JsonModelFactory<T> factoryMethod;
  final T? defaultValue;
  final JsonDecoderReviver? reviver;

  const JsonModelResponseParser(this.factoryMethod, {this.defaultValue, this.reviver});

  T? parseNonStreamedResponse(Response response) {
    if (!response.ok) return defaultValue;
    final jsonResponse = JsonResponseParser(reviver: reviver).parse(response);
    return factoryMethod(jsonResponse);
  }
}

class ListJsonModelResponseParser<T> extends BaseResponseParser<List<T>?> with NonStreamedResponseParserMixin {
  final JsonModelFactory<T> factoryMethod;
  final List<T>? defaultValue;
  final JsonDecoderReviver? reviver;

  const ListJsonModelResponseParser(this.factoryMethod, {this.defaultValue, this.reviver});

  List<T>? parseNonStreamedResponse(Response response) {
    if (!response.ok) return defaultValue;
    JsonModelFactory<List<T>> listFactory = (dynamic jsonArrayResponse) {
      return List<T>.from(jsonArrayResponse.map(factoryMethod));
    };
    return JsonModelResponseParser<List<T>>(listFactory, reviver: reviver).parse(response);
  }
}
