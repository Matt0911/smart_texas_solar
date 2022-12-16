import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:smart_texas_solar/models/enphase_system.dart';

import '../../models/enphase_intervals.dart';

final enphaseDataStoreProvider =
    FutureProvider<EnphaseDataStore>((_) => EnphaseDataStore.create());

const String coreBoxName = 'enphaseData';
const String intervalsBoxName = 'enphaseIntervals';
const String systemIdKey = 'sysid';
const String systemInfoKey = 'sysinfo';

class EnphaseDataStore {
  late Box _coreBox;
  late Box<EnphaseIntervals> _intervalsBox;

  EnphaseDataStore._create();

  static Future<EnphaseDataStore> create() async {
    final component = EnphaseDataStore._create();
    await component._init();
    return component;
  }

  _init() async {
    _coreBox = await Hive.openBox(coreBoxName);
    _intervalsBox = await Hive.openBox<EnphaseIntervals>(intervalsBoxName);
    // resetIntervalsStore();
  }

  String _getIntervalKey(DateTime day) => '${day.year}-${day.month}-${day.day}';

  storeIntervals(EnphaseIntervals data, DateTime day) {
    _intervalsBox.put(_getIntervalKey(day), data);
  }

  storeManyIntervals(Map<DateTime, EnphaseIntervals> data) {
    data.forEach((date, intervals) {
      storeIntervals(intervals, date);
    });
  }

  EnphaseIntervals? getIntervals(DateTime day) {
    return _intervalsBox.get(_getIntervalKey(day));
  }

  Map<DateTime, EnphaseIntervals>? getStoredIntervals(List<DateTime> dates) {
    Map<DateTime, EnphaseIntervals> stored = {};
    for (var d in dates) {
      var data = _intervalsBox.get(_getIntervalKey(d));
      if (data == null) return null;
      stored[d] = data;
    }
    return stored;
  }

  resetIntervalsStore() {
    _intervalsBox.clear();
  }

  EnphaseSystem? getSystemInfo() => _coreBox.get(systemInfoKey);
  storeSystemInfo(EnphaseSystem systemInfo) {
    _coreBox.put(systemInfoKey, systemInfo);
  }
}
