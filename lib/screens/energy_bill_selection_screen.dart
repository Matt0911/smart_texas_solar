import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/models/billing_data.dart';
import 'package:smart_texas_solar/models/interval_map.dart';
import 'package:smart_texas_solar/providers/smt/billing_data_provider.dart';
import 'package:smart_texas_solar/screens/energy_plan_cost_estimate_screen.dart';
import 'package:smart_texas_solar/util/date_util.dart';
import 'package:smart_texas_solar/widgets/sts_drawer.dart';

import '../models/energy_plan.dart';
import '../models/interval.dart' as sts_interval;
import '../providers/enphase/api_service_provider.dart';
import '../providers/hive/energy_plan_store_provider.dart';
import '../providers/past_intervals_data_fetcher_provider.dart';
import '../providers/smt/api_service_provider.dart';

final _formatter = DateFormat('MMM d');

const kTableHeaderStyle =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 2);

String getBillDateRange(DateTime start, DateTime end) {
  return '${_formatter.format(start)} - ${_formatter.format(end)} ${end.year}';
}

class BillingCheckboxListDataWrapper {
  bool isChecked;
  BillingData rawData;
  num totalGridConsumption;
  num avgGridConsumption;
  num totalSurplusGeneration;
  num avgSurplusGeneration;
  num totalGeneration;
  num totalConsumption;
  num? estimatedBillAmount;
  IntervalMap periodConsumptionByTime;
  IntervalMap periodTotalConsumptionByTime;

  BillingCheckboxListDataWrapper(
    this.rawData, {
    required this.totalGeneration,
    required this.totalGridConsumption,
    required this.avgGridConsumption,
    required this.totalSurplusGeneration,
    required this.avgSurplusGeneration,
    required this.totalConsumption,
    required this.periodConsumptionByTime,
    required this.periodTotalConsumptionByTime,
    this.estimatedBillAmount,
    this.isChecked = false,
  });
}

class EnergyBillSelectionScreen extends ConsumerStatefulWidget {
  static const String routeName = '/energy-bill-selection-screen';

  const EnergyBillSelectionScreen({super.key});

  @override
  EnergyBillSelectionScreenState createState() =>
      EnergyBillSelectionScreenState();
}

