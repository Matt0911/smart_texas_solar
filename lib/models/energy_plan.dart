import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:smart_texas_solar/models/energy_plan_custom_var.dart';
import 'package:smart_texas_solar/models/interval_map.dart';
part 'energy_plan.g.dart';

final DateFormat _formatter = DateFormat('MM/dd/yyyy');
checkValidTimeRange(List<num> args) {
  String startTime = 't${args[0].toInt().toString().padLeft(4, '0')}';
  String endTime = 't${args[1].toInt().toString().padLeft(4, '0')}';
  try {
    IntervalTime.values.firstWhere((element) => element.name == startTime);
  } catch (e) {
    throw StateError('Invalid time range start');
  }
  try {
    IntervalTime.values.firstWhere((element) => element.name == endTime);
  } catch (e) {
    throw StateError('Invalid time range end');
  }
  return 0;
}

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
  static const String standardEquation =
      'cf + (d + k) * c - if_lt(s, c, s, c) * sbr + b';

  // string, custom calculation
  @HiveField(9)
  String customEquation;

  @HiveField(10)
  bool usesCustomEq;

  // TODO: move eqs to an object with descriptions that can be used in UI
  static Parser getParser() => Parser()
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
    );

  EnergyPlan({
    this.startDate,
    this.endDate,
    this.connectionFee = 0,
    this.deliveryCharge = 0,
    this.kwhCharge = 0,
    this.baseCharge = 0,
    this.solarBuybackRate = 0,
    this.customEquation = '',
    this.usesCustomEq = false,
    this.name = '',
    List<EnergyPlanCustomVar>? customVars,
  }) : customVars = customVars ?? [];

  EnergyPlan.clone(EnergyPlan other)
      : startDate = other.startDate?.copyWith(),
        endDate = other.endDate?.copyWith(),
        connectionFee = other.connectionFee,
        deliveryCharge = other.deliveryCharge,
        kwhCharge = other.kwhCharge,
        baseCharge = other.baseCharge,
        solarBuybackRate = other.solarBuybackRate,
        customEquation = other.customEquation,
        usesCustomEq = other.usesCustomEq,
        name = '${other.name} copy',
        customVars = other.customVars;

  num? calculateBill({
    required num consumptionGrid,
    required num solarSurplus,
    required IntervalMap consumptionByTime,
  }) {
    try {
      Parser p = getParser()
        ..addFunction('c_between', (List<num> args) {
          String startTime = 't${args[0].toInt().toString().padLeft(4, '0')}';
          String endTime = 't${args[1].toInt().toString().padLeft(4, '0')}';
          int startIndex = IntervalTime.values
              .indexWhere((element) => element.name == startTime);
          int endIndex = IntervalTime.values
              .indexWhere((element) => element.name == endTime);
          var desiredIntervalTimes =
              IntervalTime.values.sublist(startIndex, endIndex);
          return desiredIntervalTimes.fold<num>(
              0,
              (prev, time) =>
                  prev += consumptionByTime.intervals[time]?.kwh ?? 0);
        })
        ..addFunction('c_not_between', (List<num> args) {
          String startTime = 't${args[0].toInt().toString().padLeft(4, '0')}';
          String endTime = 't${args[1].toInt().toString().padLeft(4, '0')}';
          int startIndex = IntervalTime.values
              .indexWhere((element) => element.name == startTime);
          int endIndex = IntervalTime.values
              .indexWhere((element) => element.name == endTime);
          var desiredIntervalTimes = [
            ...IntervalTime.values.sublist(0, startIndex),
            ...IntervalTime.values.sublist(endIndex),
          ];
          return desiredIntervalTimes.fold<num>(
              0,
              (prev, time) =>
                  prev += consumptionByTime.intervals[time]?.kwh ?? 0);
        });
      Expression exp =
          p.parse(usesCustomEq ? customEquation : standardEquation);
      ContextModel cm = ContextModel()
        ..bindVariable(Variable('cf'), Number(connectionFee))
        ..bindVariable(Variable('d'), Number(deliveryCharge))
        ..bindVariable(Variable('k'), Number(kwhCharge))
        ..bindVariable(Variable('s'), Number(solarSurplus.round()))
        ..bindVariable(Variable('sbr'), Number(solarBuybackRate))
        ..bindVariable(Variable('c'), Number(consumptionGrid.round()))
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

  // this is used for daily or hourly estimates and sets monthly fees to 0
  num? calculateBillPartial({
    required num consumptionGrid,
    required num solarSurplus,
    required IntervalMap consumptionByTime,
    num partialFraction = 0,
  }) {
    try {
      Parser p = getParser()
        ..addFunction('c_between', (List<num> args) {
          String startTime = 't${args[0].toInt().toString().padLeft(4, '0')}';
          String endTime = 't${args[1].toInt().toString().padLeft(4, '0')}';
          int startIndex = IntervalTime.values
              .indexWhere((element) => element.name == startTime);
          int endIndex = IntervalTime.values
              .indexWhere((element) => element.name == endTime);
          var desiredIntervalTimes =
              IntervalTime.values.sublist(startIndex, endIndex);
          return desiredIntervalTimes.fold<num>(
              0,
              (prev, time) =>
                  prev += consumptionByTime.intervals[time]?.kwh ?? 0);
        })
        ..addFunction('c_not_between', (List<num> args) {
          String startTime = 't${args[0].toInt().toString().padLeft(4, '0')}';
          String endTime = 't${args[1].toInt().toString().padLeft(4, '0')}';
          int startIndex = IntervalTime.values
              .indexWhere((element) => element.name == startTime);
          int endIndex = IntervalTime.values
              .indexWhere((element) => element.name == endTime);
          var desiredIntervalTimes = [
            ...IntervalTime.values.sublist(0, startIndex),
            ...IntervalTime.values.sublist(endIndex),
          ];
          return desiredIntervalTimes.fold<num>(
              0,
              (prev, time) =>
                  prev += consumptionByTime.intervals[time]?.kwh ?? 0);
        });
      Expression exp =
          p.parse(usesCustomEq ? customEquation : standardEquation);
      ContextModel cm = ContextModel()
        ..bindVariable(Variable('cf'), Number(connectionFee * partialFraction))
        ..bindVariable(Variable('d'), Number(deliveryCharge))
        ..bindVariable(Variable('k'), Number(kwhCharge))
        ..bindVariable(Variable('s'), Number(solarSurplus))
        ..bindVariable(Variable('sbr'), Number(solarBuybackRate))
        ..bindVariable(Variable('c'), Number(consumptionGrid))
        ..bindVariable(Variable('b'), Number(baseCharge * partialFraction));
      for (var customVar in customVars) {
        cm.bindVariable(Variable(customVar.symbol),
            Number(customVar.includeInPartial ? customVar.value : 0));
      }
      num result = exp.evaluate(EvaluationType.REAL, cm);
      return result;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static void validateCustomEq(
    String customEq,
    List<EnergyPlanCustomVar> customVars,
  ) {
    Parser p = getParser()
      ..addFunction('c_between', checkValidTimeRange)
      ..addFunction('c_not_between', checkValidTimeRange);
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
    // if (startDate == null && endDate == null) {
    return name;
    // }
    // if (startDate != null && endDate != null) {
    //   return '$name ${_formatter.format(startDate!)} - ${_formatter.format(endDate!)}';
    // }
    // if (startDate != null) {
    //   return '$name starting ${_formatter.format(startDate!)}';
    // }
    // return '$name ending ${_formatter.format(endDate!)}';
  }

  Map<String, dynamic> exportJson() {
    return {
      'startDate': startDate?.toUtc().toIso8601String(),
      'endDate': endDate?.toUtc().toIso8601String(),
      'connectionFee': connectionFee,
      'deliveryCharge': deliveryCharge,
      'kwhCharge': kwhCharge,
      'baseCharge': baseCharge,
      'solarBuybackRate': solarBuybackRate,
      'customVars': customVars.map((e) => e.exportJson()).toList(),
      'name': name,
      'customEquation': customEquation,
      'usesCustomEq': usesCustomEq,
    };
  }

  EnergyPlan.import(Map data)
      : startDate = data['startDate'] == null
            ? null
            : DateTime.parse(data['startDate']).toLocal(),
        endDate = data['endDate'] == null
            ? null
            : DateTime.parse(data['endDate']).toLocal(),
        connectionFee = data['connectionFee'],
        deliveryCharge = data['deliveryCharge'],
        kwhCharge = data['kwhCharge'],
        baseCharge = data['baseCharge'],
        solarBuybackRate = data['solarBuybackRate'],
        customVars = data['customVars']
            .map<EnergyPlanCustomVar>(
                (element) => EnergyPlanCustomVar.import(element))
            .toList(),
        name = data['name'],
        customEquation = data['customEquation'],
        usesCustomEq = data['usesCustomEq'];
}
