class CombinedInterval {
  DateTime endTime;
  DateTime startTime;
  num kwhGridConsumption;
  num kwhSurplusGeneration;
  num kwhSolarProduction;

  CombinedInterval({
    required this.endTime,
    required this.startTime,
    required this.kwhGridConsumption,
    required this.kwhSurplusGeneration,
    required this.kwhSolarProduction,
  });

  num get kwhTotalConsumption =>
      (kwhSolarProduction - kwhSurplusGeneration) + kwhGridConsumption;

  @override
  String toString() {
    return '$endTime\ngrid: $kwhGridConsumption\nsolarProd: $kwhSolarProduction\nconsumption: $kwhTotalConsumption\nsurplus: $kwhSurplusGeneration\n';
  }
}
