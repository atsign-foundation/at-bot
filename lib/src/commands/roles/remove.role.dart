// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';

/// Add a new role to the user.
Future<void> removeRoleToUser(nyxx.MessageReceivedEvent event, nyxx.Guild guild, List<String>? args) async {
  nyxx.Role? role;
  nyxx.User? user;
  try {
    /// args is null or args length is not equal to 3, return.
    if (args == null || args.length != 3) {
      /// Send message to the user.
      await event.message.channel
          .sendMessage(nyxx.MessageBuilder.content('Missing some arguments. Try !role help command.'));
      return;
    }

    /// Check if the user mention is starting and ending with '<@!' and '>'.
    /// Get the user [SnowFlake] from the mention.
    if (args[1].startsWith('<@!') && args[1].endsWith('>')) {
      user = (event.message as nyxx.GuildMessage).mentions.first.getFromCache();
    } else if (int.parse(args[1]) is int) {
      await event.message.channel.sendMessage(MessageContent.noIdPlease);
      return;
    }

    /// Check if the role mention is starting and ending with '<@&' and '>'.
    /// Get the role as [SnowFlakeEntity] from the mention.
    if (args[2].startsWith('<@&') && args[2].endsWith('>')) {
      role = (event.message as nyxx.GuildMessage).roleMentions.first.getFromCache();
    } else if (int.parse(args[2]) is int) {
      await event.message.channel.sendMessage(MessageContent.noIdPlease);
      return;
    }

    /// Fetch the member from the guild.
    nyxx.Member member = await guild.fetchMember(user!.id);

    bool userHasRole =
        member.roles.where((nyxx.Cacheable<nyxx.Snowflake, nyxx.Role> element) => element.id == role!.id).isNotEmpty;

    /// Get member nickname.
    String? memNickName = member.nickname;

    /// If nickname is null, get user name.
    memNickName = Constants.removeStuff(memNickName ?? user.username);

    if (userHasRole) {
      /// Remove the role from the member.
      await member.removeRole(role!);

      /// reset the member nickname.
      await member.edit(nick: memNickName);

      await logAndSendMessage(
          event,
          MessageContent.roleRemoved(
            roleName: role.name,
            userName: user.username,
          ),
          LogTypeTag.success,
          'Removed ${role.name} role for ${user.username}.  -by ${event.message.author.username}');
    } else {
      /// Send message in the channel stating there no role assigned for the member.
      await logAndSendMessage(event, MessageContent.custom('No role found in role list of ${user.username}.'),
          LogTypeTag.warning, 'No role found in role list of ${user.username}.  -by ${event.message.author.username}');
    }
  } catch (e) {
    /// Send Exception message to the user.
    await event.message.channel.sendMessage(MessageContent.exception(e));

    /// Log the error.
    AtBotLogger.logln(LogTypeTag.error, e.toString());
  }
}
