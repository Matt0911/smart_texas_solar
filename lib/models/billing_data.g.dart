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
      fields[5] as String,
      fields[6] as String,
      fields[2] as num,
      fields[3] as DateTime,
      fields[4] as num?,
    );
  }

  @override
  void write(BinaryWriter writer, BillingData obj) {
    writer
      ..writeByte(5)
      ..writeByte(2)
      ..write(obj.kwh)
      ..writeByte(3)
      ..write(obj.lastUpdate)
      ..writeByte(4)
      ..write(obj.actualBilledAmount)
      ..writeByte(5)
      ..write(obj.startDateString)
      ..writeByte(6)
      ..write(obj.endDateString);
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
