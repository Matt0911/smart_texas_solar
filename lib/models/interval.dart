class Interval {
  DateTime endTime;
  num kwh;

  Interval({required this.endTime, required this.kwh});

  @override
  String toString() {
    return '$endTime - khw: $kwh';
  }
}
