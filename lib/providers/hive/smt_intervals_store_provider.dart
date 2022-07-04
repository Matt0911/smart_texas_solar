import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';

import '../../models/smt_intervals.dart';

final smtIntervalsStoreProvider =
    FutureProvider<SMTIntervalsStore>((_) => SMTIntervalsStore.create());

const String boxName = 'smtIntervals';

class SMTIntervalsStore {
  late Box _box;

  SMTIntervalsStore._create();

  static Future<SMTIntervalsStore> create() async {
    final component = SMTIntervalsStore._create();
    await component._init();
    return component;
  }

  _init() async {
    _box = await Hive.openBox<SMTIntervals>(boxName);
  }

  String _getKey(DateTime day) => '${day.year}-${day.month}-${day.day}';

  storeIntervals(SMTIntervals data, DateTime day) {
    _box.put(_getKey(day), data);
  }

  SMTIntervals? getIntervals(DateTime day) {
    return _box.get(_getKey(day));
  }
}
