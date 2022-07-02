import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/models/interval.dart' as models;
import 'package:smart_texas_solar/providers/enphase/intervals_service_provider.dart';
import 'package:smart_texas_solar/providers/selected_dates_provider.dart';

final enphaseIntervalsDataProvider = FutureProvider.autoDispose
    .family<EnphaseIntervalsData, BuildContext>((ref, context) async {
  EnphaseApiService apiService = ref.watch(enphaseApiServiceProvider);
  SelectedDates selectedDates = ref.watch(selectedDatesProvider);

  var response = await apiService.fetchIntervals(
    context: context,
    startDate: selectedDates.startDate,
    endDate: selectedDates.endDate,
  );
  return EnphaseIntervalsData(response);
});

class EnphaseIntervalsData {
  List<models.Interval> generationData;
  EnphaseIntervalsData(Map<String, dynamic> enphaseIntervalResponse)
      : generationData = (enphaseIntervalResponse['intervals'] as List)
            .map((d) => models.Interval(
                endTime:
                    DateTime.fromMillisecondsSinceEpoch(d['end_at'] * 1000),
                kwh: d['wh_del'] / 1000))
            .toList();
}
