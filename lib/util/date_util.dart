List<DateTime> getDateListFromRange(DateTime start, DateTime end) {
  // subtract an hour to account for long day on daylight savings time
  final daysToGenerate =
      end.subtract(const Duration(hours: 1)).difference(start).inDays + 1;
  return List.generate(daysToGenerate,
      (i) => DateTime(start.year, start.month, start.day + (i)));
}
