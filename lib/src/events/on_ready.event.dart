// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';

// 🌎 Project imports:

/// On bot ready Do what ever you want 😎.
Future<void> onReadyEvent(Nyxx? client) async {
  client!.onReady.listen((_) {
    try {
      /// Set the bot activity to listening.
      client.setPresence(
        PresenceBuilder.of(
          status: UserStatus.online,
          activity: ActivityBuilder.listening('@signs')..url = 'https://atsign.com/',
        ),
      );
      AtBotLogger.logln(LogTypeTag.success, '${client.self.tag} is ready to go 🔥');
    } catch (e) {
      /// Throw Exception if something goes wrong.
      AtBotLogger.logln(LogTypeTag.error, e.toString());
    }
  });
}
