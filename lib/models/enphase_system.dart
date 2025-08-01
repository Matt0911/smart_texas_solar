import 'package:hive_flutter/adapters.dart';

part 'enphase_system.g.dart';

@HiveType(typeId: 6)
class EnphaseSystem {
  @HiveField(0)
  final String systemId;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String publicName;
  @HiveField(3)
  final String timezone;
  @HiveField(4)
  final num? systemSize;
  @HiveField(5)
  final DateTime operationalAtTime;

  EnphaseSystem({
    required this.systemId,
    required this.name,
    required this.publicName,
    required this.timezone,
    required this.systemSize,
    required this.operationalAtTime,
  });

  EnphaseSystem.fromData(Map<String, dynamic> enphaseSystemData)
      : systemId = enphaseSystemData['system_id'].toString(),
        name = enphaseSystemData['name'],
        publicName = enphaseSystemData['public_name'],
        timezone = enphaseSystemData['timezone'],
        systemSize = enphaseSystemData['system_size'],
        operationalAtTime = DateTime.fromMillisecondsSinceEpoch(
            enphaseSystemData['operational_at'] * 1000);

  Map<String, dynamic> exportJson() {
    return {
      'systemId': systemId,
      'name': name,
      'publicName': publicName,
      'timezone': timezone,
      'systemSize': systemSize,
      'operationalAtTime': operationalAtTime.toUtc().toIso8601String(),
    };
  }

  EnphaseSystem.import(Map data)
      : systemId = data['systemId'],
        name = data['name'],
        publicName = data['publicName'],
        timezone = data['timezone'],
        systemSize = data['systemSize'],
        operationalAtTime = DateTime.parse(data['operationalAtTime']).toLocal();
}
