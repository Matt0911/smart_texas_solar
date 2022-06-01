import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_texas_solar/providers/smt/intervals_provider.dart';
import 'package:smart_texas_solar/providers/smt/token_provider.dart';
import 'package:smart_texas_solar/util/http_override.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Texas Solar',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(context, ref) {
    AsyncValue<Map<String, dynamic>> token = ref.watch(smtIntervalsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Texas Solar'),
      ),
      body: Center(
        child: Text(
          token.when(
            data: (t) => t.toString(),
            error: (e, s) => 'error',
            loading: () => 'loading',
          ),
        ),
      ),
    );
  }
}
