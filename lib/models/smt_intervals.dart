import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/models/interval_map.dart';

import 'interval.dart';

part 'smt_intervals.g.dart';

final DateFormat _formatter = DateFormat('yyyy-MM-dd hh:mm a');

@HiveType(typeId: 5)
class SMTIntervals {
  @HiveField(0)
  final List<Interval> consumptionData;
  @HiveField(1)
  final List<Interval> surplusData;

  late final IntervalMap consumptionMap;
  late final IntervalMap surplusMap;

  SMTIntervals(this.consumptionData, this.surplusData)
      : consumptionMap = IntervalMap(consumptionData),
        surplusMap = IntervalMap(surplusData);

  SMTIntervals.fromData(Map<String, dynamic> smtIntervalResponse)
      : consumptionData = (smtIntervalResponse['intervaldata'] as List)
            .map((d) => Interval(
                endTime: _formatter
                    .parse(
                        '${d['date']} ${d['starttime'].toString().trimLeft().toUpperCase()}')
                    .add(const Duration(minutes: 15)),
                kwh: d['consumption']))
            .toList(),
        surplusData = (smtIntervalResponse['intervaldata'] as List)
            .map((d) => Interval(
                endTime: _formatter
                    .parse(
                        '${d['date']} ${d['starttime'].toString().trimLeft().toUpperCase()}')
                    .add(const Duration(minutes: 15)),
                kwh: d['generation']))
            .toList() {
    consumptionMap = IntervalMap(consumptionData);
    surplusMap = IntervalMap(surplusData);
  }

  SMTIntervals.combine(List<SMTIntervals> dates)
      : consumptionData = dates
            .map((e) => e.consumptionData)
            .reduce((value, element) => value..addAll(element)),
        surplusData = dates
            .map((e) => e.surplusData)
            .reduce((value, element) => value..addAll(element)) {
    consumptionMap = IntervalMap(consumptionData);
    surplusMap = IntervalMap(surplusData);
  }

  _addConsumptionInterval(Interval interval) {
    consumptionData.add(interval);
  }

  _addSurplusInterval(Interval interval) {
    surplusData.add(interval);
  }

  Map<DateTime, SMTIntervals> splitIntoDays() {
    Map<DateTime, SMTIntervals> data = {};
    for (var i = 0; i < consumptionData.length; i++) {
      var consumptionInterval = consumptionData[i];
      var intervalDay =
          consumptionInterval.endTime.subtract(const Duration(minutes: 1));
      var startOfDay = DateTime(
        intervalDay.year,
        intervalDay.month,
        intervalDay.day,
      );

      if (data.containsKey(startOfDay)) {
        data[startOfDay]!
          .._addConsumptionInterval(consumptionInterval)
          .._addSurplusInterval(surplusData[i]);
      } else {
        data[startOfDay] =
            SMTIntervals([consumptionInterval], [surplusData[i]]);
      }
    }

    return data;
  }
}
