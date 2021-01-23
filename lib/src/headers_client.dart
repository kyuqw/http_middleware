import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'base_client_mixin.dart';
import 'utils.dart' as utils;


/// [HeadersClient] is used to add custom headers to [BaseRequest].
class HeadersClient extends http.BaseClient with BaseClientMixin {
  final Map<String, String>? headers;
  final http.Client _client;

  HeadersClient({this.headers, http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(mergeHeaders(request, headers));
  }

  @protected
  http.BaseRequest mergeHeaders(http.BaseRequest request, Map<String, String>? headers) {
    return utils.mergeHeaders(request, headers);
  }

  @override
  void close() {
    _client.close();
  }
}
