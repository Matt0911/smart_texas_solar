import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedDatesProvider = ChangeNotifierProvider((ref) {
  return SelectedDates();
});

DateTime _getDateFromToday(int deltaDays, bool endOfDay) {
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

class SelectedDates extends ChangeNotifier {
  SelectedDates({DateTime? startDate, DateTime? endDate})
      : startDate = startDate ?? _getDateFromToday(-2, false),
        endDate = endDate ?? _getDateFromToday(-2, true);

  DateTime startDate;
  DateTime endDate;

  void updateDates({DateTime? start, DateTime? end}) {
    if (start != null) {
      startDate = start;
    }
    if (end != null) {
      endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    }
    notifyListeners();
  }
}
