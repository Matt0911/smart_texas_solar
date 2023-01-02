import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/models/billing_data.dart';
import 'package:smart_texas_solar/models/smt_intervals.dart';
import 'package:smart_texas_solar/providers/smt/billing_data_provider.dart';
import 'package:smart_texas_solar/util/date_util.dart';
import 'package:smart_texas_solar/widgets/sts_drawer.dart';

import '../models/enphase_intervals.dart';
import '../providers/enphase/api_service_provider.dart';
import '../providers/past_intervals_data_fetcher_provider.dart';
import '../providers/smt/api_service_provider.dart';
import '../widgets/number_card.dart';

final _formatter = DateFormat('MMM dd');

const kTableHeaderStyle =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 2);

String getBillDateRange(DateTime start, DateTime end) {
  return '${_formatter.format(start)} - ${_formatter.format(end)} ${end.year}';
}

class BillingListDataWrapper {
  bool isExpanded = false;
  BillingData rawData;
  num totalGridConsumption;
  num totalSurplusGeneration;
  num totalGeneration;

  BillingListDataWrapper(
    this.rawData, {
    required this.totalGeneration,
    required this.totalGridConsumption,
    required this.totalSurplusGeneration,
  });
}

class EnergyBillScreen extends ConsumerStatefulWidget {
  static const String routeName = '/energy-bill-screen';

  const EnergyBillScreen({super.key});

  @override
  EnergyBillScreenState createState() => EnergyBillScreenState();
}

class EnergyBillScreenState extends ConsumerState<EnergyBillScreen> {
  bool isBillingLoaded = false;
  bool isHistoryLoaded = false;
  List<BillingData> rawBillingData = [];
  List<BillingListDataWrapper>? data;

  void setData() async {
    if (isBillingLoaded && isHistoryLoaded) {
      var enphaseApiService = await ref.watch(enphaseApiServiceProvider.future);
      var smtApiService = await ref.watch(smtApiServiceProvider.future);
      List<BillingListDataWrapper> newData = [];
      for (var bill in rawBillingData.reversed) {
        DateTime start = getStartOfDay(bill.startDate);
        DateTime end = getEndOfDay(bill.endDate);
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
        for (var dayIntervals in smtIntervalsMap.values) {
          totalGridConsumption += dayIntervals.consumptionData
              .fold(0, (previousValue, element) => previousValue + element.kwh);
          totalSurplusGeneration += dayIntervals.surplusData
              .fold(0, (previousValue, element) => previousValue + element.kwh);
        }

        num totalGeneration = 0;
        for (var dayIntervals in enphaseIntervalsMap.values) {
          totalGeneration += dayIntervals.generationData
              .fold(0, (previousValue, element) => previousValue + element.kwh);
        }

        newData.add(
          BillingListDataWrapper(
            bill,
            totalGeneration: totalGeneration,
            totalGridConsumption: totalGridConsumption,
            totalSurplusGeneration: totalSurplusGeneration,
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
      setState(() {
        rawBillingData = billingData;
        isBillingLoaded = true;
      });
      setData();
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
                  data![panelIndex].isExpanded = !isExpanded;
                }),
                children: data!
                    .map(
                      (bill) => ExpansionPanel(
                        isExpanded: bill.isExpanded,
                        backgroundColor: Colors.grey[850],
                        headerBuilder: (context, isExpanded) => ListTile(
                          title: Text(getBillDateRange(
                              bill.rawData.startDate, bill.rawData.endDate)),
                        ),
                        body: Row(
                          children: [
                            NumberCard(
                              title: 'Billed Cons',
                              value: bill.rawData.kwh,
                              valueColor: Colors.red.shade900,
                              valueUnits: 'kWh',
                            ),
                            NumberCard(
                              title: 'Grid Cons',
                              value: bill.totalGridConsumption,
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
                      ),
                    )
                    .toList(),
              ),
            )
          : const Text('Loading...'),
    );
  }
}
