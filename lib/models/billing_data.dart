import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/util/date_util.dart';

part 'billing_data.g.dart';

final DateFormat _formatter = DateFormat('MM/dd/yyyy');
final DateFormat _formatterLong = DateFormat('MM/dd/yyyy HH:mm:ss');
final _toStringFormatter = DateFormat('MMM d');

String getBillDateRange(DateTime start, DateTime end) {
  return '${_toStringFormatter.format(start)} - ${_toStringFormatter.format(end)} ${end.year}';
}

@HiveType(typeId: 7)
class BillingData extends HiveObject {
  // @HiveField(0)
  DateTime startDate;
  // @HiveField(1)
  DateTime endDate;
  @HiveField(2)
  num kwh;
  @HiveField(3)
  DateTime lastUpdate;
  @HiveField(4)
  num? actualBilledAmount;
  @HiveField(5)
  String startDateString;
  @HiveField(6)
  String endDateString;

// actl_kwh_usg: 290
// blld_kva_usg: "0"
// blld_kwh_usg: "0"
// enddate: "01/28/2021"
// errmsg: "Success"
// lastupdate: "01/29/2021 09:55:06"
// mtrd_kva_usg: "0"
// mtrd_kwh_usg: "0"
// startdate: "12/30/2020"

  BillingData(
    this.startDateString,
    this.endDateString,
    this.kwh,
    this.lastUpdate,
    this.actualBilledAmount,
  )   : startDate = _formatter.parse(startDateString),
        endDate = _formatter.parse(endDateString);

  BillingData.fromData(Map<String, dynamic> billingData)
      : startDate = _formatter.parse(billingData['startdate']),
        endDate = getStartOfDay(
          _formatter
              .parse(billingData['enddate'])
              .subtract(const Duration(hours: 12)),
        ),
        kwh = billingData['actl_kwh_usg'],
        lastUpdate = _formatterLong.parse(billingData['lastupdate']),
        startDateString = billingData['startdate'],
        endDateString = billingData['enddate'];

  static List<BillingData> getBillingDataList(
      Map<String, dynamic> billingDataResponse) {
    List<dynamic> monthlyData = billingDataResponse['monthlyData'];
    return monthlyData.map((data) => BillingData.fromData(data)).toList();
  }

  @override
  String toString() {
    return getBillDateRange(startDate, endDate);
  }

  Map<String, dynamic> exportJson() {
    return {
      'startDate': startDateString,
      'endDate': endDateString,
      'kwh': kwh,
      'lastUpdate': lastUpdate.toUtc().toIso8601String(),
      'actualBilledAmount': actualBilledAmount,
    };
  }

  BillingData.import(Map data)
      : startDateString = data['startDate'],
        endDateString = data['endDate'],
        startDate = _formatter.parse(data['startDate']).toLocal(),
        endDate = _formatter.parse(data['endDate']).toLocal(),
        kwh = data['kwh'],
        lastUpdate = DateTime.parse(data['lastUpdate']).toLocal(),
        actualBilledAmount = data['actualBilledAmount'];
}
