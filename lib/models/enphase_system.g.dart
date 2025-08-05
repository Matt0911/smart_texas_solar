// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enphase_system.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnphaseSystemAdapter extends TypeAdapter<EnphaseSystem> {
  @override
  final int typeId = 6;

  @override
  EnphaseSystem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnphaseSystem(
      systemId: fields[0] as String,
      name: fields[1] as String,
      publicName: fields[2] as String,
      timezone: fields[3] as String,
      systemSize: fields[4] as num?,
      operationalAtTime: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EnphaseSystem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.systemId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.publicName)
      ..writeByte(3)
      ..write(obj.timezone)
      ..writeByte(4)
      ..write(obj.systemSize)
      ..writeByte(5)
      ..write(obj.operationalAtTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnphaseSystemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
