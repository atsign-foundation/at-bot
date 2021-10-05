// 📦 Package imports:
import 'package:dotenv/dotenv.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/interactions.dart';

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';

/// If the user accepts the role request, the bot will add the role to the user.
Future<void> onRoleRequestAccept(Guild guild, String id, Member mem, User user,
    Message invitationMsg, ButtonInteractionEvent event, Role? role) async {
  try {
    /// Get member nickname.
    String? memNickName = mem.nickname;

    /// If nickname is null, get user name.
    memNickName ??= user.username;

    /// Trim the role to first 3 letters of the role name.
    String roleNickName = role!.name.substring(0, 3).toUpperCase();

    /// If the member has already a nickname and it has `[something]`,
    /// replace that with ''.
    if (memNickName.contains(RegExp('/[(.*?)]/g'))) {
      memNickName.replaceAll(RegExp('/[(.*?)]/g'), '');
    }

    /// Adding member a role.
    await mem.addRole(role);

    /// Adding memeber a nickname.
    await mem.edit(nick: '[$roleNickName] $memNickName');

    /// Delete the request message.
    await invitationMsg.delete().then(
          /// Send thanking message.
          (_) async => event.interaction.message!.channel.sendMessage(
            MessageContent.custom(
              'Thanks for accepting the Request',
            ),
          ),
        );

    /// Log the user interaction.
    AtBotLogger.log(LogTypeTag.info,
        '${user.username} has accepted the ${role.name} role request.');

    /// Check for the moderator channel or bot channel.
    Iterable<GuildChannel> modChannel = guild.channels.where(
      (GuildChannel channel) =>
          (channel.id.toString() == env['mod_channel_id'] ||
              channel.id.toString() == env['bot_channel_id']),
    );

    /// If modChannel list is empty throw error in the console.
    if (modChannel.isEmpty) {
      AtBotLogger.log(
          LogTypeTag.info, 'Cannot find a moderator channel to initmate.');
      return;
    }

    /// Notify the mods about the user interaction.
    await (modChannel.first as TextChannel).sendMessage(
      MessageContent.custom(
          '**${user.username}** has accepted the **${role.name}** role request.'),
    );
  } catch (e) {
    /// Log the Exception.
    AtBotLogger.log(LogTypeTag.error, e.toString());
    return;
  }
}
