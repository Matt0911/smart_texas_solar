import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

  return DataUtilities(
      smtDataStore: smtDataStore,
      enphaseDataStore: enphaseDataStore,
      energyPlanStore: energyPlanStore);
});

class DataUtilities {
  SMTDataStore smtDataStore;
  EnphaseDataStore enphaseDataStore;
  EnergyPlanStore energyPlanStore;

  DataUtilities({
    required this.smtDataStore,
    required this.enphaseDataStore,
    required this.energyPlanStore,
  });

  Future<bool> exportData() async {
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

      final result = await SharePlus.instance
          .share(ShareParams(files: [XFile(filename)], text: 'Data Export'));

      if (result.status == ShareResultStatus.success) {
        dataFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        var dataStr = await file.readAsString();
        Map<String, dynamic> data = json.decode(dataStr);

        // pass data to each store
        smtDataStore.importData(data);
        enphaseDataStore.importData(data);
        energyPlanStore.importData(data);

        return true;
      } else {
        // User canceled the picker
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
