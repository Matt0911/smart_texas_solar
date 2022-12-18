import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/providers/smt/api_service_provider.dart';
import 'package:smart_texas_solar/util/date_util.dart';

import 'enphase/api_service_provider.dart';

final pastIntervalsDataFetcherProvider =
    StateNotifierProvider.autoDispose<PastIntervalsFetcher, bool>((ref) {
  return PastIntervalsFetcher(ref);
});

class PastIntervalsFetcher extends StateNotifier<bool> {
  Future<EnphaseApiService> enphaseApiServiceFuture;
  Future<SMTApiService> smtApiServiceFuture;
  PastIntervalsFetcher(
      AutoDisposeStateNotifierProviderRef<PastIntervalsFetcher, bool> ref)
      : enphaseApiServiceFuture = ref.watch(enphaseApiServiceProvider.future),
        smtApiServiceFuture = ref.watch(smtApiServiceProvider.future),
        super(false) {
    _fetchPastIntervals();
  }

  void _fetchPastIntervals() async {
    EnphaseApiService enphaseApiService = await enphaseApiServiceFuture;
    SMTApiService smtApiService = await smtApiServiceFuture;
    DateTime currentEndDate = getDateFromToday(-3, true);
    DateTime twoYearsAgo = getDateFromToday(365 * -2, true);
    DateTime solarStartDate = await enphaseApiService.getSystemStartDate();

    while (!(currentEndDate.isBefore(solarStartDate) || currentEndDate.isBefore(twoYearsAgo))) {
      DateTime sixDaysBefore = currentEndDate.subtract(const Duration(days: 6));
      DateTime fetchStartDate = sixDaysBefore;
      bool beforeSolarStart = sixDaysBefore.isBefore(solarStartDate);
      bool beforeTwoYearsAgo = sixDaysBefore.isBefore(twoYearsAgo);
      if (beforeSolarStart || beforeTwoYearsAgo) {
        if (solarStartDate.isAfter(twoYearsAgo)) {
          fetchStartDate = solarStartDate;
        } else {
          fetchStartDate = twoYearsAgo;
        }
      }
      fetchStartDate = getStartOfDay(fetchStartDate);
      var enphaseSavedData = enphaseApiService.getIntervalsSavedForDates(
        fetchStartDate,
        currentEndDate,
      );
      bool needsToFetchEnphase = enphaseSavedData == null;
      var smtSavedData = smtApiService.getIntervalsSavedForDates(
        fetchStartDate,
        currentEndDate,
      );
      bool needsToFetchSMT = smtSavedData == null;

      if (needsToFetchEnphase || needsToFetchSMT) {
        state = true;
      }
      if (needsToFetchEnphase) {
        print('fetching enphase: $fetchStartDate-$currentEndDate');
        await enphaseApiService.fetchIntervals(
          startDate: fetchStartDate,
          endDate: currentEndDate,
        );
      }
      if (needsToFetchSMT) {
        print('fetching smt: $fetchStartDate-$currentEndDate');
        await smtApiService.fetchIntervals(
          startDate: fetchStartDate,
          endDate: currentEndDate,
        );
      }

      currentEndDate = currentEndDate.subtract(const Duration(days: 7));
      if(!(currentEndDate.isBefore(solarStartDate) || currentEndDate.isBefore(twoYearsAgo))) {
        // Enphase has strict 10 api calls/min limit, do 6/min here to allow for
        //   normal user interaction too
        await Future.delayed(const Duration(seconds: 10));
      }
    }

    // done fetching history
    state = false;
  }
}
