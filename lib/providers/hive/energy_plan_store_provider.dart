import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:smart_texas_solar/models/energy_plan.dart';
import 'package:collection/collection.dart';

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
    _box = await Hive.openBox<EnergyPlan>('energyPlans');
    // _box.flush();
    // _box.clear();
    // _box.deleteFromDisk();
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

  EnergyPlan? getEnergyPlanForDate(DateTime date) {
    List<EnergyPlan>? plans = getStoredEnergyPlans();
    if (plans == null) {
      return null;
    }
    return plans.firstWhereOrNull((plan) {
      if (plan.startDate != null) {
        bool isAfterPlanStart = plan.startDate!.isBefore(date);
        if (plan.endDate == null) {
          return isAfterPlanStart;
        } else {
          return isAfterPlanStart && plan.endDate!.isAfter(date);
        }
      }
      return false;
    });
  }

  Future<List<EnergyPlan>> addEnergyPlan(EnergyPlan plan) async {
    await _box.add(plan);
    return getStoredEnergyPlans()!;
  }
}
