import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_texas_solar/models/enphase_system.dart';
import 'package:smart_texas_solar/providers/enphase/token_service_provider.dart';
import 'dart:convert' as convert;

import 'package:smart_texas_solar/providers/hive/enphase_data_store_provider.dart';
import 'package:smart_texas_solar/util/date_util.dart';
import 'package:smart_texas_solar/util/navigator_key.dart';
import 'package:smart_texas_solar/widgets/enable_enphase_dialog.dart';

import '../../models/enphase_intervals.dart';

Future<bool?> _promptEnableEnphase() async => await showDialog<bool>(
      context: navigatorKey.currentContext!,
      builder: (context) => EnableEnphaseDialog(),
    );

final enphaseApiServiceProvider =
    FutureProvider.autoDispose<EnphaseApiService?>((ref) async {
  var tokenService = await ref.watch(enphaseTokenServiceProvider.future);
  var enphaseDataStore = await ref.watch(enphaseDataStoreProvider.future);
  if (enphaseDataStore.isEnabled() == null) {
    final shouldEnable = await _promptEnableEnphase();
    if (shouldEnable == true) {
      enphaseDataStore.setEnabled(true);
      return EnphaseApiService.create(tokenService, enphaseDataStore);
    } else {
      if (shouldEnable == false) {
        enphaseDataStore.setEnabled(false);
      }
      return null;
    }
  }
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

    DateTime systemStartDate = await getSystemStartDate();
    DateTime fetchStart = startDate;
    Map<DateTime, EnphaseIntervals> emptyDays = {};
    if (startDate.isBefore(systemStartDate)) {
      var end = endDate ?? startDate;
      if (end.isBefore(systemStartDate)) {
        var intervalsData = EnphaseIntervals.getEmptyDays(startDate, end);
        _dataStore.storeManyIntervals(intervalsData);
        return intervalsData;
      }

      fetchStart = systemStartDate;
      emptyDays = EnphaseIntervals.getEmptyDays(startDate, systemStartDate);
    }

    String token = await _tokenService.getAccessToken();
    DateTime startDateStartOfDay =
        DateTime(fetchStart.year, fetchStart.month, fetchStart.day);
    DateTime realEndDate = endDate ?? fetchStart.add(const Duration(days: 1));
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
      var intervalsMap = {
        ...emptyDays,
        ...EnphaseIntervals.splitIntoDays(jsonResponse)
      };
      _dataStore.storeManyIntervals(intervalsMap);
      return intervalsMap;
    } else {
      print(
          'Request failed with status: ${response.statusCode}, ${response.body}');
      return Future.error('Failed to get enphase intervals');
    }
  }
}
