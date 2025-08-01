import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/models/energy_plan.dart';
import 'package:smart_texas_solar/models/interval_map.dart';
import 'package:smart_texas_solar/providers/hive/energy_plan_store_provider.dart';
import 'package:smart_texas_solar/screens/energy_plan_edit_screen.dart';
import 'package:smart_texas_solar/widgets/sts_drawer.dart';

import '../providers/past_intervals_data_fetcher_provider.dart';
import 'energy_bill_selection_screen.dart';

const kTableHeaderStyle =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 2);

class EnergyPlanWrapper {
  bool isExpanded = false;
  num totalCost;
  num totalCostNoSolar;
  EnergyPlan data;
  List<String> bills;

  EnergyPlanWrapper(
    this.data, {
    this.totalCost = 0,
    this.totalCostNoSolar = 0,
    List<String>? bills,
  }) : bills = bills ?? [];
}

class EnergyPlanCostEstimateList extends ConsumerStatefulWidget {
  final List<BillingCheckboxListDataWrapper> selectedBills;
  const EnergyPlanCostEstimateList({super.key, required this.selectedBills});

  @override
  EnergyPlanCostEstimateListState createState() =>
      EnergyPlanCostEstimateListState();
}

class EnergyPlanCostEstimateListState
    extends ConsumerState<EnergyPlanCostEstimateList> {
  late TextEditingController _controller;

  bool arePlansLoaded = false;
  bool isHistoryLoaded = false;
  List<EnergyPlan> rawPlansData = [];
  List<EnergyPlanWrapper> data = [];
  bool modifyEnergyUsage = false;
  num usageChange = 0;
  IntervalTime timeToModify = IntervalTime.t0000;
  bool settingsOpen = false;

  void setData() async {
    List<EnergyPlanWrapper> wrappedData = rawPlansData.map((plan) {
      List<String> bills = [];
      num totalCostNoSolar = 0;
      num totalCost = widget.selectedBills.fold<num>(0, (prev, bill) {
        num gridCons = bill.totalGridConsumption;
        num totalCons = bill.totalConsumption;
        IntervalMap cByTime = IntervalMap.clone(bill.periodConsumptionByTime);
        if (modifyEnergyUsage) {
          gridCons += usageChange;
          cByTime.intervals[timeToModify]!.kwh += usageChange;
        }
        IntervalMap cTotalByTime =
            IntervalMap.clone(bill.periodTotalConsumptionByTime);
        if (modifyEnergyUsage) {
          totalCons += usageChange;
          cTotalByTime.intervals[timeToModify]!.kwh += usageChange;
        }

        num billCost = plan.calculateBill(
          consumptionGrid: gridCons,
          solarSurplus: bill.totalSurplusGeneration,
          consumptionByTime: cByTime,
        )!;
        num billCostNoSolar = plan.calculateBill(
          consumptionGrid: totalCons,
          solarSurplus: 0,
          consumptionByTime: cTotalByTime,
        )!;
        totalCostNoSolar += billCostNoSolar;
        bills.add(
            '${bill.rawData.toString()}: \$${billCost.toStringAsFixed(2)}');
        return prev + billCost;
      });
      return EnergyPlanWrapper(plan,
          totalCost: totalCost,
          totalCostNoSolar: totalCostNoSolar,
          bills: bills);
    }).toList();

    setState(() {
      data = wrappedData;
    });
  }

  void addPlan(EnergyPlan plan) async {
    ref.read(energyPlanStoreProvider.future).then((energyPlanStore) async {
      rawPlansData = await energyPlanStore.addEnergyPlan(plan);
      setData();
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: usageChange.toStringAsFixed(0));
    isHistoryLoaded = !ref.read(pastIntervalsDataFetcherProvider);
    ref.read(energyPlanStoreProvider.future).then((energyPlanStore) {
      setState(() {
        rawPlansData = energyPlanStore.getStoredEnergyPlans() ?? [];
        arePlansLoaded = true;
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
        title: const Text('Energy Plan Cost Estimates'),
        actions: [
          IconButton(
            onPressed: () {
              if (settingsOpen) {
                setData();
              }
              setState(() {
                settingsOpen = !settingsOpen;
              });
            },
            icon: const Icon(
              Icons.settings,
              // color: Colors.red,
            ),
          )
        ],
      ),
      drawer: const STSDrawer(),
      body: arePlansLoaded && isHistoryLoaded
          ? Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: settingsOpen ? 203 : 0,
                  child: settingsOpen
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(16)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Modify Energy Consumption?'),
                                    Checkbox(
                                      value: modifyEnergyUsage,
                                      onChanged: (bool? val) {
                                        setState(() {
                                          modifyEnergyUsage = val ?? false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                        flex: 2,
                                        child:
                                            Text('Consumption Change (kWh)')),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        decoration: const InputDecoration(
                                          labelText: "Enter your number",
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == '' || value == '-') {
                                              usageChange = 0;
                                            } else {
                                              usageChange =
                                                  double.tryParse(value) ?? 0;
                                            }
                                          });
                                        },
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp("^-?\\d*\$",
                                                  multiLine: true))
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Time to Modify'),
                                    DropdownButton(
                                      items: IntervalTime.values
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e.displayName),
                                              ))
                                          .toList(),
                                      value: timeToModify,
                                      onChanged: (IntervalTime? selected) {
                                        setState(() {
                                          timeToModify =
                                              selected ?? IntervalTime.t0000;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: ExpansionPanelList(
                      expansionCallback: (panelIndex, isExpanded) =>
                          setState(() {
                        data[panelIndex].isExpanded = isExpanded;
                      }),
                      // TODO: UI for consumption mod (toggle should modify, kwh delta, time select)
                      children: data
                          .map(
                            (plan) => ExpansionPanel(
                              isExpanded: plan.isExpanded,
                              backgroundColor: Colors.grey[850],
                              headerBuilder: (context, isExpanded) => ListTile(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(plan.data.toString()),
                                    Text(
                                        '\$${plan.totalCost.toStringAsFixed(2)}'),
                                  ],
                                ),
                              ),
                              canTapOnHeader: true,
                              body: Column(
                                children: [
                                  ...plan.bills.map((e) => Text(e)),
                                  Text(
                                      'Total cost no solar: \$${plan.totalCostNoSolar.toStringAsFixed(2)}'),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        color: Colors.grey,
                                        onPressed: () async {
                                          var updatedPlan =
                                              await Navigator.of(context)
                                                  .pushNamed(
                                            EnergyPlanEditScreen.routeName,
                                            arguments: plan.data,
                                          ) as EnergyPlan?;
                                          if (updatedPlan != null) {
                                            updatedPlan.save();
                                            setData();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy),
                                        color: Colors.grey,
                                        onPressed: () async {
                                          var planClone =
                                              await Navigator.of(context)
                                                  .pushNamed(
                                            EnergyPlanEditScreen.routeName,
                                            arguments:
                                                EnergyPlan.clone(plan.data),
                                          ) as EnergyPlan?;
                                          if (planClone != null) {
                                            addPlan(planClone);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        onPressed: () async {
                                          await plan.data.delete();
                                          rawPlansData.remove(plan.data);
                                          setData();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            )
          : const Text('Loading...'),
    );
  }
}

class EnergyPlanCostEstimateScreen extends StatelessWidget {
  static const String routeName = '/energy-plan-cost-estimate-screen';

  const EnergyPlanCostEstimateScreen({super.key});

  @override
  Widget build(context) {
    final List<BillingCheckboxListDataWrapper> selectedBills =
        ModalRoute.of(context)!.settings.arguments
            as List<BillingCheckboxListDataWrapper>;
    return EnergyPlanCostEstimateList(selectedBills: selectedBills);
  }
}
