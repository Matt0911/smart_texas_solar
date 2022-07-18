import 'package:hive_flutter/adapters.dart';
import 'package:smart_texas_solar/models/interval_map.dart';

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
  }

  Map<DateTime, EnphaseIntervals> splitIntoDays() {
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
}
