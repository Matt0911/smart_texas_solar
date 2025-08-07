import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/providers/enphase/api_service_provider.dart';
import 'package:smart_texas_solar/providers/selected_dates_provider.dart';

import '../../models/enphase_intervals.dart';

final enphaseIntervalsDataProvider =
    FutureProvider.autoDispose<Map<DateTime, EnphaseIntervals>>((ref) async {
  SelectedDates selectedDates = ref.watch(selectedDatesProvider);
  EnphaseApiService? apiService =
      await ref.watch(enphaseApiServiceProvider.future);

  if (apiService == null) {
    return {};
  }

  return await apiService.fetchIntervals(
    startDate: selectedDates.startDate,
    endDate: selectedDates.endDate,
  );
});