class EnergyBillSelectionScreenState
    extends ConsumerState<EnergyBillSelectionScreen> {
  bool isBillingLoaded = false;
  bool isHistoryLoaded = false;
  List<BillingData> rawBillingData = [];
  List<BillingCheckboxListDataWrapper>? data;
  List<EnergyPlan> energyPlans = [];

  void setData() async {
    if (isBillingLoaded && isHistoryLoaded) {
      var enphaseApiService = await ref.watch(enphaseApiServiceProvider.future);
      var smtApiService = await ref.watch(smtApiServiceProvider.future);
      List<BillingCheckboxListDataWrapper> newData = [];
      for (var bill in rawBillingData.reversed) {
        DateTime start = getStartOfDay(bill.startDate);
        DateTime end = getEndOfDay(bill.endDate);
        bool planChecker(EnergyPlan p) => p.startDate != null
            ? p.startDate!.isBefore(start.add(const Duration(minutes: 1))) &&
                (p.endDate != null
                    ? p.endDate!
                        .isAfter(end.subtract(const Duration(minutes: 1)))
                    : true)
            : false;
        EnergyPlan? plan = energyPlans.any(planChecker)
            ? energyPlans.firstWhere(planChecker)
            : null;
        var smtIntervalsMap = await smtApiService.fetchIntervals(
          startDate: start,
          endDate: end,
        );
        var enphaseIntervalsMap = await enphaseApiService.fetchIntervals(
          startDate: start,
          endDate: end,
        );

        num totalGridConsumption = 0;
        num totalSurplusGeneration = 0;
        List<sts_interval.Interval> allGridConsumptionIntervals = [];
        List<sts_interval.Interval> allSurplusIntervals = [];
        for (var dayIntervals in smtIntervalsMap.values) {
          allGridConsumptionIntervals.addAll(dayIntervals.consumptionData);
          allSurplusIntervals.addAll(dayIntervals.surplusData);
          totalGridConsumption += dayIntervals.consumptionData
              .fold(0, (previousValue, element) => previousValue + element.kwh);
          totalSurplusGeneration += dayIntervals.surplusData
              .fold(0, (previousValue, element) => previousValue + element.kwh);
        }
        IntervalMap periodGridConsumptionByTime =
            IntervalMap(allGridConsumptionIntervals);
        IntervalMap periodSurplusByTime = IntervalMap(allSurplusIntervals);

        num? estimatedBillAmount;
        if (plan != null) {
          estimatedBillAmount = plan.calculateBill(
                consumptionGrid: totalGridConsumption,
                solarSurplus: totalSurplusGeneration,
                consumptionByTime: periodGridConsumptionByTime,
              ) ??
              0;
        }

        num totalGeneration = 0;
        List<sts_interval.Interval> allGenerationIntervals = [];
        for (var dayIntervals in enphaseIntervalsMap.values) {
          allGenerationIntervals.addAll(dayIntervals.generationData);
          totalGeneration += dayIntervals.generationData
              .fold(0, (previousValue, element) => previousValue + element.kwh);
        }
        IntervalMap periodGenerationByTime =
            IntervalMap(allGenerationIntervals);

        num totalConsumption =
            totalGridConsumption + totalGeneration - totalSurplusGeneration;

        IntervalMap periodTotalConsumptionByTime =
            IntervalMap.clone(periodGridConsumptionByTime);
        periodTotalConsumptionByTime.addIntervalMap(periodGenerationByTime);
        periodTotalConsumptionByTime.subtractIntervalMap(periodSurplusByTime);

        num daysForBill = bill.endDate.difference(bill.startDate).inDays + 1;

        newData.add(
          BillingCheckboxListDataWrapper(
            bill,
            totalGeneration: totalGeneration,
            totalGridConsumption: totalGridConsumption,
            avgGridConsumption: totalGridConsumption / daysForBill,
            totalSurplusGeneration: totalSurplusGeneration,
            avgSurplusGeneration: totalSurplusGeneration / daysForBill,
            totalConsumption: totalConsumption,
            periodConsumptionByTime: periodGridConsumptionByTime,
            periodTotalConsumptionByTime: periodTotalConsumptionByTime,
            estimatedBillAmount: estimatedBillAmount,
            isChecked: bill.startDate.isAfter(
              getStartOfDay(DateTime.now().subtract(const Duration(days: 365)))
                  .subtract(const Duration(hours: 1)),
            ),
          ),
        );
      }
      setState(() {
        data = newData;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    isHistoryLoaded = !ref.read(pastIntervalsDataFetcherProvider);
    var billingDataFuture = ref.read(billingDataProvider.future);
    var energyPlanStoreFuture = ref.read(energyPlanStoreProvider.future);
    billingDataFuture.then((billingData) {
      energyPlanStoreFuture.then((energyPlanStore) {
        setState(() {
          energyPlans = energyPlanStore.getStoredEnergyPlans() ?? [];
          rawBillingData = billingData;
          isBillingLoaded = true;
        });
        setData();
      });
    });
  }

  @override
  Widget build(context) {
    ref.listen<bool>(pastIntervalsDataFetcherProvider, ((previous, next) {
      if (next) {
        setState(() {
          isHistoryLoaded = false;
        });
        ScaffoldMessenger.of(context).showMaterialBanner(
          const MaterialBanner(
            content: Text('Fetching historical data...'),
            backgroundColor: Colors.green,
            actions: <Widget>[
              SizedBox(height: 0),
            ],
          ),
        );
      } else if (previous != null && previous) {
        setState(() {
          isHistoryLoaded = true;
        });
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        setData();
      }
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Plan Cost Estimate'),
      ),
      drawer: const STSDrawer(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed(
              EnergyPlanCostEstimateScreen.routeName,
              arguments: data!.where((bill) => bill.isChecked).toList(),
            );
          },
          child: const Text('Continue'),
        ),
      ),
      body: isBillingLoaded && isHistoryLoaded && data != null
          ? ListView(
              children: [
                ...data!.map(
                  (bill) => CheckboxListTile(
                    value: bill.isChecked,
                    title: Text(
                      getBillDateRange(
                          bill.rawData.startDate, bill.rawData.endDate),
                    ),
                    onChanged: (value) => setState(() {
                      bill.isChecked = value!;
                    }),
                  ),
                ),
              ],
            )
          : const Text('Loading...'),
    );
  }
}
