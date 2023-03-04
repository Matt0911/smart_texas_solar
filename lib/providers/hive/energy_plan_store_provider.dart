import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:smart_texas_solar/models/energy_plan.dart';

const String boxName = 'energyPlans';

final energyPlanStoreProvider =
    FutureProvider<EnergyPlanStore>((_) => EnergyPlanStore.create());

class EnergyPlanStore {
  late Box<EnergyPlan> _box;

  EnergyPlanStore._create();

  static Future<EnergyPlanStore> create() async {
    final component = EnergyPlanStore._create();
    await component._init();
    return component;
  }

  _init() async {
    _box = await Hive.openBox<EnergyPlan>(boxName);
    // resetIntervalsStore();
  }

  List<EnergyPlan>? getStoredEnergyPlans() {
    return _box.values.toList()
      ..sort(((a, b) {
        if (a.startDate == null || b.startDate == null) {
          if (a.startDate == null) {
            if (b.startDate == null) {
              return a.name.compareTo(b.name);
            } else {
              return -1;
            }
          } else {
            return 1;
          }
        }

        return a.startDate!.compareTo(b.startDate!);
      }));
  }

  Future<List<EnergyPlan>> addEnergyPlan(EnergyPlan plan) async {
    await _box.add(plan);
    return getStoredEnergyPlans()!;
  }
}
