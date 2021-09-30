// 📦 Package imports:
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/utils/custom_print.dart';

/// Login the discord bot with the given token as parameter
Future<Nyxx?> login(String? token, int? privilages) async {
  try {
    /// Check if [token] is null. If null, Throw [MissingTokenError].
    if (token == null) throw MissingTokenError();
    return Nyxx(
      token,
      privilages!,
      ignoreExceptions: false,
    );
  } catch (e) {
    printError('Login error: ${e.toString()}');
  }
}
