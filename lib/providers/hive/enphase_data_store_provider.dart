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
const String enphaseEnabledKey = 'enphaseDisabled';

class EnphaseDataStore {
  late Box _coreBox;
  late Box<EnphaseIntervals> _intervalsBox;

  EnphaseDataStore._create();

  static Future<EnphaseDataStore> create() async {
    final component = EnphaseDataStore._create();
    await component._init();
    return component;
  }

  Future<void> _init() async {
    _coreBox = await Hive.openBox(coreBoxName);
    _intervalsBox = await Hive.openBox<EnphaseIntervals>(intervalsBoxName);
    // resetIntervalsStore();
  }

  String _getIntervalKey(DateTime day) => '${day.year}-${day.month}-${day.day}';

  void storeIntervals(EnphaseIntervals data, DateTime day) {
    _intervalsBox.put(_getIntervalKey(day), data);
  }

  void storeManyIntervals(Map<DateTime, EnphaseIntervals> data) {
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

  void resetIntervalsStore() {
    _intervalsBox.clear();
  }

  EnphaseSystem? getSystemInfo() => _coreBox.get(systemInfoKey);
  void storeSystemInfo(EnphaseSystem systemInfo) {
    _coreBox.put(systemInfoKey, systemInfo);
  }

  bool? isEnabled() => _coreBox.get(enphaseEnabledKey);
  void setEnabled(bool enabled) => _coreBox.put(enphaseEnabledKey, enabled);

  Map<dynamic, Map<String, dynamic>> exportIntervals() {
    var intervalsMap = _intervalsBox.toMap();
    var result = intervalsMap.map((key, value) {
      return MapEntry(key, value.exportJson());
    });
    return result;
  }

  Map exportCore() {
    var enabled = isEnabled();
    var sysInfo = getSystemInfo();
    if (sysInfo == null) {
      return {};
    }
    return {
      enabled: enabled,
      systemInfoKey: sysInfo.exportJson(),
    };
  }

  Map<String, dynamic> exportData() {
    Map<String, dynamic> data = {
      'enphase': {
        'intervals': exportIntervals(),
        'core': exportCore(),
      }
    };
    return data;
  }

  bool importData(Map<String, dynamic> data) {
    try {
      Map<String, EnphaseIntervals> intervals = {};
      data['enphase']['intervals'].forEach((key, value) {
        intervals.putIfAbsent(key, () => EnphaseIntervals.import(value));
      });
      Map<String, dynamic> coreData = {};
      data['enphase']['core'].forEach((key, value) {
        if (key == systemInfoKey) {
          coreData.putIfAbsent(key, () => EnphaseSystem.import(value));
        }
        coreData.putIfAbsent(key, () => value);
      });

      intervals.forEach((key, value) {
        _intervalsBox.put(key, value);
      });
      coreData.forEach((key, value) {
        _coreBox.put(key, value);
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
