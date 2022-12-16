import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../models/smt_intervals.dart';

final smtDataStoreProvider =
    FutureProvider<SMTDataStore>((_) => SMTDataStore.create());

const String coreBoxName = 'smtCore';
const String intervalsBoxName = 'smtIntervals';

const String accessTokenKey = 'accessToken';
const String cookiesKey = 'cookies';

class SMTDataStore {
  late Box<String> _coreBox; // TODO: storing esiid or stuff
  late Box<SMTIntervals> _intervalsBox;

  SMTDataStore._create();

  static Future<SMTDataStore> create() async {
    final component = SMTDataStore._create();
    await component._init();
    return component;
  }

  _init() async {
    _coreBox = await Hive.openBox<String>(coreBoxName);
    _intervalsBox = await Hive.openBox<SMTIntervals>(intervalsBoxName);
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
    _intervalsBox.clear();
  }

  String? getAccessToken() {
    String? storedToken = _coreBox.get(accessTokenKey);
    if (storedToken == null || JwtDecoder.isExpired(storedToken)) return null;
    return storedToken;
  }

  setAccessToken(String token) {
    _coreBox.put(accessTokenKey, token);
  }

  String? getCookies() {
    return _coreBox.get(cookiesKey);
  }

  setCookies(String cookies) {
    _coreBox.put(cookiesKey, cookies);
  }

  removeCookies() {
    _coreBox.delete(cookiesKey);
  }
}
