// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'energy_plan_custom_var.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnergyPlanCustomVarAdapter extends TypeAdapter<EnergyPlanCustomVar> {
  @override
  final int typeId = 9;

  @override
  EnergyPlanCustomVar read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnergyPlanCustomVar(
      name: fields[0] as String,
      value: fields[1] as num,
      symbol: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EnergyPlanCustomVar obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.symbol);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnergyPlanCustomVarAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
