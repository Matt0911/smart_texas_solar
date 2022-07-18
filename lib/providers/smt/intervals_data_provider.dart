import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/providers/selected_dates_provider.dart';
import 'package:smart_texas_solar/providers/smt/api_service_provider.dart';

import '../../models/smt_intervals.dart';

final smtIntervalsDataProvider = FutureProvider<SMTIntervals>((ref) async {
  IntervalsService intervalsService =
      await ref.watch(smtApiServiceProvider.future);
  SelectedDates selectedDates = ref.watch(selectedDatesProvider);

  return await intervalsService.fetchIntervals(
    startDate: selectedDates.startDate,
    endDate: selectedDates.endDate,
  );
});
