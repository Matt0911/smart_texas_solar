import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/models/combined_interval.dart';
import 'package:smart_texas_solar/providers/enphase/intervals_data_provider.dart';
import 'package:smart_texas_solar/providers/smt/intervals_data_provider.dart';

import '../models/enphase_intervals.dart';

final combinedIntervalsDataProvider = FutureProvider.autoDispose
    .family<CombinedIntervalsData, BuildContext>((ref, context) async {
  var smtIntervals = await ref.watch(smtIntervalsDataProvider.future);
  var enphaseIntervals =
      await ref.watch(enphaseIntervalsDataProvider(context).future);

  return CombinedIntervalsData(
      smtData: smtIntervals, enpahseData: enphaseIntervals);
});

class CombinedIntervalsData {
  List<CombinedInterval> intervalsData;

  CombinedIntervalsData(
      {required EnphaseIntervals enpahseData,
      required SMTIntervalsData smtData})
      : intervalsData = enpahseData.generationData
            .asMap()
            .map(
              (index, value) => MapEntry(
                  index,
                  CombinedInterval(
                    endTime: value.endTime,
                    kwhGridConsumption: smtData.consumptionData[index].kwh,
                    kwhSurplusGeneration: smtData.surplusData[index].kwh,
                    kwhSolarProduction: value.kwh,
                  )),
            )
            .values
            .toList();
}
