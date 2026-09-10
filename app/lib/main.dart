import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/naming/stroke_dictionary.dart';
import 'services/app_state.dart';
import 'services/storage/profile_store.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 康熙笔画字典:有文件就加载,没有就用内置兜底
  try {
    final json = await rootBundle.loadString('assets/data/kangxi_strokes.json');
    StrokeDictionary.loadFromJson(json);
  } catch (_) {}

  final state = AppState(ProfileStore());
  await state.init();

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const MingliApp(),
    ),
  );
}

class MingliApp extends StatelessWidget {
  const MingliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '命理师 AI',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('zh'),
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeScreen(),
    );
  }
}
