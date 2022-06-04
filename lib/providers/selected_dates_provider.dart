import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedDatesProvider = ChangeNotifierProvider((ref) {
  return SelectedDates();
});

class SelectedDates extends ChangeNotifier {
  SelectedDates({DateTime? startDate, DateTime? endDate})
      : startDate =
            startDate ?? DateTime.now().subtract(const Duration(days: 2)),
        endDate = endDate ?? DateTime.now().subtract(const Duration(days: 2));

  DateTime startDate;
  DateTime endDate;

  void updateDates({DateTime? start, DateTime? end}) {
    if (start != null) {
      startDate = start;
    }
    if (end != null) {
      endDate = end;
    }
    notifyListeners();
  }
}
