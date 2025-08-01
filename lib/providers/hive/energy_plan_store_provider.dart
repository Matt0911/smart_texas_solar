import 'dart:convert';

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

  Future<void> _init() async {
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
    await _box.put(plan.name, plan);
    return getStoredEnergyPlans()!;
  }

  Map<String, dynamic> exportData() {
    Map<String, dynamic> data = {
      'energyPlans': {
        'plans': _box
            .toMap()
            .map((key, value) => MapEntry(key.toString(), value.exportJson())),
      }
    };
    print(json.encode(data));
    return data;
  }

  bool importData(Map<String, dynamic> data) {
    try {
      data['energyPlans']['plans'].forEach((key, value) {
        var plan = EnergyPlan.import(value);
        _box.put(plan.name, plan);
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
