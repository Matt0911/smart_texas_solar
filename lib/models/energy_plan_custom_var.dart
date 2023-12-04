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
  @HiveField(3)
  bool includeInPartial;

  EnergyPlanCustomVar({
    this.name = '',
    this.value = 0,
    this.symbol = '',
    this.includeInPartial = true,
  });

  Map<String, dynamic> exportJson() {
    return {
      'name': name,
      'value': value,
      'symbol': symbol,
      'includeInPartial': includeInPartial,
    };
  }

  EnergyPlanCustomVar.import(Map data)
      : name = data['name'],
        value = data['value'],
        symbol = data['symbol'],
        includeInPartial = data['includeInPartial'];
}
