import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/widgets/sts_drawer.dart';

final _formatter = DateFormat('MMM dd, yyyy');
String getSelectedDateText(DateTime start, DateTime end) {
  var startStr = _formatter.format(start);
  var endStr = _formatter.format(end);
  if (startStr == endStr) return startStr;
  return '$startStr - $endStr';
}

class EnergyBillScreen extends ConsumerWidget {
  static const String routeName = '/energy-bill-screen';

  const EnergyBillScreen({Key? key}) : super(key: key);

  @override
  Widget build(context, ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Bill Analysis'),
      ),
      drawer: const STSDrawer(),
      body: Column(
        children: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Bill data stuff....'),
          ),
        ],
      ),
    );
  }
}
