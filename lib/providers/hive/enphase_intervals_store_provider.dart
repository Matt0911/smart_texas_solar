import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';

import '../../models/enphase_intervals.dart';
import '../../models/interval.dart';

final enphaseIntervalsStoreProvider = FutureProvider<EnphaseIntervalsStore>(
    (_) => EnphaseIntervalsStore.create());

const String boxName = 'enphaseIntervals';

class EnphaseIntervalsStore {
  late Box _box;

  EnphaseIntervalsStore._create();

  static Future<EnphaseIntervalsStore> create() async {
    final component = EnphaseIntervalsStore._create();
    await component._init();
    return component;
  }

  _init() async {
    Hive.registerAdapter(EnphaseIntervalsAdapter());
    Hive.registerAdapter(IntervalAdapter());
    _box = await Hive.openBox<EnphaseIntervals>(boxName);
  }

  String _getKey(DateTime day) => '${day.year}-${day.month}-${day.day}';

  storeIntervals(EnphaseIntervals data, DateTime day) {
    _box.put(_getKey(day), data);
  }

  EnphaseIntervals? getIntervals(DateTime day) {
    return _box.get(_getKey(day));
  }
}
