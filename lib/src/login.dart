// 📦 Package imports:
// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:nyxx/nyxx.dart';

/// Login the discord bot with the given token as parameter
Future<INyxxWebsocket?> login(String? token, int? privilages) async {
  try {
    /// Check if [token] is null. If null, Throw [MissingTokenError].
    if (token == null) throw MissingTokenError();
    return NyxxFactory.createNyxxWebsocket(
      token,
      privilages!,
      cacheOptions: CacheOptions()
        ..memberCachePolicyLocation = CachePolicyLocation.all()
        ..userCachePolicyLocation = CachePolicyLocation.all(),
    );
  } catch (e) {
    AtBotLogger.logln(LogTypeTag.error, 'Login Exception : ${e.toString()}');
    return null;
  }
}
