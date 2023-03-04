// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'energy_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnergyPlanAdapter extends TypeAdapter<EnergyPlan> {
  @override
  final int typeId = 8;

  @override
  EnergyPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnergyPlan(
      startDate: fields[0] as DateTime?,
      endDate: fields[1] as DateTime?,
      connectionFee: fields[2] as num,
      deliveryCharge: fields[3] as num,
      kwhCharge: fields[4] as num,
      baseCharge: fields[5] as num,
      solarBuybackRate: fields[6] as num,
      customEquation: fields[9] as String,
      usesCustomEq: fields[10] as bool,
      name: fields[8] as String,
      customVars: (fields[7] as List?)?.cast<EnergyPlanCustomVar>(),
    );
  }

  @override
  void write(BinaryWriter writer, EnergyPlan obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.endDate)
      ..writeByte(2)
      ..write(obj.connectionFee)
      ..writeByte(3)
      ..write(obj.deliveryCharge)
      ..writeByte(4)
      ..write(obj.kwhCharge)
      ..writeByte(5)
      ..write(obj.baseCharge)
      ..writeByte(6)
      ..write(obj.solarBuybackRate)
      ..writeByte(7)
      ..write(obj.customVars)
      ..writeByte(8)
      ..write(obj.name)
      ..writeByte(9)
      ..write(obj.customEquation)
      ..writeByte(10)
      ..write(obj.usesCustomEq);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnergyPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
