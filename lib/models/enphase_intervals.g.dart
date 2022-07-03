// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enphase_intervals.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnphaseIntervalsAdapter extends TypeAdapter<EnphaseIntervals> {
  @override
  final int typeId = 3;

  @override
  EnphaseIntervals read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnphaseIntervals(
      (fields[0] as List).cast<Interval>(),
    );
  }

  @override
  void write(BinaryWriter writer, EnphaseIntervals obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.generationData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnphaseIntervalsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
