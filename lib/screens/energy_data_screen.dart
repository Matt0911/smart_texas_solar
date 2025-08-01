import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/providers/past_intervals_data_fetcher_provider.dart';
import 'package:smart_texas_solar/widgets/sts_drawer.dart';

import '../providers/combined_intervals_data_provider.dart';
import '../providers/selected_dates_provider.dart';
import '../widgets/intervals_chart.dart';

final _formatter = DateFormat('MMM dd, yyyy');
final _formatterNoYear = DateFormat('MMM dd');
String getSelectedDateText(DateTime start, DateTime end) {
  var startStr = _formatter.format(start);
  var endStr = _formatter.format(end);
  if (startStr == endStr) return startStr;
  return '${_formatterNoYear.format(start)} - $endStr';
}

class EnergyDataScreen extends ConsumerWidget {
  static const String routeName = '/energy-data-screen';

  const EnergyDataScreen({super.key});

  @override
  Widget build(context, ref) {
    var selectedDates = ref.watch(selectedDatesProvider);
    var intervals = ref.watch(combinedIntervalsDataProvider);
    ref.listen<bool>(pastIntervalsDataFetcherProvider, ((previous, next) {
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
        title: Text(
            'Energy Data: ${getSelectedDateText(selectedDates.startDate, selectedDates.endDate)}'),
        actions: [
          IconButton(
            onPressed: () async {
              DateTimeRange? range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2010),
                lastDate: DateTime.now().subtract(const Duration(days: 2)),
                initialDateRange: DateTimeRange(
                  start: selectedDates.startDate,
                  end: selectedDates.endDate,
                ),
              );
              if (range != null) {
                selectedDates.updateDates(
                  start: range.start,
                  end: range.end,
                );
              }
            },
            icon: const Icon(
              Icons.calendar_today,
            ),
            // TODO: add button to reset data for a particular day somewhere
          )
        ],
      ),
      drawer: const STSDrawer(),
      body: intervals.when(
        data: (combinedIntervals) {
          return IntervalsChart(
            combinedIntervalsData: combinedIntervals,
          );
        },
        error: (e, s) => Text('$e with stack $s '),
        loading: () => const Text('loading'),
      ),
    );
  }
}
