// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/utils/custom_print.dart';

/// On bot ready Do what ever you want 😎.
StreamSubscription<ReadyEvent> onReadyEvent(Nyxx? client) {
  return client!.onReady.listen((_) {
    try {
      /// Set the bot activity to listening.
      client.setPresence(
        PresenceBuilder.of(
          status: UserStatus.online,
          activity: ActivityBuilder.listening('@signs'),
        ),
      );
      printSuccess('${client.self.tag} is ready to go 🔥');
    } catch (e) {
      /// Throw Exception if something goes wrong.
      throw Exception('Error on ready event : ${e.toString()}');
    }
  });
}
