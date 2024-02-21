import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/providers/data_export_provider.dart';

import '../widgets/sts_drawer.dart';

class DataExportScreen extends ConsumerWidget {
  static const String routeName = '/data-export-screen';

  const DataExportScreen({Key? key}) : super(key: key);

  @override
  Widget build(context, ref) {
    var dataExporter = ref.watch(dataExportProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      drawer: const STSDrawer(),
      body: dataExporter.when(
        data: (dataUtilities) {
          return SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: dataUtilities.exportData, // TODO: react to result
                  icon: const Icon(Icons.save),
                  label: const Text('Export'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: dataUtilities.importData, // TODO: react to result
                  icon: const Icon(Icons.upload),
                  label: const Text('Import'),
                )
              ],
            ),
          );
        },
        error: (e, s) => Text('$e with stack $s '),
        loading: () => const Text('Getting things ready for export/import'),
      ),
    );
  }
}
