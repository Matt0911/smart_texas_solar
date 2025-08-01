import 'package:flutter/material.dart';
import 'package:smart_texas_solar/screens/data_export_screen.dart';
import 'package:smart_texas_solar/screens/energy_bill_history_screen.dart';
import 'package:smart_texas_solar/screens/energy_bill_selection_screen.dart';
import 'package:smart_texas_solar/screens/energy_data_screen.dart';
import 'package:smart_texas_solar/screens/energy_plans_screen.dart';

class STSDrawer extends StatelessWidget {
  const STSDrawer({
    super.key,
  });

  @override
  Widget build(context) {
    String currentRoute = ModalRoute.of(context)!.settings.name ?? 'test';
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.area_chart_outlined),
            title: const Text('Energy Data'),
            selected: EnergyDataScreen.routeName == currentRoute,
            onTap: EnergyDataScreen.routeName == currentRoute
                ? () => Navigator.pop(context)
                : () => Navigator.pushNamed(
                      context,
                      EnergyDataScreen.routeName,
                    ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Bill History'),
            selected: EnergyBillHistoryScreen.routeName == currentRoute,
            onTap: EnergyBillHistoryScreen.routeName == currentRoute
                ? () => Navigator.pop(context)
                : () => Navigator.pushNamed(
                      context,
                      EnergyBillHistoryScreen.routeName,
                    ),
          ),
          ListTile(
            leading: const Icon(Icons.format_list_bulleted),
            title: const Text('Energy Plans'),
            selected: EnergyPlansScreen.routeName == currentRoute,
            onTap: EnergyPlansScreen.routeName == currentRoute
                ? () => Navigator.pop(context)
                : () => Navigator.pushNamed(
                      context,
                      EnergyPlansScreen.routeName,
                    ),
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('Energy Plan Cost Estimator'),
            selected: EnergyBillSelectionScreen.routeName == currentRoute,
            onTap: EnergyBillSelectionScreen.routeName == currentRoute
                ? () => Navigator.pop(context)
                : () => Navigator.pushNamed(
                      context,
                      EnergyBillSelectionScreen.routeName,
                    ),
          ),
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Export Data'),
            selected: DataExportScreen.routeName == currentRoute,
            onTap: DataExportScreen.routeName == currentRoute
                ? () => Navigator.pop(context)
                : () => Navigator.pushNamed(
                      context,
                      DataExportScreen.routeName,
                    ),
          ),
        ],
      ),
    );
  }
}
