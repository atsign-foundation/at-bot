// 📦 Package imports:
import 'package:dotenv/dotenv.dart';
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';

/// If the user accepts the role request, the bot will add the role to the user.
Future<void> onRoleRequestAccept(
    nyxx.IGuild guild,
    String id,
    nyxx.IMember mem,
    nyxx.IUser user,
    nyxx.IMessage invitationMsg,
    IButtonInteractionEvent event,
    nyxx.IRole? role) async {
  try {
    /// Get member nickname.
    String? memNickName = mem.nickname;

    /// If nickname is null, get user name.
    memNickName ??= user.username;

    /// Trim the role to first 3 letters of the role name.
    String roleNickName = role!.name.substring(0, 3).toUpperCase();

    /// If the member has already a nickname and it has `[something]`,
    /// replace that with ''.
    memNickName = Constants.removeStuff(memNickName);
    bool userHasRole = mem.roles
        .where((nyxx.Cacheable<nyxx.Snowflake, nyxx.IRole> element) =>
            element.id == role.id)
        .isNotEmpty;

    /// Check for the moderator channel or bot channel.
    Iterable<nyxx.IGuildChannel> modChannel = guild.channels.where(
      (nyxx.IGuildChannel channel) =>
          (channel.id.toString() == env['mod_channel_id'] ||
              channel.id.toString() == env['bot_channel_id']),
    );

    if (userHasRole) {
      if (modChannel.isEmpty) {
        AtBotLogger.logln(LogTypeTag.warning,
            '${user.username} already has ${role.name} role.');

        /// Delete the request message.
        await invitationMsg.delete().then(
              /// Send thanking message.
              (_) async => event.interaction.message!.channel.sendMessage(
                MessageContent.custom(
                  'Sorry, Looks like you already have this role. Admin might got confused.',
                ),
              ),
            );
        return;
      } else {
        /// Notify the mods about the user interaction.
        if (event.interaction.customId.startsWith('req_')) {
          await (modChannel.first as nyxx.ITextChannel).sendMessage(
            MessageContent.custom(
                '**${user.username}** already has **${role.name}** role.'),
          );
          AtBotLogger.logln(LogTypeTag.warning,
              '${user.username} already has ${role.name} role. ');
        }

        /// Delete the request message.
        await invitationMsg.delete().then(
              /// Send thanking message.
              (_) async => event.interaction.message!.channel.sendMessage(
                MessageContent.custom(
                  'Sorry, Looks like you already have this role. Admin might got confused.',
                ),
              ),
            );
      }
    } else {
      /// Adding member a role.
      await mem.addRole(role);

      /// Delete the request message.
      await invitationMsg.delete().then(
            /// Send thanking message.
            (_) async => event.interaction.message!.channel.sendMessage(
              MessageContent.custom(
                'Thanks for accepting the Request',
              ),
            ),
          );

      /// If modChannel list is empty throw error in the console.
      if (modChannel.isEmpty) {
        AtBotLogger.logln(
            LogTypeTag.info, 'Cannot find a moderator channel to initmate.');
        return;
      } else {
        /// Notify the mods about the user interaction.
        if (event.interaction.customId.startsWith('req_')) {
          /// Adding memeber a nickname.
          await mem.edit(
              builder: nyxx.MemberBuilder()
                ..nick = '[$roleNickName] $memNickName');
          await (modChannel.first as nyxx.ITextChannel).sendMessage(
            MessageContent.custom(
                '**${user.username}** has accepted the **${role.name}** role request.'),
          );

          /// Log the user interaction.
          AtBotLogger.logln(LogTypeTag.info,
              '${user.username} has accepted the ${role.name} role request.');
        }
      }
    }
  } catch (e) {
    /// Log the Exception.
    AtBotLogger.logln(LogTypeTag.error, e.toString());
    return;
  }
}
