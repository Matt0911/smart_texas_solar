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
    Provider.autoDispose<EnphaseApiService>((ref) {
  var tokenService = ref.watch(enphaseTokenServiceProvider);
  var enphaseDataStore = ref.watch(enphaseDataStoreProvider.future);
  return EnphaseApiService(tokenService, enphaseDataStore);
});

class EnphaseApiService {
  final EnphaseTokenService _tokenService;
  final Future<EnphaseDataStore> _futureDataStore;
  EnphaseApiService._create(this._tokenService, this._futureDataStore);

  EnphaseApiService(this._tokenService, this._futureDataStore);

  static Future<EnphaseApiService> create(EnphaseTokenService tokenController,
      Future<EnphaseDataStore> dataStore) async {
    final component = EnphaseApiService._create(tokenController, dataStore);
    // await component.fetchInterval();
    return component;
  }

  // TODO: "queueing" system to help avoid the 10 requests per min limit

  Future<EnphaseSystem> _fetchSystemInfo(BuildContext context) async {
    var dataStore = await _futureDataStore;
    EnphaseSystem? systemInfo = dataStore.getSystemInfo();
    if (systemInfo != null) {
      return systemInfo;
    }

    var url = Uri.https('api.enphaseenergy.com', '/api/v4/systems',
        (await _tokenService.apiKeyQuery));
    String token = await _tokenService.getAccessToken(context);
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;

      // support multiple system setups
      systemInfo = EnphaseSystem.fromData(jsonResponse['systems'][0]);
      dataStore.storeSystemInfo(systemInfo);
      return systemInfo;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get enphase systems');
    }
  }

  Future<String> _fetchSystemId(BuildContext context) async {
    var systemInfo = await _fetchSystemInfo(context);
    return systemInfo.systemId;
  }

  Future<Map<DateTime, EnphaseIntervals>> fetchIntervals({
    required BuildContext context,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    String systemId = await _fetchSystemId(context);

    var dates = getDateListFromRange(startDate, endDate ?? startDate);

    var dataStore = await _futureDataStore;
    var intervalsData = dataStore.getStoredIntervals(dates);
    if (intervalsData != null) {
      return intervalsData;
    }

    String token = await _tokenService.getAccessToken(context);
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

      var fetchedIntervals = EnphaseIntervals.fromData(jsonResponse);
      var intervalsMap = fetchedIntervals.splitIntoDays();
      dataStore.storeManyIntervals(intervalsMap);
      return intervalsMap;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get token');
    }
  }
}
