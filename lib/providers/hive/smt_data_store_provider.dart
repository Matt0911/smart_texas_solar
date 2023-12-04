import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:smart_texas_solar/models/billing_data.dart';

import '../../models/smt_intervals.dart';

final smtDataStoreProvider =
    FutureProvider<SMTDataStore>((_) => SMTDataStore.create());

const String coreBoxName = 'smtCore';
const String intervalsBoxName = 'smtIntervals';
const String billingBoxName = 'smtBilling';

const String accessTokenKey = 'accessToken';
const String cookiesKey = 'cookies';

class SMTDataStore {
  late Box<String> _coreBox; // TODO: storing esiid or stuff
  late Box<SMTIntervals> _intervalsBox;
  late Box<BillingData> _billingDataBox;

  SMTDataStore._create();

  static Future<SMTDataStore> create() async {
    final component = SMTDataStore._create();
    await component._init();
    return component;
  }

  _init() async {
    _coreBox = await Hive.openBox<String>(coreBoxName);
    _intervalsBox = await Hive.openBox<SMTIntervals>(intervalsBoxName);
    _billingDataBox = await Hive.openBox<BillingData>(billingBoxName);
    // _billingDataBox.clear();
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

  List<BillingData>? getStoredBillingData() {
    return _billingDataBox.values.toList()
      ..sort(((a, b) => a.startDate.compareTo(b.startDate)));
  }

  Future<List<BillingData>> addBillingData(
      List<BillingData> newBillingData) async {
    var existingDataKeys = [..._billingDataBox.keys];
    if (existingDataKeys.isEmpty) {
      await _billingDataBox.addAll(newBillingData);
      return getStoredBillingData()!;
    }
    for (var bill in newBillingData) {
      var index = existingDataKeys.indexWhere((existingBillIndex) {
        var existingBill =
            _billingDataBox.get(existingDataKeys[existingBillIndex]);
        return existingBill != null &&
            existingBill.startDate.isAtSameMomentAs(bill.startDate) &&
            existingBill.endDate.isAtSameMomentAs(bill.endDate);
      });
      if (index == -1) {
        await _billingDataBox.add(bill);
      } else {
        var match = _billingDataBox.get(existingDataKeys[index]);
        if (bill.lastUpdate.isAfter(match!.lastUpdate)) {
          await _billingDataBox.put(existingDataKeys[index], bill);
        }
      }
    }

    return getStoredBillingData()!;
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

  Map<String, dynamic> exportData() {
    Map<String, dynamic> data = {
      'smt': {
        'intervals': _intervalsBox
            .toMap()
            .map((key, value) => MapEntry(key, value.exportJson())),
        'billingData': _billingDataBox
            .toMap()
            .map((key, value) => MapEntry(key.toString(), value.exportJson())),
      }
    };
    print(json.encode(data));
    return data;
  }

  bool importData(Map<String, dynamic> data) {
    try {
      Map<String, SMTIntervals> intervals = {};
      data['smt']['intervals'].forEach((key, value) {
        intervals.putIfAbsent(key, () => SMTIntervals.import(value));
      });
      List<BillingData> billingData = [];
      data['smt']['billingData'].forEach((key, value) {
        billingData.add(BillingData.import(value));
      });

      intervals.forEach((key, value) {
        _intervalsBox.put(key, value);
      });
      addBillingData(billingData);
      return true;
    } catch (e) {
      return false;
    }
  }
}
