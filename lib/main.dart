import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_texas_solar/models/billing_data.dart';
import 'package:smart_texas_solar/models/energy_plan.dart';
import 'package:smart_texas_solar/models/energy_plan_custom_var.dart';
import 'package:smart_texas_solar/models/enphase_system.dart';
import 'package:smart_texas_solar/screens/energy_bill_screen.dart';
import 'package:smart_texas_solar/screens/energy_data_screen.dart';
import 'package:smart_texas_solar/screens/energy_plan_create_screen.dart';
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
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Texas Solar',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ),
      navigatorKey: navigatorKey,
      initialRoute: EnergyDataScreen.routeName,
      routes: {
        EnergyDataScreen.routeName: (context) => const EnergyDataScreen(),
        EnergyBillScreen.routeName: (context) => const EnergyBillScreen(),
        EnergyPlansScreen.routeName: (context) => const EnergyPlansScreen(),
        EnergyPlanCreateScreen.routeName: (context) =>
            const EnergyPlanCreateScreen(),
      },
    );
  }
}
