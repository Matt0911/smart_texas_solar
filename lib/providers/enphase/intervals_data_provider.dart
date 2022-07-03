import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/providers/enphase/intervals_service_provider.dart';
import 'package:smart_texas_solar/providers/hive/enphase_intervals_store_provider.dart';
import 'package:smart_texas_solar/providers/selected_dates_provider.dart';

import '../../models/enphase_intervals.dart';

final enphaseIntervalsDataProvider = FutureProvider.autoDispose
    .family<EnphaseIntervals, BuildContext>((ref, context) async {
  EnphaseApiService apiService = ref.watch(enphaseApiServiceProvider);
  SelectedDates selectedDates = ref.watch(selectedDatesProvider);
  EnphaseIntervalsStore intervalsStore =
      await ref.watch(enphaseIntervalsStoreProvider.future);

  EnphaseIntervals? storedIntervals =
      intervalsStore.getIntervals(selectedDates.startDate);

  if (storedIntervals != null) {
    return storedIntervals;
  }

  var response = await apiService.fetchIntervals(
    context: context,
    startDate: selectedDates.startDate,
    endDate: selectedDates.endDate,
  );
  var fetchedIntervals = EnphaseIntervals.fromData(response);
  intervalsStore.storeIntervals(fetchedIntervals, selectedDates.startDate);
  return fetchedIntervals;
});
