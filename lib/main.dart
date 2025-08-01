import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_texas_solar/models/billing_data.dart';
import 'package:smart_texas_solar/models/energy_plan.dart';
import 'package:smart_texas_solar/models/energy_plan_custom_var.dart';
import 'package:smart_texas_solar/models/enphase_system.dart';
import 'package:smart_texas_solar/screens/data_export_screen.dart';
import 'package:smart_texas_solar/screens/energy_bill_history_screen.dart';
import 'package:smart_texas_solar/screens/energy_bill_selection_screen.dart';
import 'package:smart_texas_solar/screens/energy_data_screen.dart';
import 'package:smart_texas_solar/screens/energy_plan_cost_estimate_screen.dart';
import 'package:smart_texas_solar/screens/energy_plan_edit_screen.dart';
import 'package:smart_texas_solar/screens/energy_plans_screen.dart';
import 'package:smart_texas_solar/util/navigator_key.dart';

import 'models/enphase_intervals.dart';
import 'models/interval.dart';
import 'models/smt_intervals.dart';
import 'providers/hive/enphase_refresh_token_provider.dart';
import 'providers/hive/secrets_provider.dart';
import 'util/http_override.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await Hive.initFlutter();
  Hive.registerAdapter(SecretsAdapter());
  Hive.registerAdapter(EnphaseTokenResponseAdapter());
  Hive.registerAdapter(IntervalAdapter());
  Hive.registerAdapter(SMTIntervalsAdapter());
  Hive.registerAdapter(EnphaseIntervalsAdapter());
  Hive.registerAdapter(EnphaseSystemAdapter());
  Hive.registerAdapter(BillingDataAdapter());
  Hive.registerAdapter(EnergyPlanAdapter());
  Hive.registerAdapter(EnergyPlanCustomVarAdapter());
  // var _box = await Hive.openBox<EnergyPlan>('energyPlans');
  // // _box.flush();
  // _box.clear();
  // _box.deleteFromDisk();
  // print('deleted box');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Texas Solar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green, brightness: Brightness.dark),
      ),
      navigatorKey: navigatorKey,
      initialRoute: EnergyDataScreen.routeName,
      routes: {
        EnergyDataScreen.routeName: (context) => const EnergyDataScreen(),
        EnergyBillHistoryScreen.routeName: (context) =>
            const EnergyBillHistoryScreen(),
        EnergyPlansScreen.routeName: (context) => const EnergyPlansScreen(),
        EnergyPlanEditScreen.routeName: (context) =>
            const EnergyPlanEditScreen(),
        EnergyBillSelectionScreen.routeName: (context) =>
            const EnergyBillSelectionScreen(),
        EnergyPlanCostEstimateScreen.routeName: (context) =>
            const EnergyPlanCostEstimateScreen(),
        DataExportScreen.routeName: (context) => const DataExportScreen(),
      },
    );
  }
}
