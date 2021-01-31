import 'package:http_middleware/src/utils.dart';
import 'package:test/test.dart';

void main() {
  const base = 'http://example.com';
  group('mergeUrlQueryParameters', () {
    final urls = [
      '$base/a/b',
      '$base/a/b?c=1',
      '$base:8080/a/b?c=1&b=2&a=',
      '$base/a/b?c=1&b=2&a&d={"name":"название"}',
      Uri.parse('$base/a/b?c=1&b=2&a&d={"name":"название"}'),
    ];
    test('null and empty query parameters', () {
      for (final url in urls) {
        expect(mergeUrlQueryParameters(url, null), urlFromUriOrString(url));
        expect(mergeUrlQueryParameters(url, {}), urlFromUriOrString(url));
      }
    });
    test('with query parameters', () {
      final toUri = (uri) => urlFromUriOrString(uri).sortQueryParams();
      for (final url in urls) {
        final strUrl = url.toString();
        final separator = strUrl.contains('?') ? '&' : '?';
        Map<String, dynamic> p = {
          'c': '2',
          'e': ['1', '2'],
        };
        var query = 'c=2&e=1&e=2';
        expect(toUri(mergeUrlQueryParameters(url, p)), toUri('$strUrl$separator$query'));

        p = {
          'e': null,
          'd': ['', null, '3'],
          'D': 'DDdd=',
        };
        query = 'e&d&d&d=3&D=DDdd=';
        expect(toUri(mergeUrlQueryParameters(url, p)), toUri('$strUrl$separator$query'));
      }
    });
    test('query parameters types', () {
      expect(mergeUrlQueryParameters(base, <String, String?>{'a': null}).toString(), '$base?a');
      expect(mergeUrlQueryParameters(base, <String, String>{'a': ''}).toString(), '$base?a');
      expect(mergeUrlQueryParameters(base, <String, String>{'a': '1'}).toString(), '$base?a=1');
      expect(mergeUrlQueryParameters(base, <String, List<String>?>{'a': null}).toString(), '$base?a');
      expect(mergeUrlQueryParameters(base, <String, List<String?>>{'a': [null]}).toString(), '$base?a');
      expect(mergeUrlQueryParameters(base, <String, List<String?>>{'a': []}).toString(), '$base?a');
      expect(mergeUrlQueryParameters(base, <String, List<String?>>{'a': ['']}).toString(), '$base?a');
      expect(mergeUrlQueryParameters(base, <String, List<String>>{'a': ['1']}).toString(), '$base?a=1');
      expect(() => mergeUrlQueryParameters(base, {'a': 1}).toString(), throwsA(isA<TypeError>()));
      expect(() => mergeUrlQueryParameters(base, {'a': [1]}).toString(), throwsA(isA<TypeError>()));
    });
  });

  group('UriExtensions.', () {
    test('sortQueryParams', () {
      final toUri = (uri) => urlFromUriOrString(uri).sortQueryParams();
      final url = '$base/a/b';
      expect(toUri(url), urlFromUriOrString(url));
      expect(toUri('$url?a'), urlFromUriOrString('$url?a'));
      expect(toUri('$url?a=1'), urlFromUriOrString('$url?a=1'));
      expect(toUri('$url?c=2&a=1&c&e&c=1'), urlFromUriOrString('$url?a=1&c&c=1&c=2&e'));
      expect(toUri('$url?c=2&b=2&a=1&c&c=1&b={"value"}'), urlFromUriOrString('$url?a=1&b=2&b={"value"}&c&c=1&c=2'));
    });
  });
}
