import 'package:hive_flutter/adapters.dart';
import 'package:smart_texas_solar/models/interval_map.dart';
import 'package:smart_texas_solar/util/date_util.dart';

import 'interval.dart';

part 'enphase_intervals.g.dart';

@HiveType(typeId: 3)
class EnphaseIntervals {
  @HiveField(0)
  final List<Interval> generationData;

  late final IntervalMap generationMap;

  EnphaseIntervals(this.generationData)
      : generationMap = IntervalMap(generationData);

  EnphaseIntervals.fromData(Map<String, dynamic> enphaseIntervalResponse)
      : generationData = (enphaseIntervalResponse['intervals'] as List)
            .map((d) => Interval(
                endTime:
                    DateTime.fromMillisecondsSinceEpoch(d['end_at'] * 1000),
                kwh: d['wh_del'] / 1000))
            .toList() {
    generationMap = IntervalMap(generationData);
  }

  EnphaseIntervals.combine(List<EnphaseIntervals> dates)
      : generationData = dates.map((e) => e.generationData).reduce(
              (value, element) => value..addAll(element),
            ) {
    generationMap = IntervalMap(generationData);
  }

  _addInterval(Interval interval) {
    generationData.add(interval);
    generationMap.addInterval(interval);
  }

  static Map<DateTime, EnphaseIntervals> splitIntoDays(
      Map<String, dynamic> enphaseIntervalResponse) {
    var generationData = (enphaseIntervalResponse['intervals'] as List)
        .map((d) => Interval(
            endTime: DateTime.fromMillisecondsSinceEpoch(d['end_at'] * 1000),
            kwh: d['wh_del'] / 1000))
        .toList();
    Map<DateTime, EnphaseIntervals> data = {};
    for (var interval in generationData) {
      var intervalDay = interval.endTime.subtract(const Duration(minutes: 1));
      var startOfDay = DateTime(
        intervalDay.year,
        intervalDay.month,
        intervalDay.day,
      );

      if (data.containsKey(startOfDay)) {
        data[startOfDay]!._addInterval(interval);
      } else {
        data[startOfDay] = EnphaseIntervals([interval]);
      }
    }

    return data;
  }

  static Map<DateTime, EnphaseIntervals> getEmptyDays(
      DateTime start, DateTime end) {
    var dates = getDateListFromRange(start, end);
    Map<DateTime, EnphaseIntervals> data = {};
    for (var date in dates) {
      var endOfFirstInterval = DateTime(
        date.year,
        date.month,
        date.day,
        0,
        15,
      );

      // this works beacuse generationMap missing values are filled in during
      // IntervalMap constructor. We just need the one Interval to know the day
      var fakeGenerationData = [Interval(endTime: endOfFirstInterval, kwh: 0)];
      data[date] = EnphaseIntervals(fakeGenerationData);
    }

    return data;
  }

  Map<String, dynamic> exportJson() {
    return {
      'generationData': generationData.map((i) => i.exportJson()).toList(),
    };
  }

  EnphaseIntervals.import(Map data)
      : generationData = data['generationData']
            .map<Interval>((d) => Interval.import(d))
            .toList() {
    generationMap = IntervalMap(generationData);
  }
}
