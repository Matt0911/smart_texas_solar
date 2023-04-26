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

List<Interval> _getFilteredIntervals(
    Map<IntervalTime, Interval> intervalsMap, List<IntervalTime> desiredTimes) {
  List<Interval> filtered = [];
  for (var time in desiredTimes) {
    filtered.add(Interval.clone(intervalsMap[time]!));
  }
  return filtered;
}

class IntervalMap {
  Map<IntervalTime, Interval> intervals;

  IntervalMap(List<Interval> intervalList)
      : intervals = _convertListToMap(intervalList);

  IntervalMap.clone(IntervalMap other)
      : intervals = _convertListToMap(other.intervals.values.toList());

  IntervalMap.filtered(IntervalMap other, List<IntervalTime> desiredTimes)
      : intervals = _convertListToMap(
          _getFilteredIntervals(other.intervals, desiredTimes),
        );

  Interval? getIntervalByDateTime(DateTime endDate) =>
      intervals[IntervalTime.values.byName(intervalTimeFormat
          .format(endDate.subtract(const Duration(minutes: 15))))];

  Interval? getInterval(IntervalTime time) => intervals[time];

  num get totalKwh =>
      intervals.values.fold<num>(0, (sum, interval) => sum + interval.kwh);

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

extension IntervalTimeExtension on IntervalTime {
  String get displayName {
    switch (this) {
      case (IntervalTime.t0000):
        return '12:00am';
      case (IntervalTime.t0015):
        return '12:15am';
      case (IntervalTime.t0030):
        return '12:30am';
      case (IntervalTime.t0045):
        return '12:45am';
      case (IntervalTime.t0100):
        return '1:00am';
      case (IntervalTime.t0115):
        return '1:15am';
      case (IntervalTime.t0130):
        return '1:30am';
      case (IntervalTime.t0145):
        return '1:45am';
      case (IntervalTime.t0200):
        return '2:00am';
      case (IntervalTime.t0215):
        return '2:15am';
      case (IntervalTime.t0230):
        return '2:30am';
      case (IntervalTime.t0245):
        return '2:45am';
      case (IntervalTime.t0300):
        return '3:00am';
      case (IntervalTime.t0315):
        return '3:15am';
      case (IntervalTime.t0330):
        return '3:30am';
      case (IntervalTime.t0345):
        return '3:45am';
      case (IntervalTime.t0400):
        return '4:00am';
      case (IntervalTime.t0415):
        return '4:15am';
      case (IntervalTime.t0430):
        return '4:30am';
      case (IntervalTime.t0445):
        return '4:45am';
      case (IntervalTime.t0500):
        return '5:00am';
      case (IntervalTime.t0515):
        return '5:15am';
      case (IntervalTime.t0530):
        return '5:30am';
      case (IntervalTime.t0545):
        return '5:45am';
      case (IntervalTime.t0600):
        return '6:00am';
      case (IntervalTime.t0615):
        return '6:15am';
      case (IntervalTime.t0630):
        return '6:30am';
      case (IntervalTime.t0645):
        return '6:45am';
      case (IntervalTime.t0700):
        return '7:00am';
      case (IntervalTime.t0715):
        return '7:15am';
      case (IntervalTime.t0730):
        return '7:30am';
      case (IntervalTime.t0745):
        return '7:45am';
      case (IntervalTime.t0800):
        return '8:00am';
      case (IntervalTime.t0815):
        return '8:15am';
      case (IntervalTime.t0830):
        return '8:30am';
      case (IntervalTime.t0845):
        return '8:45am';
      case (IntervalTime.t0900):
        return '9:00am';
      case (IntervalTime.t0915):
        return '9:15am';
      case (IntervalTime.t0930):
        return '9:30am';
      case (IntervalTime.t0945):
        return '9:45am';
      case (IntervalTime.t1000):
        return '10:00am';
      case (IntervalTime.t1015):
        return '10:15am';
      case (IntervalTime.t1030):
        return '10:30am';
      case (IntervalTime.t1045):
        return '10:45am';
      case (IntervalTime.t1100):
        return '11:00am';
      case (IntervalTime.t1115):
        return '11:15am';
      case (IntervalTime.t1130):
        return '11:30am';
      case (IntervalTime.t1145):
        return '11:45am';
      case (IntervalTime.t1200):
        return '12:00pm';
      case (IntervalTime.t1215):
        return '12:15pm';
      case (IntervalTime.t1230):
        return '12:30pm';
      case (IntervalTime.t1245):
        return '12:45pm';
      case (IntervalTime.t1300):
        return '1:00pm';
      case (IntervalTime.t1315):
        return '1:15pm';
      case (IntervalTime.t1330):
        return '1:30pm';
      case (IntervalTime.t1345):
        return '1:45pm';
      case (IntervalTime.t1400):
        return '2:00pm';
      case (IntervalTime.t1415):
        return '2:15pm';
      case (IntervalTime.t1430):
        return '2:30pm';
      case (IntervalTime.t1445):
        return '2:45pm';
      case (IntervalTime.t1500):
        return '3:00pm';
      case (IntervalTime.t1515):
        return '3:15pm';
      case (IntervalTime.t1530):
        return '3:30pm';
      case (IntervalTime.t1545):
        return '3:45pm';
      case (IntervalTime.t1600):
        return '4:00pm';
      case (IntervalTime.t1615):
        return '4:15pm';
      case (IntervalTime.t1630):
        return '4:30pm';
      case (IntervalTime.t1645):
        return '4:45pm';
      case (IntervalTime.t1700):
        return '5:00pm';
      case (IntervalTime.t1715):
        return '5:15pm';
      case (IntervalTime.t1730):
        return '5:30pm';
      case (IntervalTime.t1745):
        return '5:45pm';
      case (IntervalTime.t1800):
        return '6:00pm';
      case (IntervalTime.t1815):
        return '6:15pm';
      case (IntervalTime.t1830):
        return '6:30pm';
      case (IntervalTime.t1845):
        return '6:45pm';
      case (IntervalTime.t1900):
        return '7:00pm';
      case (IntervalTime.t1915):
        return '7:15pm';
      case (IntervalTime.t1930):
        return '7:30pm';
      case (IntervalTime.t1945):
        return '7:45pm';
      case (IntervalTime.t2000):
        return '8:00pm';
      case (IntervalTime.t2015):
        return '8:15pm';
      case (IntervalTime.t2030):
        return '8:30pm';
      case (IntervalTime.t2045):
        return '8:45pm';
      case (IntervalTime.t2100):
        return '9:00pm';
      case (IntervalTime.t2115):
        return '9:15pm';
      case (IntervalTime.t2130):
        return '9:30pm';
      case (IntervalTime.t2145):
        return '9:45pm';
      case (IntervalTime.t2200):
        return '10:00pm';
      case (IntervalTime.t2215):
        return '10:15pm';
      case (IntervalTime.t2230):
        return '10:30pm';
      case (IntervalTime.t2245):
        return '10:45pm';
      case (IntervalTime.t2300):
        return '11:00pm';
      case (IntervalTime.t2315):
        return '11:15pm';
      case (IntervalTime.t2330):
        return '11:30pm';
      case (IntervalTime.t2345):
        return '11:45pm';
    }
  }
}
