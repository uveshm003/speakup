/// Web stub: ObjectBox FFI bindings are not compiled for `dart2js`.
/// Persist structured data on web with a different strategy when you implement features.
class ObjectBoxStore {
  ObjectBoxStore._();

  static Future<void> init() async {}

  static Never get store =>
      throw UnsupportedError('ObjectBox is not available on web.');

  static bool get isInitialized => false;

  static Future<void> close() async {}
}
