import 'package:hive_flutter/adapters.dart';

part 'interval.g.dart';

@HiveType(typeId: 4)
class Interval {
  @HiveField(0)
  DateTime endTime;
  @HiveField(1)
  num kwh;

  Interval({required this.endTime, required this.kwh});

  Interval.clone(Interval other)
      : endTime = other.endTime.copyWith(),
        kwh = other.kwh;

  void combine(Interval other) {
    kwh += other.kwh;
  }

  @override
  String toString() {
    return '$endTime - khw: $kwh';
  }

  Map<String, dynamic> toMap() {
    return {
      'endTime': endTime.toUtc().toIso8601String(),
      'kwh': kwh,
    };
  }
}
