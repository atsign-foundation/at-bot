// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:at_bot/src/commands/music.command.dart';
import 'package:at_bot/src/utils/constants.util.dart';
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/commands/rename.command.dart';
import 'package:at_bot/src/commands/role.command.dart';
import 'package:at_bot/src/services/logs.dart';
import 'package:nyxx_lavalink/lavalink.dart';

/// Listening to every message in the guild.
Future<void> onMessageEvent(Nyxx? client, {Cluster? cluster}) async {
  try {
    /// Check if [client] is null.
    if (client == null) throw NullThrownError();

    /// Listening on message recived.
    client.onMessageReceived.listen((MessageReceivedEvent event) async {
      /// This makes your bot ignore other bots and itself
      /// and not get into a spam loop (we call that "botception").
      if (event.message.author.bot) return;

      /// Check if the message is a command.
      if (event.message.content.startsWith('!')) {
        /// Splitting the command to get the command name and the arguments.
        List<String>? commandList = event.message.content.split(' ');

        /// Getting the command name.
        String? command = commandList[0].substring(1);

        /// Getting the arguments.
        List<String>? arguments = commandList.sublist(1);

        /// Getting the command name.

        /// Check if the message is GuildMessage, if not, return null.
        /// else return the member.
        Member? member = event.message is GuildMessage ? (event.message as GuildMessage).member : null;

        /// Get the user permissions.
        Permissions? permissions = await member?.effectivePermissions;

        /// Get the command.
        switch (command.toLowerCase()) {

          /// Check if the command is a role command.
          case 'role':
            await onRoleCommand(event, arguments, permissions, client: client);
            break;

          /// Check if the command is ding ping.
          case 'rename':
            await onRenameCommand(event, arguments);
            break;

          /// Check if the command is ding ping.
          case 'music':
          case 'm':
            await onMusicCommand(event, arguments, cluster: cluster);
            break;
          case 'node':
            if (arguments.isEmpty) {
              await event.message.channel
                  .sendMessage(MessageContent.custom('Kill argument to kill the nodes (Not at all prefered).'));
            }
            if (arguments[0] == 'kill') {
              bool? nodesKilled = cluster?.connectedNodes.entries.any((MapEntry<int, Node> element) {
                element.value.disconnect();
                return true;
              });
              await event.message.channel
                  .sendMessage(MessageContent.custom(nodesKilled! ? 'Killed all nodes.' : 'Killed no nodes'));
            }
            break;

          /// Check if the command is unknown.
          default:
            await event.message.channel.sendMessage(MessageBuilder.content('Unknown command'));
            break;
        }
      }
    });
  } catch (e) {
    AtBotLogger.logln(LogTypeTag.error, e.toString());
    throw Exception(e.toString());
  }
}
