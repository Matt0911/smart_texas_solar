import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';

part 'enphase_refresh_token_provider.g.dart';

final enphaseRefreshTokenProvider =
    FutureProvider<EnphaseTokenStore>((_) => EnphaseTokenStore.create());

const String boxName = 'enphaseTokenStore';

// class EnphaseRefreshTokenService {
//   late Box<String> _box;

//   EnphaseRefreshTokenService._create();

//   static Future<EnphaseRefreshTokenService> create() async {
//     final component = EnphaseRefreshTokenService._create();
//     await component._init();
//     return component;
//   }

//   _init() async {
//     // TODO: use encrypted box
//     _box = await Hive.openBox<String>(boxName);
//   }

//   storeSecrets(String refreshToken) {
//     _box.put(boxName, refreshToken);
//   }

//   String? getRefreshToken() {
//     return _box.get(boxName);
//   }
// }

class EnphaseTokenStore {
  late Box _tokensBox;

  EnphaseTokenStore._create();

  static Future<EnphaseTokenStore> create() async {
    final component = EnphaseTokenStore._create();
    await component._init();
    return component;
  }

  _init() async {
    // TODO: use encrypted box
    _tokensBox = await Hive.openBox<EnphaseTokenResponse>(boxName);
    // _tokensBox.clear();
  }

  storeTokens(EnphaseTokenResponse tokens) {
    _tokensBox.put(boxName, tokens);
  }

  EnphaseTokenResponse? getTokens() {
    return _tokensBox.get(boxName);
  }
}

@HiveType(typeId: 2)
class EnphaseTokenResponse {
  @HiveField(0)
  String accessToken;
  @HiveField(1)
  String refreshToken;
  @HiveField(2)
  int expiresIn;

  EnphaseTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
  EnphaseTokenResponse.fromData(Map<String, dynamic> data)
      : accessToken = data['access_token'],
        refreshToken = data['refresh_token'],
        expiresIn = data['expires_in'];
}
