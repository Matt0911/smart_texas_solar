import 'package:intl/intl.dart';

import './interval.dart';

final DateFormat intervalTimeFormat = DateFormat('tHHmm');

Map<IntervalTime, Interval> _convertListToMap(List<Interval> intervalList) {
  Map<IntervalTime, Interval> map = {};
  for (var intervalOrig in intervalList) {
    var interval = Interval.clone(intervalOrig);
    var key = IntervalTime.values.byName(intervalTimeFormat
        .format(interval.endTime.subtract(const Duration(minutes: 15))));
    if (map[key] != null) {
      map[key]!.combine(interval);
    } else {
      map[key] = interval;
    }
  }
  for (var key in IntervalTime.values) {
    if (map[key] == null) {
      var missingDate = intervalList.first.endTime;
      var missingHours = int.tryParse(key.name.substring(1, 3));
      var missingMins = int.tryParse(key.name.substring(3));
      var missingIntervalEndTime = DateTime(
        missingDate.year,
        missingDate.month,
        missingDate.day,
        missingHours!,
        missingMins!,
      ).add(const Duration(minutes: 15));
      map[key] = Interval(endTime: missingIntervalEndTime, kwh: 0);
    }
  }
  return map;
}

class IntervalMap {
  Map<IntervalTime, Interval> intervals;

  IntervalMap(List<Interval> intervalList)
      : intervals = _convertListToMap(intervalList);

  IntervalMap.copy(IntervalMap other)
      : intervals = IntervalMap(other.intervals.values.toList()).intervals;

  Interval? getIntervalByDateTime(DateTime endDate) =>
      intervals[IntervalTime.values.byName(intervalTimeFormat
          .format(endDate.subtract(const Duration(minutes: 15))))];

  Interval? getInterval(IntervalTime time) => intervals[time];

  addInterval(Interval interval) {
    var key = IntervalTime.values.byName(intervalTimeFormat
        .format(interval.endTime.subtract(const Duration(minutes: 15))));
    intervals[key] = interval;
  }

  addIntervalMap(IntervalMap other) {
    intervals.forEach((time, value) {
      value.kwh += other.intervals[time]!.kwh;
    });
  }

  subtractIntervalMap(IntervalMap other) {
    intervals.forEach((time, value) {
      value.kwh -= other.intervals[time]!.kwh;
    });
  }
}

enum IntervalTime {
  t0000,
  t0015,
  t0030,
  t0045,
  t0100,
  t0115,
  t0130,
  t0145,
  t0200,
  t0215,
  t0230,
  t0245,
  t0300,
  t0315,
  t0330,
  t0345,
  t0400,
  t0415,
  t0430,
  t0445,
  t0500,
  t0515,
  t0530,
  t0545,
  t0600,
  t0615,
  t0630,
  t0645,
  t0700,
  t0715,
  t0730,
  t0745,
  t0800,
  t0815,
  t0830,
  t0845,
  t0900,
  t0915,
  t0930,
  t0945,
  t1000,
  t1015,
  t1030,
  t1045,
  t1100,
  t1115,
  t1130,
  t1145,
  t1200,
  t1215,
  t1230,
  t1245,
  t1300,
  t1315,
  t1330,
  t1345,
  t1400,
  t1415,
  t1430,
  t1445,
  t1500,
  t1515,
  t1530,
  t1545,
  t1600,
  t1615,
  t1630,
  t1645,
  t1700,
  t1715,
  t1730,
  t1745,
  t1800,
  t1815,
  t1830,
  t1845,
  t1900,
  t1915,
  t1930,
  t1945,
  t2000,
  t2015,
  t2030,
  t2045,
  t2100,
  t2115,
  t2130,
  t2145,
  t2200,
  t2215,
  t2230,
  t2245,
  t2300,
  t2315,
  t2330,
  t2345,
}
