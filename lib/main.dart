import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_texas_solar/providers/selected_dates_provider.dart';
import 'package:smart_texas_solar/providers/smt/intervals_data_provider.dart';
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
    var intervalsData = ref.watch(smtIntervalsDataProvider);
    var selectedDates = ref.watch(selectedDatesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Texas Solar'),
      ),
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
                onPressed: () async {
                  DateTimeRange? range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2010),
                      lastDate:
                          DateTime.now().subtract(const Duration(days: 2)),
                      initialDateRange: DateTimeRange(
                          start: selectedDates.startDate,
                          end: selectedDates.endDate));
                  if (range != null) {
                    selectedDates.updateDates(
                        start: range.start, end: range.end);
                  }
                },
                child: const Text('Select Dates')),
          ),
          Expanded(
            child: Center(
              child: intervalsData.when(
                data: (t) => ListView.builder(
                  itemBuilder: (context, i) =>
                      Text(t.intervalData[i].toString()),
                  itemCount: t.intervalData.length,
                ),
                error: (e, s) => const Text('error'),
                loading: () => const Text('loading'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
