import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_texas_solar/models/billing_data.dart';
import 'package:smart_texas_solar/providers/smt/api_service_provider.dart';

final billingDataProvider = FutureProvider<List<BillingData>>((ref) async {
  SMTApiService apiService = await ref.watch(smtApiServiceProvider.future);

  return await apiService.fetchBillingData();
});
