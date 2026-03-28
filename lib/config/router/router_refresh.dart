import 'package:flutter/foundation.dart';

/// Increment to force GoRouter to re-run [redirect] (e.g. after onboarding).
final ValueNotifier<int> appRouterRefreshNotifier = ValueNotifier<int>(0);

void notifyAppRouterRefresh() {
  appRouterRefreshNotifier.value++;
}
