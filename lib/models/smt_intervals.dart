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

  void _addConsumptionInterval(Interval interval) {
    consumptionData.add(interval);
    consumptionMap.addInterval(interval);
  }

  void _addSurplusInterval(Interval interval) {
    surplusData.add(interval);
    surplusMap.addInterval(interval);
  }

  static Map<DateTime, SMTIntervals> splitIntoDays(
      Map<String, dynamic> smtIntervalResponse) {
    var consumptionData = (smtIntervalResponse['intervaldata'] as List)
        .map((d) => Interval(
            endTime: _formatter
                .parse(
                    '${d['date']} ${d['starttime'].toString().trimLeft().toUpperCase()}')
                .add(const Duration(minutes: 15)),
            kwh: d['consumption']))
        .toList();
    var surplusData = (smtIntervalResponse['intervaldata'] as List)
        .map((d) => Interval(
            endTime: _formatter
                .parse(
                    '${d['date']} ${d['starttime'].toString().trimLeft().toUpperCase()}')
                .add(const Duration(minutes: 15)),
            kwh: d['generation']))
        .toList();

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

  Map<String, dynamic> exportJson() {
    return {
      'consumptionData': consumptionData.map((i) => i.exportJson()).toList(),
      'surplusData': surplusData.map((i) => i.exportJson()).toList(),
    };
  }

  SMTIntervals.import(Map data)
      : consumptionData = data['consumptionData']
            .map<Interval>((d) => Interval.import(d))
            .toList(),
        surplusData = data['surplusData']
            .map<Interval>((d) => Interval.import(d))
            .toList() {
    consumptionMap = IntervalMap(consumptionData);
    surplusMap = IntervalMap(surplusData);
  }
}
