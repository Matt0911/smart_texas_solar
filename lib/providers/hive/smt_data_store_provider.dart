import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';

import '../../models/smt_intervals.dart';

final smtDataStoreProvider =
    FutureProvider<SMTDataStore>((_) => SMTDataStore.create());

const String boxName = 'smtIntervals';

class SMTDataStore {
  // late Box<String> _coreBox; TODO: storing esiid or stuff
  late Box<SMTIntervals> _intervalsBox;

  SMTDataStore._create();

  static Future<SMTDataStore> create() async {
    final component = SMTDataStore._create();
    await component._init();
    return component;
  }

  _init() async {
    _intervalsBox = await Hive.openBox<SMTIntervals>(boxName);
    // resetIntervalsStore();
  }

  String _getKey(DateTime day) => '${day.year}-${day.month}-${day.day}';

  storeIntervals(SMTIntervals data, DateTime day) {
    _intervalsBox.put(_getKey(day), data);
  }

  storeManyIntervals(Map<DateTime, SMTIntervals> data) {
    data.forEach((date, intervals) {
      storeIntervals(intervals, date);
    });
  }

  SMTIntervals? getIntervals(DateTime day) {
    return _intervalsBox.get(_getKey(day));
  }

  Map<DateTime, SMTIntervals>? getStoredIntervals(List<DateTime> dates) {
    Map<DateTime, SMTIntervals> stored = {};
    for (var d in dates) {
      var data = _intervalsBox.get(_getKey(d));
      if (data == null) return null;
      stored[d] = data;
    }
    return stored;
  }

  resetIntervalsStore() {
    _intervalsBox.deleteAll(_intervalsBox.keys);
  }
}
