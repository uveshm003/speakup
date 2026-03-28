import 'package:flutter/widgets.dart';

extension ContextExtensions on BuildContext {
  /// Theme short access when Material is not guaranteed at call site.
  MediaQueryData get mediaQuery => MediaQuery.of(this);
}
