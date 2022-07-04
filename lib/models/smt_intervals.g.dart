// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smt_intervals.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SMTIntervalsAdapter extends TypeAdapter<SMTIntervals> {
  @override
  final int typeId = 5;

  @override
  SMTIntervals read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SMTIntervals(
      (fields[0] as List).cast<Interval>(),
      (fields[1] as List).cast<Interval>(),
    );
  }

  @override
  void write(BinaryWriter writer, SMTIntervals obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.consumptionData)
      ..writeByte(1)
      ..write(obj.surplusData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SMTIntervalsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
