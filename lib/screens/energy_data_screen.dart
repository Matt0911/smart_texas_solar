import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/providers/past_intervals_data_fetcher_provider.dart';
import 'package:smart_texas_solar/widgets/sts_drawer.dart';

import '../providers/combined_intervals_data_provider.dart';
import '../providers/selected_dates_provider.dart';
import '../widgets/intervals_chart.dart';
import '../widgets/number_card.dart';

final _formatter = DateFormat('MMM dd, yyyy');
String getSelectedDateText(DateTime start, DateTime end) {
  var startStr = _formatter.format(start);
  var endStr = _formatter.format(end);
  if (startStr == endStr) return startStr;
  return '$startStr - $endStr';
}

class EnergyDataScreen extends ConsumerWidget {
  static const String routeName = '/energy-data-screen';

  const EnergyDataScreen({Key? key}) : super(key: key);

  @override
  Widget build(context, ref) {
    var selectedDates = ref.watch(selectedDatesProvider);
    var intervals = ref.watch(combinedIntervalsDataProvider);
    ref.listen<bool>(pastIntervalsDataFetcherProvider, ((previous, next) {
      print('fetching past data? $next, $previous');
      if (next) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          const MaterialBanner(
            content: Text('Fetching historical data...'),
            backgroundColor: Colors.green,
            actions: <Widget>[
              SizedBox(height: 0),
            ],
          ),
        );
      } else if (previous != null && previous) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    }));
    return Scaffold(
        appBar: AppBar(
          title: const Text('Energy Data'),
        ),
        drawer: const STSDrawer(),
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
              num totalConsumption = combinedIntervals.totalConsumption;
              num totalGrid = combinedIntervals.totalGrid;
              num totalProduction = combinedIntervals.totalProduction;
              num totalSurplus = combinedIntervals.totalSurplus;
              num totalNet = combinedIntervals.totalNet;
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
                                title: 'Surplus',
                                value: totalSurplus,
                                valueColor: Colors.green.shade500,
                                valueUnits: 'kWh',
                              ),
                              NumberCard(
                                title: 'Production',
                                value: totalProduction,
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
                                title: 'Grid Cons.',
                                value: totalGrid,
                                valueColor: Colors.red.shade900,
                                valueUnits: 'kWh',
                              ),
                              NumberCard(
                                title: 'Consumption',
                                value: totalConsumption,
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
                        child: IntervalsChart(
                          intervalsData: combinedIntervals.intervalsList,
                        ))
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
