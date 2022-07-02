import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/models/interval.dart';
import 'package:smart_texas_solar/providers/selected_dates_provider.dart';
import 'package:smart_texas_solar/providers/smt/intervals_service_provider.dart';

final smtIntervalsDataProvider = FutureProvider<SMTIntervalsData>((ref) async {
  IntervalsService intervalsService =
      await ref.watch(smtIntervalsServiceProvider.future);
  SelectedDates selectedDates = ref.watch(selectedDatesProvider);

  var response = await intervalsService.fetchIntervals(
    startDate: selectedDates.startDate,
    endDate: selectedDates.endDate,
  );
  return SMTIntervalsData(response);
});

final DateFormat _formatter = DateFormat('yyyy-MM-dd hh:mm a');

class SMTIntervalsData {
  List<Interval> consumptionData;
  List<Interval> surplusData;
  SMTIntervalsData(Map<String, dynamic> smtIntervalResponse)
      : consumptionData = (smtIntervalResponse['intervaldata'] as List)
            .map((d) => Interval(
                endTime: _formatter.parse(
                    '${d['date']} ${d['endtime'].toString().trimLeft().toUpperCase()}'),
                kwh: d['consumption']))
            .toList(),
        surplusData = (smtIntervalResponse['intervaldata'] as List)
            .map((d) => Interval(
                endTime: _formatter.parse(
                    '${d['date']} ${d['endtime'].toString().trimLeft().toUpperCase()}'),
                kwh: d['generation']))
            .toList();
}
