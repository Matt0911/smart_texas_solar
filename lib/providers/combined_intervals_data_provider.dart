import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/models/combined_interval.dart';
import 'package:smart_texas_solar/models/interval_map.dart';
import 'package:smart_texas_solar/providers/enphase/intervals_data_provider.dart';
import 'package:smart_texas_solar/providers/smt/intervals_data_provider.dart';

import '../models/enphase_intervals.dart';
import '../models/smt_intervals.dart';

final combinedIntervalsDataProvider =
    FutureProvider.autoDispose<CombinedIntervalsData>((ref) async {
  var smtIntervals = await ref.watch(smtIntervalsDataProvider.future);
  var enphaseIntervals = await ref.watch(enphaseIntervalsDataProvider.future);

  return CombinedIntervalsData(
      smtData: smtIntervals, enpahseData: enphaseIntervals);
});

int _getNumberOfIntervalsToCombine(int numDaysToDisplay) {
  if (numDaysToDisplay <= 1) {
    return 1; // 15 min data
  }
  if (numDaysToDisplay <= 2) {
    return 2; // 30 min
  }
  if (numDaysToDisplay <= 4) {
    return 4; // hourly
  }
  if (numDaysToDisplay <= 7) {
    return 12; // 3 hours
  }
  return 96; // daily data
}

Map<DateTime, List<CombinedInterval>> _combineEnphaseAndSMTData(
  Map<DateTime, EnphaseIntervals> enpahseData,
  Map<DateTime, SMTIntervals> smtData,
) {
  assert(enpahseData.length == smtData.length);
  Map<DateTime, List<CombinedInterval>> data = {};
  int sliceSize = _getNumberOfIntervalsToCombine(enpahseData.length);
  for (var day in enpahseData.keys) {
    data[day] = <CombinedInterval>[];
    var enphase = enpahseData[day]!.generationMap;
    var smtConsumption = smtData[day]!.consumptionMap;
    var smtSurplus = smtData[day]!.surplusMap;

    for (int i = 0; i < IntervalTime.values.length; i += sliceSize) {
      var itSublist = IntervalTime.values.sublist(i, i + sliceSize);
      data[day]!.add(
        // TODO: handle combining days together
        CombinedInterval(
          endTime: enphase.getInterval(itSublist.last)!.endTime,
          startTime: enphase
              .getInterval(itSublist.first)!
              .endTime
              .subtract(const Duration(minutes: 15)),
          kwhGridConsumption: itSublist
              .map(
                (it) => smtConsumption.getInterval(it)!.kwh,
              )
              .fold<num>(
                0,
                (prev, element) => prev + element,
              ),
          kwhSurplusGeneration: itSublist
              .map(
                (it) => smtSurplus.getInterval(it)!.kwh,
              )
              .fold<num>(
                0,
                (prev, element) => prev + element,
              ),
          kwhSolarProduction: itSublist
              .map(
                (it) => enphase.getInterval(it)!.kwh,
              )
              .fold<num>(
                0,
                (prev, element) => prev + element,
              ),
        ),
      );
    }
  }
  return data;
}

class CombinedIntervalsData {
  Map<DateTime, List<CombinedInterval>> intervalsData;

  num get totalConsumption {
    return intervalsData.values.fold<num>(
      0,
      (sum, l) =>
          sum +
          l.fold<num>(
            0,
            (s, i) => s + i.kwhTotalConsumption,
          ),
    );
  }

  num get totalGrid {
    return intervalsData.values.fold<num>(
      0,
      (sum, l) =>
          sum +
          l.fold<num>(
            0,
            (s, i) => s + i.kwhGridConsumption,
          ),
    );
  }

  num get totalProduction {
    return intervalsData.values.fold<num>(
      0,
      (sum, l) =>
          sum +
          l.fold<num>(
            0,
            (s, i) => s + i.kwhSolarProduction,
          ),
    );
  }

  num get totalSurplus {
    return intervalsData.values.fold<num>(
      0,
      (sum, l) =>
          sum +
          l.fold<num>(
            0,
            (s, i) => s + i.kwhSurplusGeneration,
          ),
    );
  }

  num get totalNet {
    return totalProduction - totalConsumption;
  }

  List<CombinedInterval> get intervalsList => intervalsData.values.reduce(
        (value, element) => [...value, ...element],
      );

  CombinedIntervalsData(
      {required Map<DateTime, EnphaseIntervals> enpahseData,
      required Map<DateTime, SMTIntervals> smtData})
      : intervalsData = _combineEnphaseAndSMTData(enpahseData, smtData);
}
