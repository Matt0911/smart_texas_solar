import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/providers/selected_dates_provider.dart';
import 'package:smart_texas_solar/providers/smt/intervals_service_provider.dart';

import '../../models/smt_intervals.dart';
import '../hive/smt_intervals_store_provider.dart';

final smtIntervalsDataProvider = FutureProvider<SMTIntervals>((ref) async {
  IntervalsService intervalsService =
      await ref.watch(smtIntervalsServiceProvider.future);
  SelectedDates selectedDates = ref.watch(selectedDatesProvider);
  SMTIntervalsStore intervalsStore =
      await ref.watch(smtIntervalsStoreProvider.future);

  SMTIntervals? storedIntervals =
      intervalsStore.getIntervals(selectedDates.startDate);

  if (storedIntervals != null) {
    return storedIntervals;
  }

  var response = await intervalsService.fetchIntervals(
    startDate: selectedDates.startDate,
    endDate: selectedDates.endDate,
  );
  var fetchedIntervals = SMTIntervals.fromData(response);
  intervalsStore.storeIntervals(fetchedIntervals, selectedDates.startDate);
  return fetchedIntervals;
});
