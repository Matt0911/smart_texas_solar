import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/providers/enphase/token_service_provider.dart';
import 'dart:convert' as convert;

import 'package:smart_texas_solar/providers/hive/enphase_intervals_store_provider.dart';

import '../../models/enphase_intervals.dart';

final enphaseApiServiceProvider = Provider<EnphaseApiService>((ref) {
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

  final DateFormat _formatter = DateFormat('MM/dd/yyyy');

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

  Future<EnphaseIntervals> fetchIntervals({
    required BuildContext context,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    String systemId = await _fetchSystemId(context);

    // TODO: handle multiple days selected
    var dataStore = await _futureDataStore;
    var intervalsData = dataStore.getIntervals(startDate);
    if (intervalsData != null) {
      return intervalsData;
    }

    String token = await _tokenService.getAccessToken(context);
    DateTime startDateStartOfDay =
        DateTime(startDate.year, startDate.month, startDate.day);
    DateTime realEndDate = endDate ?? DateTime.now();
    DateTime endDateEndOfDay =
        DateTime(realEndDate.year, realEndDate.month, realEndDate.day + 1)
            .subtract(const Duration(seconds: 1));
    var url = Uri.https(
        'api.enphaseenergy.com', '/api/v4/systems/$systemId/rgm_stats', {
      ...(await _tokenService.apiKeyQuery),
      'start_at':
          (startDateStartOfDay.millisecondsSinceEpoch / 1000).toString(),
      'end_at': (endDateEndOfDay.millisecondsSinceEpoch / 1000).toString(),
    });
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;

      var fetchedIntervals = EnphaseIntervals.fromData(jsonResponse);
      dataStore.storeIntervals(fetchedIntervals, startDate);
      return fetchedIntervals;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get token');
    }
  }
}
