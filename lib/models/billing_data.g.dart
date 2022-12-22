// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BillingDataAdapter extends TypeAdapter<BillingData> {
  @override
  final int typeId = 7;

  @override
  BillingData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillingData(
      fields[0] as DateTime,
      fields[1] as DateTime,
      fields[2] as num,
      fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BillingData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.endDate)
      ..writeByte(2)
      ..write(obj.kwh)
      ..writeByte(3)
      ..write(obj.lastUpdate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
