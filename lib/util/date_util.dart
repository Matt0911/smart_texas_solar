List<DateTime> getDateListFromRange(DateTime start, DateTime end) {
  // subtract an hour to account for long day on daylight savings time
  final daysToGenerate =
      end.subtract(const Duration(hours: 1)).difference(start).inDays + 1;
  return List.generate(daysToGenerate,
      (i) => DateTime(start.year, start.month, start.day + (i)));
}

DateTime getStartOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 0, 0, 0);

DateTime getEndOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59);

DateTime getDateFromToday(int deltaDays, bool endOfDay) {
  var now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day + deltaDays,
    endOfDay ? 23 : 0,
    endOfDay ? 59 : 0,
    endOfDay ? 59 : 0,
  );
}

DateTime getStartOfNextMonth(DateTime date) {
  return DateTime(
    date.year,
    date.month + 1,
    1,
    date.hour,
    date.minute,
    date.second,
  );
}

DateTime getEndOfMonth(DateTime date) {
  return DateTime(
    date.year,
    date.month + 1,
    0,
    date.hour,
    date.minute,
    date.second,
  );
}

int getDaysInMonth(DateTime date) {
  DateTime monthStart = DateTime(date.year, date.month, 0);
  return DateTime(date.year, date.month + 1, 0).difference(monthStart).inDays;
}
