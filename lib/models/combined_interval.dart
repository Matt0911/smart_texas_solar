import 'package:smart_texas_solar/models/interval_map.dart';

class CombinedInterval {
  DateTime endTime;
  DateTime startTime;
  num kwhGridConsumption;
  num kwhSurplusGeneration;
  num kwhSolarProduction;
  num? cost;

  CombinedInterval({
    required this.endTime,
    required this.startTime,
    required this.kwhGridConsumption,
    required this.kwhSurplusGeneration,
    required this.kwhSolarProduction,
    this.cost = 0,
  });

  num get kwhTotalConsumption =>
      (kwhSolarProduction - kwhSurplusGeneration) + kwhGridConsumption;

  @override
  String toString() {
    return '$endTime\ngrid: $kwhGridConsumption\nsolarProd: $kwhSolarProduction\nconsumption: $kwhTotalConsumption\nsurplus: $kwhSurplusGeneration\n';
  }
}
