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
        data: (exportData) {
          return Container(
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              onPressed: exportData, // TODO: react to result
              icon: const Icon(Icons.save),
              label: const Text('Export'),
            ),
          );
        },
        error: (e, s) => Text('$e with stack $s '),
        loading: () => const Text('loading'),
      ),
    );
  }
}