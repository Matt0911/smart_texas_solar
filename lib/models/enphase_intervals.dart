import 'package:hive_flutter/adapters.dart';

import 'interval.dart';

part 'enphase_intervals.g.dart';

@HiveType(typeId: 3)
class EnphaseIntervals {
  @HiveField(0)
  List<Interval> generationData;

  EnphaseIntervals(this.generationData);

  EnphaseIntervals.fromData(Map<String, dynamic> enphaseIntervalResponse)
      : generationData = (enphaseIntervalResponse['intervals'] as List)
            .map((d) => Interval(
                endTime:
                    DateTime.fromMillisecondsSinceEpoch(d['end_at'] * 1000),
                kwh: d['wh_del'] / 1000))
            .toList();
}
