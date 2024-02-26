import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/models/billing_data.dart';
import 'package:smart_texas_solar/models/interval_map.dart';
import 'package:smart_texas_solar/providers/smt/billing_data_provider.dart';
import 'package:smart_texas_solar/util/date_util.dart';
import 'package:smart_texas_solar/widgets/sts_drawer.dart';

import '../models/energy_plan.dart';
import '../models/interval.dart' as sts_interval;
import '../providers/enphase/api_service_provider.dart';
import '../providers/hive/energy_plan_store_provider.dart';
import '../providers/past_intervals_data_fetcher_provider.dart';
import '../providers/smt/api_service_provider.dart';
import '../widgets/number_card.dart';

const kTableHeaderStyle =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 2);

class BillingListDataWrapper {
  bool isExpanded = false;
  BillingData rawData;
  num totalGridConsumption;
  num totalSurplusGeneration;
  num totalGeneration;
  num totalConsumption;
  num? estimatedBillAmount;

  BillingListDataWrapper(
    this.rawData, {
    required this.totalGeneration,
    required this.totalGridConsumption,
    required this.totalSurplusGeneration,
    required this.totalConsumption,
    this.estimatedBillAmount,
  });
}

class EnergyBillHistoryScreen extends ConsumerStatefulWidget {
  static const String routeName = '/energy-bill-history-screen';

  const EnergyBillHistoryScreen({super.key});

  @override
  EnergyBillHistoryScreenState createState() => EnergyBillHistoryScreenState();
}

class EnergyBillHistoryScreenState
    extends ConsumerState<EnergyBillHistoryScreen> {
  bool isBillingLoaded = false;
  bool isHistoryLoaded = false;
  List<BillingData> rawBillingData = [];
  List<BillingListDataWrapper>? data;
  List<EnergyPlan> energyPlans = [];

  void setData() async {
    if (isBillingLoaded && isHistoryLoaded) {
      var enphaseApiService = await ref.watch(enphaseApiServiceProvider.future);
      var smtApiService = await ref.watch(smtApiServiceProvider.future);
      List<BillingListDataWrapper> newData = [];
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
        List<sts_interval.Interval> allConsumptionIntervals = [];
        for (var dayIntervals in smtIntervalsMap.values) {
          allConsumptionIntervals.addAll(dayIntervals.consumptionData);
          totalGridConsumption += dayIntervals.consumptionData
              .fold(0, (previousValue, element) => previousValue + element.kwh);
          totalSurplusGeneration += dayIntervals.surplusData
              .fold(0, (previousValue, element) => previousValue + element.kwh);
        }
        IntervalMap periodConsumptionByTime =
            IntervalMap(allConsumptionIntervals);

        num? estimatedBillAmount;
        if (plan != null) {
          estimatedBillAmount = plan.calculateBill(
                consumptionGrid: totalGridConsumption,
                solarSurplus: totalSurplusGeneration,
                consumptionByTime: periodConsumptionByTime,
              ) ??
              0;
        }

        num totalGeneration = 0;
        for (var dayIntervals in enphaseIntervalsMap.values) {
          totalGeneration += dayIntervals.generationData
              .fold(0, (previousValue, element) => previousValue + element.kwh);
        }

        num totalConsumption =
            totalGridConsumption + totalGeneration - totalSurplusGeneration;

        newData.add(
          BillingListDataWrapper(
            bill,
            totalGeneration: totalGeneration,
            totalGridConsumption: totalGridConsumption,
            totalSurplusGeneration: totalSurplusGeneration,
            totalConsumption: totalConsumption,
            estimatedBillAmount: estimatedBillAmount,
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
    ref.read(billingDataProvider.future).then((billingData) {
      ref.read(energyPlanStoreProvider.future).then((energyPlanStore) {
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
        title: const Text('Energy Bill Analysis'),
      ),
      drawer: const STSDrawer(),
      body: isBillingLoaded && isHistoryLoaded && data != null
          ? SingleChildScrollView(
              child: ExpansionPanelList(
                expansionCallback: (panelIndex, isExpanded) => setState(() {
                  data![panelIndex].isExpanded = isExpanded;
                }),
                children: data!
                    .map(
                      (bill) => ExpansionPanel(
                        isExpanded: bill.isExpanded,
                        backgroundColor: Colors.grey[850],
                        headerBuilder: (context, isExpanded) => ListTile(
                          title: Text(bill.rawData.toString()),
                        ),
                        canTapOnHeader: true,
                        body: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                NumberCard(
                                  title: 'Billed Cons',
                                  value: bill.rawData.kwh,
                                  valueColor: Colors.red.shade900,
                                  valueUnits: 'kWh',
                                ),
                                NumberCard(
                                  title: 'Surplus',
                                  value: bill.totalSurplusGeneration,
                                  valueColor: Colors.green.shade500,
                                  valueUnits: 'kWh',
                                ),
                                NumberCard(
                                  title: 'Total Gen',
                                  value: bill.totalGeneration,
                                  valueColor: Colors.green.shade500,
                                  valueUnits: 'kWh',
                                ),
                              ],
                            ),
                            bill.estimatedBillAmount != null
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                        'Estimated Bill Amount: \$${bill.estimatedBillAmount!.toStringAsFixed(2)}'),
                                  )
                                : const SizedBox(height: 0),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
          : const Text('Loading...'),
    );
  }
}
