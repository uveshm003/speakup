import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:speakup/config/app.dart';
import 'package:speakup/core/bootstrap/data_bootstrap.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final Directory temp =
        Directory.systemTemp.createTempSync('speakup_widget_test_hive');
    Hive.init(temp.path);
    await bootstrapDataLayer(enableObjectBox: false);
  });

  testWidgets('SpeakUp app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SpeakUpApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
