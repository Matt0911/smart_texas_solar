// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enphase_refresh_token_provider.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnphaseTokenResponseAdapter extends TypeAdapter<EnphaseTokenResponse> {
  @override
  final int typeId = 2;

  @override
  EnphaseTokenResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnphaseTokenResponse(
      accessToken: fields[0] as String,
      refreshToken: fields[1] as String,
      expiresIn: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, EnphaseTokenResponse obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.accessToken)
      ..writeByte(1)
      ..write(obj.refreshToken)
      ..writeByte(2)
      ..write(obj.expiresIn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnphaseTokenResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
