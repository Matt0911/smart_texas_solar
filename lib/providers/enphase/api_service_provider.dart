import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_texas_solar/models/enphase_system.dart';
import 'package:smart_texas_solar/providers/enphase/token_service_provider.dart';
import 'dart:convert' as convert;

import 'package:smart_texas_solar/providers/hive/enphase_data_store_provider.dart';
import 'package:smart_texas_solar/util/date_util.dart';

import '../../models/enphase_intervals.dart';

final enphaseApiServiceProvider =
    FutureProvider.autoDispose<EnphaseApiService>((ref) async {
  var tokenService = await ref.watch(enphaseTokenServiceProvider.future);
  var enphaseDataStore = await ref.watch(enphaseDataStoreProvider.future);
  return EnphaseApiService.create(tokenService, enphaseDataStore);
});

class EnphaseApiService {
  final EnphaseTokenService _tokenService;
  final EnphaseDataStore _dataStore;
  EnphaseApiService._create(this._tokenService, this._dataStore);

  EnphaseApiService(this._tokenService, this._dataStore);

  static Future<EnphaseApiService> create(
      EnphaseTokenService tokenController, EnphaseDataStore dataStore) async {
    final component = EnphaseApiService._create(tokenController, dataStore);
    // await component.fetchInterval();
    return component;
  }

  Future<EnphaseSystem> _fetchSystemInfo() async {
    EnphaseSystem? systemInfo = _dataStore.getSystemInfo();
    if (systemInfo != null) {
      return systemInfo;
    }

    var url = Uri.https('api.enphaseenergy.com', '/api/v4/systems',
        (await _tokenService.apiKeyQuery));
    String token = await _tokenService.getAccessToken();
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;

      // support multiple system setups
      systemInfo = EnphaseSystem.fromData(jsonResponse['systems'][0]);
      _dataStore.storeSystemInfo(systemInfo);
      return systemInfo;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get enphase system info');
    }
  }

  Future<String> _fetchSystemId() async {
    var systemInfo = await _fetchSystemInfo();
    return systemInfo.systemId;
  }

  Future<DateTime> getSystemStartDate() async {
    return (await _fetchSystemInfo()).operationalAtTime;
  }

  Map<DateTime, EnphaseIntervals>? getIntervalsSavedForDates(
      DateTime startDate, DateTime? endDate) {
    var dates = getDateListFromRange(startDate, endDate ?? startDate);
    return _dataStore.getStoredIntervals(dates);
  }

  Future<Map<DateTime, EnphaseIntervals>> fetchIntervals({
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    String systemId = await _fetchSystemId();

    var intervalsData = getIntervalsSavedForDates(startDate, endDate);
    if (intervalsData != null) {
      return intervalsData;
    }

    String token = await _tokenService.getAccessToken();
    DateTime startDateStartOfDay =
        DateTime(startDate.year, startDate.month, startDate.day);
    DateTime realEndDate = endDate ?? startDate.add(const Duration(days: 1));
    var url = Uri.https(
        'api.enphaseenergy.com', '/api/v4/systems/$systemId/rgm_stats', {
      ...(await _tokenService.apiKeyQuery),
      'start_at':
          (startDateStartOfDay.millisecondsSinceEpoch ~/ 1000).toString(),
      'end_at': (realEndDate.millisecondsSinceEpoch ~/ 1000 + 1).toString(),
    });
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      var intervalsMap = EnphaseIntervals.splitIntoDays(jsonResponse);
      _dataStore.storeManyIntervals(intervalsMap);
      return intervalsMap;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get enphase intervals');
    }
  }
}
