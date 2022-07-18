List<DateTime> getDateListFromRange(DateTime start, DateTime end) {
  final daysToGenerate = end.difference(start).inDays + 1;
  return List.generate(daysToGenerate,
      (i) => DateTime(start.year, start.month, start.day + (i)));
}
