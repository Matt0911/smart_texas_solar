import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/providers/enphase/api_service_provider.dart';
import 'package:smart_texas_solar/providers/selected_dates_provider.dart';

import '../../models/enphase_intervals.dart';

final enphaseIntervalsDataProvider = FutureProvider.autoDispose
    .family<Map<DateTime, EnphaseIntervals>, BuildContext>(
        (ref, context) async {
  EnphaseApiService apiService =
      await ref.watch(enphaseApiServiceProvider.future);
  SelectedDates selectedDates = ref.watch(selectedDatesProvider);

  return await apiService.fetchIntervals(
    context: context,
    startDate: selectedDates.startDate,
    endDate: selectedDates.endDate,
  );
});
