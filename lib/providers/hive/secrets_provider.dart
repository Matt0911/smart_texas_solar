import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:smart_texas_solar/secret_vals.dart' as secrets;

part 'secrets_provider.g.dart';

final secretsProvider =
    FutureProvider<HiveSecretsDB>((_) => HiveSecretsDB.create());

const String secretsBoxName = 'secrets';

class HiveSecretsDB {
  late Box _secretsBox;

  HiveSecretsDB._create();

  static Future<HiveSecretsDB> create() async {
    final component = HiveSecretsDB._create();
    await component._init();
    return component;
  }

  Future<void> _init() async {
    // TODO: use encrypted box
    _secretsBox = await Hive.openBox<Secrets>(secretsBoxName);
  }

  void storeSecrets(Secrets secrets) {
    _secretsBox.put(secretsBoxName, secrets);
  }

  Secrets getSecrets() {
    return _secretsBox.get(secretsBoxName) ?? Secrets();
  }
}

@HiveType(typeId: 1)
class Secrets {
  @HiveField(0)
  String smtUser;
  @HiveField(1)
  String smtPass;
  @HiveField(2)
  String enphaseClientId;
  @HiveField(3)
  String enphaseClientSecret;
  @HiveField(4)
  String enphaseApiKey;

  Secrets({
    this.smtUser = secrets.smtUser,
    this.smtPass = secrets.smtPass,
    this.enphaseClientId = secrets.enphaseClientId,
    this.enphaseClientSecret = secrets.enphaseClientSecret,
    this.enphaseApiKey = secrets.enphaseApiKey,
  });
}
