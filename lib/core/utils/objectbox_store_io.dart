import 'package:path_provider/path_provider.dart';
import 'package:speakup/core/constants/app_constants.dart';
import 'package:speakup/objectbox.g.dart';

/// Singleton access to the ObjectBox [Store] (iOS, Android, desktop).
///
/// Call [init] once during app startup after [WidgetsFlutterBinding.ensureInitialized].
class ObjectBoxStore {
  ObjectBoxStore._();

  static Store? _store;

  static Store get store {
    final s = _store;
    if (s == null) {
      throw StateError('ObjectBoxStore not initialized. Call ObjectBoxStore.init() in main.');
    }
    return s;
  }

  static bool get isInitialized => _store != null;

  static Future<void> init() async {
    if (_store != null) {
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${AppConstants.objectBoxSubdirectory}';
    _store = await openStore(directory: path);
  }

  static Future<void> close() async {
    final s = _store;
    if (s == null) {
      return;
    }
    s.close();
    _store = null;
  }
}
