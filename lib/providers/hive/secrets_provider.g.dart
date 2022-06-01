// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secrets_provider.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SecretsAdapter extends TypeAdapter<Secrets> {
  @override
  final int typeId = 1;

  @override
  Secrets read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Secrets(
      smtUser: fields[0] as String,
      smtPass: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Secrets obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.smtUser)
      ..writeByte(1)
      ..write(obj.smtPass);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecretsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
