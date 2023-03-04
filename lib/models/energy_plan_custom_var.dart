import 'package:hive_flutter/adapters.dart';

part 'energy_plan_custom_var.g.dart';

@HiveType(typeId: 9)
class EnergyPlanCustomVar {
  @HiveField(0)
  String name;
  @HiveField(1)
  num value;
  @HiveField(2)
  String symbol;

  EnergyPlanCustomVar({
    this.name = '',
    this.value = 0,
    this.symbol = '',
  });

  @override
  String toString() {
    return 'energy plan';
  }
}
