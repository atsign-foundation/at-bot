// 📦 Package imports:
import 'package:nyxx/nyxx.dart';

/// Login the discord bot with the given token as parameter
Future<Nyxx?> login(String? token, int? privilages) async {
  try {
    /// Check if [token] is null. If null, Throw [MissingTokenError].
    if (token == null) throw MissingTokenError();
    return Nyxx(
      token,
      privilages!,
      cacheOptions: CacheOptions()
        ..memberCachePolicyLocation = CachePolicyLocation.all()
        ..userCachePolicyLocation = CachePolicyLocation.all(),
      ignoreExceptions: false,
    );
  } catch (e) {
    Exception('Login Exception : ${e.toString()}');
  }
}
