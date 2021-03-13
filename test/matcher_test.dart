import 'package:http_middleware/matchers/matcher.dart';
import 'package:test/test.dart';

void main() {
  const t = ConstMatcher.always();
  const f = ConstMatcher.never();
  group('MatchComposer', () {
    test('all()', () {
      expect(MatchComposer.all([]).match(null), false);
      expect(MatchComposer.all([f]).match(null), false);
      expect(MatchComposer.all([t]).match(null), true);
      expect(MatchComposer.all([f, f]).match(null), false);
      expect(MatchComposer.all([t, f]).match(null), false);
      expect(MatchComposer.all([t, t]).match(null), true);
    });
    test('any()', () {
      expect(MatchComposer.any([]).match(null), false);
      expect(MatchComposer.any([f]).match(null), false);
      expect(MatchComposer.any([t]).match(null), true);
      expect(MatchComposer.any([f, f]).match(null), false);
      expect(MatchComposer.any([t, f]).match(null), true);
      expect(MatchComposer.any([t, t]).match(null), true);
    });
  });
  group('Matcher', () {
    test('and', () {
      expect(t.and([]).match(null), true);
      expect(t.and([t]).match(null), true);
      expect(t.and([f]).match(null), false);
      expect(f.and([]).match(null), false);
      expect(f.and([f]).match(null), false);
      expect(f.and([t]).match(null), false);
    });
    test('or', () {
      expect(t.or([]).match(null), true);
      expect(t.or([t]).match(null), true);
      expect(t.or([f]).match(null), true);
      expect(f.or([]).match(null), false);
      expect(f.or([f]).match(null), false);
      expect(f.or([t]).match(null), true);
    });
    test('not', () {
      expect(f.not().match(null), true);
      expect(t.not().match(null), false);
    });
  });
}
