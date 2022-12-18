import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/util/date_util.dart';

final selectedDatesProvider = ChangeNotifierProvider((ref) {
  return SelectedDates();
});

class SelectedDates extends ChangeNotifier {
  SelectedDates({DateTime? startDate, DateTime? endDate})
      : startDate = startDate ?? getDateFromToday(-2, false),
        endDate = endDate ?? getDateFromToday(-2, true);

  DateTime startDate;
  DateTime endDate;

  void updateDates({DateTime? start, DateTime? end}) {
    if (start != null) {
      startDate = start;
    }
    if (end != null) {
      endDate = getEndOfDay(end);
    }
    notifyListeners();
  }
}
