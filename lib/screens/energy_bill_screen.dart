import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/providers/smt/billing_data_provider.dart';
import 'package:smart_texas_solar/widgets/sts_drawer.dart';

final _formatter = DateFormat('MMM dd');

const kTableHeaderStyle =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 2);

String getBillDateRange(DateTime start, DateTime end) {
  return '${_formatter.format(start)} - ${_formatter.format(end)} ${end.year}';
}

class EnergyBillScreen extends ConsumerWidget {
  static const String routeName = '/energy-bill-screen';

  const EnergyBillScreen({Key? key}) : super(key: key);

  @override
  Widget build(context, ref) {
    var billingData = ref.watch(billingDataProvider);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Energy Bill Analysis'),
        ),
        drawer: const STSDrawer(),
        body: billingData.when(
          data: (data) => Table(
            border: TableBorder.all(),
            columnWidths: const {
              0: FixedColumnWidth(160),
            },
            children: [
              const TableRow(children: [
                Text('Dates', style: kTableHeaderStyle),
                Text('Consumption', style: kTableHeaderStyle),
                Text('Surplus', style: kTableHeaderStyle),
                Text('Estimated Bill', style: kTableHeaderStyle),
              ]),
              ...data.reversed
                  .map((bill) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                getBillDateRange(bill.startDate, bill.endDate)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(bill.kwh.toString()),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('200'),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('\$20.54'),
                          ),
                        ],
                      ))
                  .toList()
            ],
          ),
          error: (error, stackTrace) => Text(error.toString()),
          loading: () => const Text('Loading...'),
        ));
  }
}
