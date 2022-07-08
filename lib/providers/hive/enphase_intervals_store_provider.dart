import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';

import '../../models/enphase_intervals.dart';

final enphaseDataStoreProvider =
    FutureProvider<EnphaseDataStore>((_) => EnphaseDataStore.create());

const String coreBoxName = 'enphaseData';
const String intervalsBoxName = 'enphaseIntervals';
const String systemIdKey = 'sysid';

class EnphaseDataStore {
  late Box<String> _coreBox;
  late Box<EnphaseIntervals> _intervalsBox;

  EnphaseDataStore._create();

  static Future<EnphaseDataStore> create() async {
    final component = EnphaseDataStore._create();
    await component._init();
    return component;
  }

  _init() async {
    _coreBox = await Hive.openBox<String>(coreBoxName);
    _intervalsBox = await Hive.openBox<EnphaseIntervals>(intervalsBoxName);
  }

  String _getIntervalKey(DateTime day) => '${day.year}-${day.month}-${day.day}';

  storeIntervals(EnphaseIntervals data, DateTime day) {
    _intervalsBox.put(_getIntervalKey(day), data);
  }

  EnphaseIntervals? getIntervals(DateTime day) {
    return _intervalsBox.get(_getIntervalKey(day));
  }

  String? getSystemId() => _coreBox.get(systemIdKey);
  storeSystemId(String systemId) {
    _coreBox.put(systemIdKey, systemId);
  }
}
