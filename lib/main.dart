import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:speakup/config/app.dart';
import 'package:speakup/core/bootstrap/data_bootstrap.dart';
import 'package:speakup/core/utils/app_bloc_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error reporting — silent in release, logged in debug.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('Unhandled error: $error\n$stack');
    }
    return true;
  };

  await Hive.initFlutter();
  await bootstrapDataLayer(enableObjectBox: !kIsWeb);
  if (kDebugMode) {
    Bloc.observer = AppBlocObserver();
  }
  runApp(const SpeakUpApp());
}
