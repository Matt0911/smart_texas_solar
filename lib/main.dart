import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'models/combined_interval.dart';
import 'models/enphase_intervals.dart';
import 'models/interval.dart';
import 'models/smt_intervals.dart';
import 'providers/combined_intervals_data_provider.dart';
import 'providers/hive/enphase_refresh_token_provider.dart';
import 'providers/hive/secrets_provider.dart';
import 'providers/selected_dates_provider.dart';
import 'util/http_override.dart';
import 'widgets/line_bar_combo_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await Hive.initFlutter();
  Hive.registerAdapter(SecretsAdapter());
  Hive.registerAdapter(EnphaseTokenResponseAdapter());
  Hive.registerAdapter(IntervalAdapter());
  Hive.registerAdapter(SMTIntervalsAdapter());
  Hive.registerAdapter(EnphaseIntervalsAdapter());
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
    var selectedDates = ref.watch(selectedDatesProvider);
    var intervals = ref.watch(combinedIntervalsDataProvider(context));
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
            child: Row(
              children: [
                Expanded(
                  child: intervals.when(
                    data: (t) => ListView.builder(
                      itemBuilder: (context, i) =>
                          Text(t.intervalsData[i].toString()),
                      itemCount: t.intervalsData.length,
                    ),
                    error: (e, s) => Text('$e with stack $s '),
                    loading: () => const Text('loading'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: intervals.when(
              data: (t) => LineBarComboChart(
                [
                  charts.Series<CombinedInterval, DateTime>(
                    id: 'Consumption',
                    colorFn: (_, __) =>
                        charts.MaterialPalette.blue.shadeDefault,
                    domainFn: (interval, _) => interval.endTime,
                    measureFn: (interval, _) => -interval.kwhTotalConsumption,
                    data: t.intervalsData,
                  )..setAttribute(charts.rendererIdKey, 'customBar'),
                  charts.Series<CombinedInterval, DateTime>(
                    id: 'Production',
                    colorFn: (_, __) =>
                        charts.MaterialPalette.green.shadeDefault,
                    domainFn: (interval, _) => interval.endTime,
                    measureFn: (interval, _) => interval.kwhSolarProduction,
                    data: t.intervalsData,
                  )..setAttribute(charts.rendererIdKey, 'customBar'),
                  charts.Series<CombinedInterval, DateTime>(
                    id: 'Net',
                    areaColorFn: (interval, __) =>
                        interval.kwhTotalConsumption -
                                    interval.kwhSolarProduction >
                                0
                            ? charts.MaterialPalette.red.shadeDefault
                            : charts.MaterialPalette.green.shadeDefault,
                    colorFn: (interval, __) => interval.kwhTotalConsumption -
                                interval.kwhSolarProduction >
                            0
                        ? charts.MaterialPalette.red.shadeDefault
                        : charts.MaterialPalette.green.shadeDefault,
                    domainFn: (interval, _) => interval.endTime,
                    measureFn: (interval, _) =>
                        interval.kwhSolarProduction -
                        interval.kwhTotalConsumption,
                    data: t.intervalsData,
                  ),
                ],
              ),
              error: (e, s) => Text('$e with stack $s '),
              loading: () => const Text('loading'),
            ),
          )
        ],
      ),
    );
  }
}
