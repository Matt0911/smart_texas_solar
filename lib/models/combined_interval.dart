class CombinedInterval {
  DateTime endTime;
  num kwhGridConsumption;
  num kwhSurplusGeneration;
  num kwhSolarProduction;

  CombinedInterval({
    required this.endTime,
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
