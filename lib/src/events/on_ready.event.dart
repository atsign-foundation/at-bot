// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';

// 🌎 Project imports:

/// On bot ready Do what ever you want 😎.
Future<void> onReadyEvent(INyxxWebsocket? client) async {
  client!.eventsWs.onReady.listen((_) async {
    try {
      /// Set the bot activity to listening.
      client.setPresence(
        PresenceBuilder.of(
          status: UserStatus.online,
          activity: ActivityBuilder.listening('@signs')
            ..url = 'https://atsign.com/',
        ),
      );
      AtBotLogger.logln(
          LogTypeTag.success, '${client.self.tag} is ready to go 🔥');
    } catch (e) {
      /// Throw Exception if something goes wrong.
      AtBotLogger.logln(LogTypeTag.error, e.toString());
    }
  })
    ..onDone(() {
      AtBotLogger.logln(LogTypeTag.info, '${client.self.tag} is offline 💤');
    })
    ..onError((Object e, StackTrace s) => AtBotLogger.logln(
        LogTypeTag.error, '${client.self.tag} is offline 💤'));
}
