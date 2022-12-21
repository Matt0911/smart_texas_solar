import 'package:flutter/material.dart';
import 'package:smart_texas_solar/screens/energy_bill_screen.dart';
import 'package:smart_texas_solar/screens/energy_data_screen.dart';

class STSDrawer extends StatelessWidget {
  const STSDrawer({
    Key? key,
  }) : super(key: key);

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
            leading: const Icon(Icons.format_list_bulleted),
            title: const Text('Energy Bill'),
            selected: EnergyBillScreen.routeName == currentRoute,
            onTap: EnergyBillScreen.routeName == currentRoute
                ? () => Navigator.pop(context)
                : () => Navigator.pushNamed(
                      context,
                      EnergyBillScreen.routeName,
                    ),
          ),
        ],
      ),
    );
  }
}
