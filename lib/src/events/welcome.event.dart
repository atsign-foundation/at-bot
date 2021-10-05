// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';

/// Listening to new user joining to the server.
Future<StreamSubscription<GuildMemberAddEvent>> onMemberJoined(
    Nyxx? client) async {
  return client!.onGuildMemberAdd.listen((GuildMemberAddEvent event) async {
    /// Get user object
    User user = event.user;

    /// If user is a bot, return.
    if (user.bot) return;

    /// Get guild object
    Guild guild = event.guild.getFromCache()!;
    try {
      /// Send member a welcome message to their inbox
      await user.sendMessage(MessageContent.welcome(user, guild));
    } catch (e) {
      /// Print error to console and throw Exception.
      AtBotLogger.log(LogTypeTag.error, e.toString());
      throw Exception(e);
    }
  }, onError: (Object e) {
    /// Print error to console and throw Exception.
    AtBotLogger.log(LogTypeTag.error, e.toString());
    throw Exception(e);
  });
}
