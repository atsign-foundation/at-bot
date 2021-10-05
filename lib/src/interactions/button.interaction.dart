// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:dotenv/dotenv.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/interactions.dart';

// 🌎 Project imports:
import 'package:at_bot/src/interactions/role.interaction.dart';
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';

Future<void> buttonInteraction(ButtonInteractionEvent event) async {
  try {
    /// Get the interaction ID
    String id = event.interaction.customId;

    /// Get the action.
    /// EG: req for request role.
    String action = id.split('_')[0];

    /// If action is role request
    if (action == 'req') {
      /// get the role ID from button ID
      String btnRoleID = id.split('_')[1];

      /// Get the Guild ID
      Guild? guild = event.interaction.message!.client.guilds.first;

      /// Get the role from the guild.
      Role? role = guild!.roles.findOne(
          (Role? item) => (item!.id.toString().compareTo(btnRoleID) == 0));

      /// If role ID from button ID matches with role ID
      if (btnRoleID == role!.id.toString()) {
        /// get the interacted button.
        String userInteraction = id.split('_')[2];

        /// Fetch the member from the guild.
        Member mem = await guild.fetchMember(event.interaction.userAuthor!.id);

        /// Fetch the user from the member.
        User? user = mem.user.getFromCache();

        /// User interacted message.
        Message? invitationMsg = event.interaction.message;

        /// If the interaction type is accept.
        if (userInteraction == 'accept') {
          await onRoleRequestAccept(
              guild, id, mem, user!, invitationMsg!, event, role);
        } else

        /// If the interaction type is reject.
        {
          /// Delete the interaction message and reply with Thanks.
          await invitationMsg!.delete().then(
                (_) async => event.interaction.message!.channel.sendMessage(
                  MessageContent.custom('Thanks for your the response.'),
                ),
              );

          /// Try getting a moderator/bots channel.
          Iterable<GuildChannel> modChannel = guild.channels.where(
            (GuildChannel channel) =>
                (channel.id.toString() == env['mod_channel_id'] ||
                    channel.id.toString() == env['bot_channel_id']),
          );

          /// Log the user interaction.
          AtBotLogger.log(LogTypeTag.info,
              '${user!.username} has rejected the ${role.name} role request.');

          /// If modChannel is empty.
          if (modChannel.isEmpty) {
            AtBotLogger.log(LogTypeTag.info,
                'Cannot find a moderator channel to initmate.');
            return;
          }

          /// Notify the moderators about user interaction.
          await (modChannel.first as TextChannel).sendMessage(
            MessageContent.custom(
                '**${user.username}** has rejected the **${role.name}** role request.'),
          );
        }
      }
    }
  } catch (e) {
    AtBotLogger.log(LogTypeTag.error, e.toString());
    return;
  }
}
