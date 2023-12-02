import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/providers/hive/energy_plan_store_provider.dart';
import 'package:smart_texas_solar/providers/hive/enphase_data_store_provider.dart';
import 'package:smart_texas_solar/providers/hive/smt_data_store_provider.dart';

final dataExportProvider = FutureProvider.autoDispose((ref) async {
  var smtDataStore = await ref.watch(smtDataStoreProvider.future);
  var enphaseDataStore = await ref.watch(enphaseDataStoreProvider.future);
  var energyPlanStore = await ref.watch(energyPlanStoreProvider.future);

  exportData() async {
    try {
      var smtData = smtDataStore.exportData();
      var enphaseData = enphaseDataStore.exportData();
      var energyPlanData = energyPlanStore.exportData();
      var data = {
        ...smtData,
        ...enphaseData,
        ...energyPlanData,
      };

      final DateFormat dateFormatter = DateFormat('yyyy-MM-dd-HH-mm-ss');
      var dir = await getTemporaryDirectory();
      String filename =
          '${dir.path}/SmartTexasSolar-export-${dateFormatter.format(DateTime.now())}.json';
      var dataFile = await File(filename).writeAsString(json.encode(data));

      final result =
          await Share.shareXFiles([XFile(filename)], text: 'Data Export');

      if (result.status == ShareResultStatus.success) {
        dataFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  return exportData;
});
