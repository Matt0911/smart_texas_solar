import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

class SMTInterval {
  DateTime startTime;
  DateTime endTime;
  num consumption;
  bool consumptionIsActual;
  num generation;
  bool generationIsActual;

  SMTInterval.fromData(Map data)
      : consumption = data['consumption'],
        consumptionIsActual = data['consumption_est_act'] == 'A',
        generation = data['generation'],
        generationIsActual = data['generation_est_act'] == 'A',
        startTime = _formatter.parse(
            '${data['date']} ${data['starttime'].toString().trimLeft().toUpperCase()}'),
        endTime = _formatter.parse(
            '${data['date']} ${(data['endtime'].toString().trimLeft().toUpperCase())}');

  @override
  String toString() {
    return '$startTime - c: $consumption, g: $generation';
  }
}

class SMTIntervalsData {
  List<SMTInterval> intervalData;
  SMTIntervalsData(Map<String, dynamic> smtIntervalResponse)
      : intervalData = (smtIntervalResponse['intervaldata'] as List)
            .map((d) => SMTInterval.fromData(d))
            .toList();
}
