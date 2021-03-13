import 'package:http/http.dart' show Request;
import 'package:http_middleware/http_middleware.dart';
import 'package:http_middleware/matchers/request_matcher.dart';
import 'package:http_middleware/src/base_client_mixin.dart';
import 'package:test/test.dart';

void main() {
  group('RequestDomainMatcher', () {
    final domain = 'domain.example.com';
    final base = 'http://$domain';
    test('RequestDomainMatcher()', () {
      expect(RequestDomainMatcher(base).domain, domain);
      expect(RequestDomainMatcher(domain).domain, domain);
      expect(RequestDomainMatcher('//$domain').domain, domain);
      expect(RequestDomainMatcher('https://$domain').domain, domain);
      expect(RequestDomainMatcher('/$domain').domain, '');
      expect(RequestDomainMatcher(Uri.parse(base)).domain, domain);
    });
    test('domain match', () {
      final m = RequestDomainMatcher(base);
      expect(m.match(req('')), false);
      expect(m.match(req('http://example.com')), false);
      expect(m.match(req('http://domain.example.org')), false);
      expect(m.match(req('http://$domain')), true);
      expect(m.match(req('http://$domain/')), true);
      expect(m.match(req('http://$domain/path')), true);
    });
    test('allowSubdomains match', () {
      final m = RequestDomainMatcher(base, allowSubdomains: true);
      expect(m.match(req(base)), true);
      expect(m.match(req('http://sub.domain.example.com')), true);
      expect(m.match(req('http://.domain.example.com')), true);
      expect(m.match(req('http://mydomain.example.com')), false);
      expect(m.match(req('http://example.com')), false);
      expect(m.match(req('http://sub.example.com')), false);
      expect(m.match(req('http://sub.domain.example.org')), false);
    });
  });
  group('RequestUrlMatcher', () {
    final base = 'http://example.com';
    test('match', () {
      final m = RequestUrlMatcher(base);
      expect(m.match(req(base)), true);
      expect(m.match(req('$base/')), true);
      expect(m.match(req('$base?')), true);
      expect(m.match(req('$base?a=a')), true);
      expect(m.match(req('$base#link')), true);
      expect(m.match(req('$base/path')), false);
      expect(m.match(req('http://another.com')), false);
      expect(m.match(req('https://example.com')), false);
    });
    test('withQueryParams match', () {
      final m = RequestUrlMatcher(base, withQueryParams: true);
      expect(m.match(req(base)), true);
      expect(m.match(req('$base/')), true);
      expect(m.match(req('$base?')), true);
      expect(m.match(req('$base/?')), true);
      expect(m.match(req('$base?a=a')), false);
      expect(RequestUrlMatcher('$base?a=a', withQueryParams: true).match(req('$base?a=a')), true);
      expect(RequestUrlMatcher('$base?a=a', withQueryParams: true).match(req('$base?')), false);
      expect(RequestUrlMatcher('$base?a=1&b=2', withQueryParams: true).match(req('$base?b=2&a=1&')), true);
      expect(RequestUrlMatcher('$base?a=1&b=2&a=a', withQueryParams: true).match(req('$base?b=2&a=a&a=1')), true);
      expect(RequestUrlMatcher('$base?a=1&b=2&a=a', withQueryParams: true).match(req('$base?b=2&a=a&a=2')), false);
    });
  });
  group('RequestMethodMatcher', () {
    final base = 'http://example.com';
    test('match', () {
      expect(RequestMethodMatcher([HttpMethod.get]).match(createRequest('GET', base)), true);
      expect(RequestMethodMatcher([HttpMethod.post, HttpMethod.get]).match(createRequest('GET', base)), true);
      expect(RequestMethodMatcher([HttpMethod.post]).match(createRequest('GET', base)), false);
      expect(RequestMethodMatcher([HttpMethod.post]).match(createRequest('POST', base)), true);
    });
  });
}

Request req(dynamic url) => createRequest('GET', url);
