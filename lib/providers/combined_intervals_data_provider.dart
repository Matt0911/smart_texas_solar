import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/models/combined_interval.dart';
import 'package:smart_texas_solar/models/energy_plan.dart';
import 'package:smart_texas_solar/models/interval_map.dart';
import 'package:smart_texas_solar/providers/enphase/intervals_data_provider.dart';
import 'package:smart_texas_solar/providers/hive/energy_plan_store_provider.dart';
import 'package:smart_texas_solar/providers/smt/intervals_data_provider.dart';
import 'package:smart_texas_solar/util/date_util.dart';

import '../models/enphase_intervals.dart';
import '../models/smt_intervals.dart';

final combinedIntervalsDataProvider =
    FutureProvider.autoDispose<CombinedIntervalsData>((ref) async {
  var smtIntervals = await ref.watch(smtIntervalsDataProvider.future);
  var enphaseIntervals = await ref.watch(enphaseIntervalsDataProvider.future);
  var energyPlanStore = await ref.watch(energyPlanStoreProvider.future);

  return CombinedIntervalsData(
    smtData: smtIntervals,
    enpahseData: enphaseIntervals,
    energyPlanStore: energyPlanStore,
  );
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

List<CombinedInterval> _combineEnphaseAndSMTData(
  Map<DateTime, EnphaseIntervals> enpahseData,
  Map<DateTime, SMTIntervals> smtData,
  EnergyPlanStore energyPlanStore,
) {
  assert(enpahseData.length == smtData.length);
  List<CombinedInterval> intervalList = [];
  int sliceSize = _getNumberOfIntervalsToCombine(enpahseData.length);
  for (var day in enpahseData.keys) {
    // TODO: handle combining days together
    var production = enpahseData[day]!.generationMap;
    var gridConsumption = smtData[day]!.consumptionMap;
    var surplusProduction = smtData[day]!.surplusMap;

    for (int i = 0; i < IntervalTime.values.length; i += sliceSize) {
      var desiredTimes = IntervalTime.values.sublist(i, i + sliceSize);
      var filteredProduction = IntervalMap.filtered(production, desiredTimes);
      var filteredGridConsumption =
          IntervalMap.filtered(gridConsumption, desiredTimes);
      var filteredSurplusProduction =
          IntervalMap.filtered(surplusProduction, desiredTimes);

      num kwhSolarProduction = filteredProduction.totalKwh;
      num kwhGridConsumption = max(filteredGridConsumption.totalKwh, 0);
      num kwhSurplusGeneration = filteredSurplusProduction.totalKwh;

      print(
          'p: $kwhSolarProduction, g: $kwhGridConsumption, s: $kwhSurplusGeneration');

      DateTime startTime = production
          .getInterval(desiredTimes.first)!
          .endTime
          .subtract(const Duration(minutes: 15));
      DateTime endTime = production.getInterval(desiredTimes.last)!.endTime;
      EnergyPlan? plan = energyPlanStore.getEnergyPlanForDate(endTime);

      num partialFraction = 1 / (getDaysInMonth(startTime) * 96 / sliceSize);

      intervalList.add(
        CombinedInterval(
          startTime: startTime,
          endTime: endTime,
          kwhGridConsumption: kwhGridConsumption,
          kwhSurplusGeneration: kwhSurplusGeneration,
          kwhSolarProduction: kwhSolarProduction,
          cost: plan?.calculateBillPartial(
            consumptionGrid: kwhGridConsumption,
            solarSurplus: kwhSurplusGeneration,
            consumptionByTime: filteredGridConsumption,
            partialFraction: partialFraction,
          ),
        ),
      );
    }
  }
  return intervalList;
}

class CombinedIntervalsData {
  List<CombinedInterval> intervalsList;

  num get totalConsumption {
    return intervalsList.fold<num>(
      0,
      (sum, i) => sum + i.kwhTotalConsumption,
    );
  }

  num get totalGrid {
    return intervalsList.fold<num>(
      0,
      (sum, i) => sum + i.kwhGridConsumption,
    );
  }

  num get totalProduction {
    return intervalsList.fold<num>(
      0,
      (sum, i) => sum + i.kwhSolarProduction,
    );
  }

  num get totalSurplus {
    return intervalsList.fold<num>(
      0,
      (sum, i) => sum + i.kwhSurplusGeneration,
    );
  }

  num get totalNet {
    return totalProduction - totalConsumption;
  }

  num get totalCost {
    return intervalsList.fold(0, (sum, i) => sum + (i.cost ?? 0));
  }

  CombinedIntervalsData({
    required Map<DateTime, EnphaseIntervals> enpahseData,
    required Map<DateTime, SMTIntervals> smtData,
    required EnergyPlanStore energyPlanStore,
  }) : intervalsList =
            _combineEnphaseAndSMTData(enpahseData, smtData, energyPlanStore);
}
