// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/utils/custom_print.dart';

/// Listening to every message in the guild.
Future<StreamSubscription<MessageReceivedEvent>> onMessageEvent(Nyxx? client) async {
  try {
    /// Check if [client] is null.
    if (client == null) throw NullThrownError();
    return client.onMessageReceived.listen((MessageReceivedEvent event) async {
      if (event.message.content == '!ping') {
        await event.message.channel.sendMessage(MessageBuilder.content('Pong!'));
      }
    });
  } catch (e) {
    printError(e.toString());
    throw Exception(e.toString());
  }
}
