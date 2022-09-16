import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/widgets/number_card.dart';

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

final _formatter = DateFormat('MMM dd, yyyy');
String getSelectedDateText(DateTime start, DateTime end) {
  var startStr = _formatter.format(start);
  var endStr = _formatter.format(end);
  if (startStr == endStr) return startStr;
  return '$startStr - $endStr';
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
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  getSelectedDateText(
                      selectedDates.startDate, selectedDates.endDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
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
                  child: const Text('Select Dates'),
                )
              ],
            ),
          ),
          intervals.when(
            data: (combinedIntervals) {
              num totalConsumption = combinedIntervals.intervalsData
                  .fold<num>(0, (sum, i) => sum + i.kwhTotalConsumption);
              num totalGrid = combinedIntervals.intervalsData
                  .fold<num>(0, (sum, i) => sum + i.kwhGridConsumption);
              num totalProduction = combinedIntervals.intervalsData
                  .fold<num>(0, (sum, i) => sum + i.kwhSolarProduction);
              num totalSurplus = combinedIntervals.intervalsData
                  .fold<num>(0, (sum, i) => sum + i.kwhSurplusGeneration);
              num totalNet = totalProduction - totalConsumption;
              return Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      // crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              NumberCard(
                                title: 'Production',
                                value: totalProduction,
                                valueColor: Colors.green.shade500,
                                valueUnits: 'kWh',
                              ),
                              NumberCard(
                                title: 'Surplus',
                                value: totalSurplus,
                                valueColor: Colors.green.shade500,
                                valueUnits: 'kWh',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              NumberCard(
                                title: 'Consumption',
                                value: totalConsumption,
                                valueColor: Colors.red.shade900,
                                valueUnits: 'kWh',
                              ),
                              NumberCard(
                                title: 'Grid Cons.',
                                value: totalGrid,
                                valueColor: Colors.red.shade900,
                                valueUnits: 'kWh',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: NumberCard(
                            title: 'Net',
                            value: totalNet,
                            valueColor: totalNet >= 0
                                ? Colors.green.shade500
                                : Colors.red.shade900,
                            valueUnits: 'kWh',
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      flex: 3,
                      child: LineBarComboChart(
                        [
                          charts.Series<CombinedInterval, DateTime>(
                            id: 'Consumption',
                            colorFn: (_, __) =>
                                const charts.Color(r: 214, g: 144, b: 2),
                            domainFn: (interval, _) => interval.endTime,
                            measureFn: (interval, _) =>
                                -interval.kwhTotalConsumption,
                            data: combinedIntervals.intervalsData,
                          )..setAttribute(charts.rendererIdKey, 'customBar'),
                          charts.Series<CombinedInterval, DateTime>(
                            id: 'Production',
                            colorFn: (_, __) =>
                                charts.MaterialPalette.green.shadeDefault,
                            domainFn: (interval, _) => interval.endTime,
                            measureFn: (interval, _) =>
                                interval.kwhSolarProduction,
                            data: combinedIntervals.intervalsData,
                          )..setAttribute(charts.rendererIdKey, 'customBar'),
                          charts.Series<CombinedInterval, DateTime>(
                            id: 'Net',
                            areaColorFn: (interval, __) =>
                                interval.kwhTotalConsumption -
                                            interval.kwhSolarProduction >
                                        0
                                    ? charts.MaterialPalette.red.shadeDefault
                                    : charts.MaterialPalette.green.shadeDefault,
                            colorFn: (interval, __) =>
                                interval.kwhTotalConsumption -
                                            interval.kwhSolarProduction >
                                        0
                                    ? charts.MaterialPalette.red.shadeDefault
                                    : const charts.Color(r: 24, g: 237, b: 7),
                            domainFn: (interval, _) => interval.endTime,
                            measureFn: (interval, _) =>
                                interval.kwhSolarProduction -
                                interval.kwhTotalConsumption,
                            data: combinedIntervals.intervalsData,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
            error: (e, s) => Text('$e with stack $s '),
            loading: () => const Text('loading'),
          ),
        ]));
  }
}
