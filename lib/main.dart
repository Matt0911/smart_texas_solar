import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_texas_solar/providers/smt/intervals_service_provider.dart';
import 'package:smart_texas_solar/providers/smt/token_service_provider.dart';
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
    AsyncValue<IntervalsService> intervalsService =
        ref.watch(smtIntervalsServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Texas Solar'),
      ),
      body: Center(
        child: intervalsService.when(
          data: (t) => FutureBuilder(
              future: t.fetchInterval(
                  startDate: DateTime.now().subtract(Duration(days: 1))),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data.toString());
                } else {
                  return const Text('no data yet');
                }
              }),
          error: (e, s) => const Text('error'),
          loading: () => const Text('loading'),
        ),
      ),
    );
  }
}
