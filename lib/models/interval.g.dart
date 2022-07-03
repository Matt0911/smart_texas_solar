// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interval.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IntervalAdapter extends TypeAdapter<Interval> {
  @override
  final int typeId = 4;

  @override
  Interval read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Interval(
      endTime: fields[0] as DateTime,
      kwh: fields[1] as num,
    );
  }

  @override
  void write(BinaryWriter writer, Interval obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.endTime)
      ..writeByte(1)
      ..write(obj.kwh);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntervalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
