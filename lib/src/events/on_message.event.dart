// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:at_bot/src/services/atsign.service.dart';
import 'package:at_bot/src/utils/constants.util.dart' as consts;
import 'package:at_bot/src/utils/provider.util.dart';
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/commands/rename.command.dart';
import 'package:at_bot/src/commands/role.command.dart';
import 'package:at_bot/src/services/logs.dart';
import 'package:riverpod/riverpod.dart';

/// Listening to every message in the guild.
Future<void> onMessageEvent(INyxxWebsocket? client,
    {required ProviderContainer container}) async {
  try {
    /// Check if [client] is null.
    if (client == null) throw NullThrownError();

    /// Listening on message recived.
    client.eventsWs.onMessageReceived
        .listen((IMessageReceivedEvent event) async {
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
        IMember? member =
            event.message.guild != null ? event.message.member : null;

        /// Get the user permissions.
        IPermissions? permissions = await member?.effectivePermissions;

        /// Get the command.
        switch (command.toLowerCase()) {

          /// Check if the command is a role command.
          case consts.Commands.role:
            await onRoleCommand(event, arguments, permissions, client: client);
            break;

          /// Check if the command is ding ping.
          case consts.Commands.rename:
            await onRenameCommand(event, arguments);
            break;

          /// Check if the command is ding ping.
          case consts.Commands.getAtSign:
            if (arguments[0].toLowerCase() == '@sign' ||
                arguments[0].toLowerCase() == 'dev@sign') {
              container.read(isDev.state).state =
                  arguments[0].toLowerCase().contains('dev');
              await AtSignService.getUserAtSign(event);
              return;
            } else {
              break;
            }
          case 'email':
          case 'devemail':
            container.read(isDev.state).state =
                command.toLowerCase() == 'devemail';
            await AtSignService.validateEmail(arguments, event,
                container: container);
            return;
          case 'status':
          case 'devstatus':
            container.read(isDev.state).state =
                command.toLowerCase() == 'devstatus';
            await AtSignService.getAtSignStatus(event, arguments, container);
            return;
          case 'rootstatus':
          case 'devrootstatus':
            container.read(isDev.state).state =
                command.toLowerCase() == 'devrootstatus';
            await AtSignService.getRootStatus(event, arguments, container);
            return;
          case 'otp':
          case 'devotp':
            container.read(isDev.state).state =
                command.toLowerCase() == 'devotp';
            await AtSignService.validatingOTP(event, arguments,
                container: container);
            return;
          case 'check':
          case 'devcheck':
            container.read(isDev.state).state =
                command.toLowerCase() == 'devcheck';
            await AtSignService.validatingOTP(event, arguments,
                container: container);
            return;

          /// Check if the command is unknown.
          default:
            await event.message.channel
                .sendMessage(MessageBuilder.content('Unknown command'));
            break;
        }
      }
    });
  } catch (e) {
    AtBotLogger.logln(LogTypeTag.error, e.toString());
    throw Exception(e.toString());
  }
}
