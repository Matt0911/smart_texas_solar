import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/models/energy_plan.dart';
import 'package:smart_texas_solar/providers/hive/energy_plan_store_provider.dart';
import 'package:smart_texas_solar/screens/energy_plan_create_screen.dart';
import 'package:smart_texas_solar/widgets/sts_drawer.dart';

import '../providers/past_intervals_data_fetcher_provider.dart';

const kTableHeaderStyle =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 2);

class EnergyPlanWrapper {
  bool isExpanded = false;
  EnergyPlan data;

  EnergyPlanWrapper(this.data);
}

class EnergyPlansScreen extends ConsumerStatefulWidget {
  static const String routeName = '/energy-plans-screen';

  const EnergyPlansScreen({super.key});

  @override
  EnergyPlansScreenState createState() => EnergyPlansScreenState();
}

class EnergyPlansScreenState extends ConsumerState<EnergyPlansScreen> {
  bool arePlansLoaded = false;
  bool isHistoryLoaded = false;
  List<EnergyPlan> rawPlansData = [];
  List<EnergyPlanWrapper> data = [];

  void setData() async {
    List<EnergyPlanWrapper> wrappedData =
        rawPlansData.map((e) => EnergyPlanWrapper(e)).toList();

    // for (var plan in rawPlansData.reversed) {
    //   wrappedData.add(
    //     EnergyPlanWrapper(plan),
    //   );
    // }
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
        title: const Text('Energy Plans'),
      ),
      drawer: const STSDrawer(),
      body: arePlansLoaded && isHistoryLoaded
          ? Column(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    var newPlan = await Navigator.of(context)
                            .pushNamed(EnergyPlanCreateScreen.routeName)
                        as EnergyPlan?;
                    if (newPlan != null) {
                      addPlan(newPlan);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Plan'),
                ),
                SingleChildScrollView(
                  child: ExpansionPanelList(
                    expansionCallback: (panelIndex, isExpanded) => setState(() {
                      data[panelIndex].isExpanded = !isExpanded;
                    }),
                    children: data
                        .map(
                          (plan) => ExpansionPanel(
                            isExpanded: plan.isExpanded,
                            backgroundColor: Colors.grey[850],
                            headerBuilder: (context, isExpanded) => ListTile(
                              title: Text(plan.data.name),
                            ),
                            body: Column(
                              children: [
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
                                          EnergyPlanCreateScreen.routeName,
                                          arguments: plan.data,
                                        ) as EnergyPlan?;
                                        if (updatedPlan != null) {
                                          updatedPlan.save();
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
              ],
            )
          : const Text('Loading...'),
    );
  }
}
