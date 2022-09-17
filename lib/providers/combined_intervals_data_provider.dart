import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/models/combined_interval.dart';
import 'package:smart_texas_solar/models/interval_map.dart';
import 'package:smart_texas_solar/providers/enphase/intervals_data_provider.dart';
import 'package:smart_texas_solar/providers/smt/intervals_data_provider.dart';

import '../models/enphase_intervals.dart';
import '../models/smt_intervals.dart';

final combinedIntervalsDataProvider = FutureProvider.autoDispose
    .family<CombinedIntervalsData, BuildContext>((ref, context) async {
  var smtIntervals = await ref.watch(smtIntervalsDataProvider.future);
  var enphaseIntervals =
      await ref.watch(enphaseIntervalsDataProvider(context).future);

  return CombinedIntervalsData(
      smtData: smtIntervals, enpahseData: enphaseIntervals);
});

Map<DateTime, List<CombinedInterval>> _combineEnphaseAndSMTData(
  Map<DateTime, EnphaseIntervals> enpahseData,
  Map<DateTime, SMTIntervals> smtData,
) {
  Map<DateTime, List<CombinedInterval>> data = {};
  for (var d in enpahseData.keys) {
    data[d] = <CombinedInterval>[];
    var enphase = enpahseData[d]!.generationMap;
    var smtConsumption = smtData[d]!.consumptionMap;
    var smtSurplus = smtData[d]!.surplusMap;
    for (var it in IntervalTime.values) {
      data[d]!.add(
        CombinedInterval(
          endTime: enphase.getInterval(it)!.endTime, // TODO: nulls?
          kwhGridConsumption: smtConsumption.getInterval(it)!.kwh,
          kwhSurplusGeneration: smtSurplus.getInterval(it)!.kwh,
          kwhSolarProduction: enphase.getInterval(it)!.kwh,
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
