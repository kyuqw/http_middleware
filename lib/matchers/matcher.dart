abstract class Matcher<T> {
  const Matcher();

  Matcher<T> and(List<Matcher<T>> others) {
    return MatchComposer<T>.all([this, ...others]);
  }

  Matcher<T> or(List<Matcher<T>> others) {
    return MatchComposer<T>.any([this, ...others]);
  }

  Matcher<T> not() => InvertMatcher(this);

  bool match(T object);
}

enum ComposerType { any, all }

class MatchComposer<T> extends Matcher<T> {
  final List<Matcher<T>> items;
  final ComposerType type;

  const MatchComposer(this.items, this.type);

  const MatchComposer.all(List<Matcher<T>> filters) : this(filters, ComposerType.all);

  const MatchComposer.any(List<Matcher<T>> filters) : this(filters, ComposerType.any);

  @override
  bool match(T object) {
    if (items.isEmpty) return false;
    if (type == ComposerType.any) return items.any((i) => i.match(object));
    if (type == ComposerType.all) return items.every((i) => i.match(object));
    return false;
  }
}

class InvertMatcher<T> extends Matcher<T> {
  final Matcher<T> matcher;

  const InvertMatcher(this.matcher);

  @override
  bool match(T object) => !matcher.match(object);
}

class ConstMatcher<T> extends Matcher<T> {
  final bool value;

  const ConstMatcher._private(this.value);

  const ConstMatcher.always() : this._private(true);

  const ConstMatcher.never() : this._private(false);

  @override
  bool match(T object) => value;
}

class FuncMatcher<T> extends Matcher<T> {
  final bool Function(T object) matcher;

  const FuncMatcher(this.matcher);

  @override
  bool match(T object) => matcher(object);
}
