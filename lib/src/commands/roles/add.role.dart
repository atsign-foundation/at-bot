// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';

/// Add a new role to the user.
Future<void> addRoleToUser(nyxx.IMessageReceivedEvent event, nyxx.IGuild guild,
    List<String>? args) async {
  nyxx.IRole? role;
  nyxx.IUser? user;
  try {
    /// Removing unwanted white spaces.
    args!.removeWhere((String element) => element.isEmpty);

    /// args is null or args length is not equal to 3, return.
    if (args.isEmpty || args.length != 3) {
      /// Send message to the user.
      await event.message.channel.sendMessage(nyxx.MessageBuilder.content(
          'Missing some arguments. Try !role help command.'));
      return;
    }

    /// Check if the user mention is starting and ending with '<@!' and '>'.
    /// Get the user [SnowFlake] from the mention.
    if (args[1].startsWith('<@!') && args[1].endsWith('>')) {
      user = await event.message.mentions.first.getOrDownload();
    } else if (int.tryParse(args[1]) is int) {
      await event.message.channel.sendMessage(MessageContent.noIdPlease);
      return;
    }

    /// Check if the role mention is starting and ending with '<@&' and '>'.
    /// Get the role as [SnowFlakeEntity] from the mention.
    if (args[2].startsWith('<@&') && args[2].endsWith('>')) {
      role = event.message.roleMentions.first.getFromCache();
    } else if (int.tryParse(args[2]) is int) {
      await event.message.channel.sendMessage(MessageContent.noIdPlease);
      return;
    }

    /// Fetch the member from the guild.
    nyxx.IMember member = await guild.fetchMember(user!.id);

    /// Get member nickname.
    String? memNickName = member.nickname;

    /// If nickname is null, get user name.
    memNickName ??= user.username;

    /// Trim the role to first 3 letters of the role name.
    String roleNickName = role!.name.substring(0, 3).toUpperCase();
    bool userHasRole = member.roles
        .where((nyxx.Cacheable<nyxx.Snowflake, nyxx.IRole> element) =>
            element.id == role!.id)
        .isNotEmpty;

    if (!userHasRole) {
      /// If the member has already a nickname and it has `[something]`,
      /// replace that with ''.
      memNickName = Constants.removeStuff(memNickName);

      /// Remove the role from the member.
      await member.addRole(role);

      await member.edit(
          builder: nyxx.MemberBuilder()..nick = '[$roleNickName] $memNickName');

      /// Send user a message to inbox.
      await user.sendMessage(MessageContent.custom(
          '${role.name} has been added to you in ${guild.name}.'));

      /// Send success message to the user.
      await logAndSendMessage(
          event,
          MessageContent.roleAdded(
            roleName: role.name,
            userName: user.username,
          ),
          LogTypeTag.success,
          'Role ${role.name} added to ${user.username}.  -by ${event.message.author.username}');
    } else {
      /// Send message in the channel stating there no role assigned for the member.
      await logAndSendMessage(
          event,
          MessageContent.custom('${user.username} already has this role.'),
          LogTypeTag.warning,
          '${user.username} already has this role  -by ${event.message.author.username}');
    }
  } catch (e) {
    /// Send Exception message to the user.
    await event.message.channel.sendMessage(MessageContent.exception(e));
  }
}
