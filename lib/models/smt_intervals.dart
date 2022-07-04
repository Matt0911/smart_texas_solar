import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

import 'interval.dart';

part 'smt_intervals.g.dart';

final DateFormat _formatter = DateFormat('yyyy-MM-dd hh:mm a');

@HiveType(typeId: 5)
class SMTIntervals {
  @HiveField(0)
  List<Interval> consumptionData;
  @HiveField(1)
  List<Interval> surplusData;

  SMTIntervals(this.consumptionData, this.surplusData);

  SMTIntervals.fromData(Map<String, dynamic> smtIntervalResponse)
      : consumptionData = (smtIntervalResponse['intervaldata'] as List)
            .map((d) => Interval(
                endTime: _formatter.parse(
                    '${d['date']} ${d['endtime'].toString().trimLeft().toUpperCase()}'),
                kwh: d['consumption']))
            .toList(),
        surplusData = (smtIntervalResponse['intervaldata'] as List)
            .map((d) => Interval(
                endTime: _formatter.parse(
                    '${d['date']} ${d['endtime'].toString().trimLeft().toUpperCase()}'),
                kwh: d['generation']))
            .toList();
}
