// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/commands/role.dart';
import 'package:at_bot/src/utils/custom_print.dart';

/// Listening to every message in the guild.
Future<StreamSubscription<MessageReceivedEvent>> onMessageEvent(
    Nyxx? client) async {
  try {
    /// Check if [client] is null.
    if (client == null) throw NullThrownError();

    /// Listening on message recived.
    return client.onMessageReceived.listen((MessageReceivedEvent event) async {
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
        Member? member = event.message is GuildMessage
            ? (event.message as GuildMessage).member
            : null;

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
            await onRenameCommand(event);
            break;

          /// Check if the command is unknown.
          default:
            await event.message.channel
                .sendMessage(MessageBuilder.content('Unknown command'));
            break;
        }
      }
    });
  } catch (e) {
    printError(e.toString());
    throw Exception(e.toString());
  }
}

Future<Message> onRenameCommand(MessageReceivedEvent event) {
  return event.message.channel.sendMessage(MessageBuilder.content('Dong!'));
}
