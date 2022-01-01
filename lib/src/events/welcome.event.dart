// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';

/// Listening to new user joining to the server.
Future<StreamSubscription<IGuildMemberAddEvent>> onMemberJoined(
    INyxxWebsocket? client) async {
  return client!.eventsWs.onGuildMemberAdd.listen(
      (IGuildMemberAddEvent event) async {
    /// Get user object
    IUser user = event.user;

    /// If user is a bot, return.
    if (user.bot) return;

    /// Get guild object
    IGuild guild = event.guild.getFromCache()!;
    try {
      ComponentMessageBuilder componentMessageBuilder =
          ComponentMessageBuilder();
      ComponentRowBuilder componentRow = ComponentRowBuilder()
        ..addComponent(
            ButtonBuilder('Accept', 'welcome_accept', ComponentStyle.success));
      componentMessageBuilder.addComponentRow(componentRow);

      /// Send member a welcome message to their inbox
      await user.sendMessage(
        MessageContent.custom(
          'Dear ${user.mention}, Welcome to **${guild.name}** Discord Community! To get started, We would love it if you can introduce yourself in the <#809591345801855038> channel and take a look at https://atsign.dev/ to get started if not already. If you have any Qs, please ping one of us from The @ Co. Don\'t forget to get an atsign 😉.',
        ),
      );
      await user.sendMessage(componentMessageBuilder
        ..content =
            'Please go through <#778383211712741457> channel and accepet the Rules and Conditions 😀.');
    } catch (e) {
      /// Print error to console and throw Exception.
      AtBotLogger.logln(LogTypeTag.error, e.toString());
      throw Exception(e);
    }
  }, onError: (Object e) {
    /// Print error to console and throw Exception.
    AtBotLogger.logln(LogTypeTag.error, e.toString());
    throw Exception(e);
  });
}
