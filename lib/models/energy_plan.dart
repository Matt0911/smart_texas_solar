import 'package:hive_flutter/adapters.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:smart_texas_solar/models/energy_plan_custom_var.dart';
import 'package:smart_texas_solar/models/interval_map.dart';

part 'energy_plan.g.dart';

@HiveType(typeId: 8)
class EnergyPlan extends HiveObject {
  @HiveField(0)
  DateTime? startDate;
  @HiveField(1)
  DateTime? endDate;

  // fields for standard billing variables
  @HiveField(2)
  num connectionFee;
  @HiveField(3)
  num deliveryCharge;
  @HiveField(4)
  num kwhCharge;
  @HiveField(5)
  num baseCharge;
  @HiveField(6)
  num solarBuybackRate;

  // [ list of custom variables
  //    {varName: x, value: y }
  // ]
  @HiveField(7)
  List<EnergyPlanCustomVar> customVars;

  @HiveField(8)
  String name;

  // string, standard calculation
  static const String standardEquation = 'cf + (d + k) * c - s * sbr + b';

  // string, custom calculation
  @HiveField(9)
  String customEquation;

  static Parser p = Parser()
    ..addFunction(
      'if_gt',
      (List<num> args) => args[0] > args[1] ? args[2] : args[3],
    )
    ..addFunction(
      'if_gte',
      (List<num> args) => args[0] >= args[1] ? args[2] : args[3],
    )
    ..addFunction(
      'if_lt',
      (List<num> args) => args[0] < args[1] ? args[2] : args[3],
    )
    ..addFunction(
      'if_lte',
      (List<num> args) => args[0] <= args[1] ? args[2] : args[3],
    )
    ..addFunction('c_between', (List<String> args) => 0);
  // TODO: figure out how to handle time ranges of consumption
  // field for hive ID?? need to research

  EnergyPlan({
    this.startDate,
    this.endDate,
    this.connectionFee = 0,
    this.deliveryCharge = 0,
    this.kwhCharge = 0,
    this.baseCharge = 0,
    this.solarBuybackRate = 0,
    this.customEquation = '',
    this.name = '',
    List<EnergyPlanCustomVar>? customVars,
  }) : customVars = customVars ?? [];

  num? calculateBill({
    required num consumptionGrid,
    required num solarSurplus,
    required IntervalMap consumptionByTime,
  }) {
    try {
      p.addFunction('c_between', (List<String> args) {});
      Expression exp =
          p.parse(customEquation.isEmpty ? standardEquation : customEquation);
      ContextModel cm = ContextModel()
        ..bindVariable(Variable('cf'), Number(connectionFee))
        ..bindVariable(Variable('d'), Number(deliveryCharge))
        ..bindVariable(Variable('k'), Number(kwhCharge))
        ..bindVariable(Variable('s'), Number(solarSurplus))
        ..bindVariable(Variable('sbr'), Number(solarBuybackRate))
        ..bindVariable(Variable('c'), Number(consumptionGrid))
        ..bindVariable(Variable('b'), Number(baseCharge));
      for (var customVar in customVars) {
        cm.bindVariable(Variable(customVar.symbol), Number(customVar.value));
      }
      num result = exp.evaluate(EvaluationType.REAL, cm);
      return result;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static void validateCustomEq(
      String customEq, List<EnergyPlanCustomVar> customVars) {
    Expression exp = p.parse(customEq);
    ContextModel cm = ContextModel()
      ..bindVariable(Variable('cf'), Number(0))
      ..bindVariable(Variable('d'), Number(0))
      ..bindVariable(Variable('k'), Number(0))
      ..bindVariable(Variable('s'), Number(0))
      ..bindVariable(Variable('sbr'), Number(0))
      ..bindVariable(Variable('c'), Number(0))
      ..bindVariable(Variable('b'), Number(0));
    for (var customVar in customVars) {
      cm.bindVariable(Variable(customVar.symbol), Number(customVar.value));
    }
    exp.evaluate(EvaluationType.REAL, cm);
  }

  @override
  String toString() {
    return 'billing plan';
  }
}
