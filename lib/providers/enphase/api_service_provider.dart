import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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

  Future<String> _fetchSystemId(BuildContext context) async {
    var dataStore = await _futureDataStore;
    String? systemId = dataStore.getSystemId();
    if (systemId != null) {
      return systemId;
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

      String systemId = jsonResponse['systems'][0]['system_id'].toString();
      dataStore.storeSystemId(systemId);
      return systemId;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get enphase systems');
    }
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
