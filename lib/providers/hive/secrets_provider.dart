import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:smart_texas_solar/secret_vals.dart' as secrets;
import 'package:smart_texas_solar/util/navigator_key.dart';
import 'package:smart_texas_solar/widgets/smt_credentials_dialog.dart';

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
    // Use HiveAesCipher for encryption. Store your encryption key securely.
    final encryptionKey =
        secrets.hiveEncryptionKey; // Should be a 32-byte Uint8List
    _secretsBox = await Hive.openBox<Secrets>(
      secretsBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  void storeSecrets(Secrets secrets) {
    _secretsBox.put(secretsBoxName, secrets);
  }

  Future<Secrets> getSecrets() async {
    if (!_secretsBox.containsKey(secretsBoxName)) {
      SMTCredentials? creds = null;

      while (creds == null) {
        creds = await showDialog<SMTCredentials>(
          context: navigatorKey.currentContext!,
          builder: (context) => SmtCredentialsDialog(),
        );
      }

      storeSecrets(Secrets(
        smtUser: creds.username,
        smtPass: creds.password,
        enphaseClientId: secrets.enphaseClientId,
        enphaseClientSecret: secrets.enphaseClientSecret,
        enphaseApiKey: secrets.enphaseApiKey,
      ));
    }
    return _secretsBox.get(secretsBoxName);
  }
}

@HiveType(typeId: 1)
class Secrets {
  // TODO: screen for smt user/pass
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
    required this.smtUser,
    required this.smtPass,
    this.enphaseClientId = secrets.enphaseClientId,
    this.enphaseClientSecret = secrets.enphaseClientSecret,
    this.enphaseApiKey = secrets.enphaseApiKey,
  });
}
