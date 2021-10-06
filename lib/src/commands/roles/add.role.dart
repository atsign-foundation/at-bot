// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/utils/constants.util.dart';

/// Add a new role to the user.
Future<void> addRoleToUser(nyxx.MessageReceivedEvent event, nyxx.Guild guild,
    List<String>? args) async {
  nyxx.Role? role;
  nyxx.User? user;
  RegExp _regExp = RegExp(r'\[\S*\] ');
  String removeStuff(String input) => input.replaceAll(_regExp, '');
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
      user = await (event.message as nyxx.GuildMessage)
          .mentions
          .first
          .getOrDownload();
    } else if (int.parse(args[1]) is int) {
      await event.message.channel.sendMessage(MessageContent.noIdPlease);
      return;
    }

    /// Check if the role mention is starting and ending with '<@&' and '>'.
    /// Get the role as [SnowFlakeEntity] from the mention.
    if (args[2].startsWith('<@&') && args[2].endsWith('>')) {
      role = (event.message as nyxx.GuildMessage)
          .roleMentions
          .first
          .getFromCache();
    } else if (int.parse(args[2]) is int) {
      await event.message.channel.sendMessage(MessageContent.noIdPlease);
      return;
    }

    /// Fetch the member from the guild.
    nyxx.Member member = await guild.fetchMember(user!.id);

    /// Get member nickname.
    String? memNickName = member.nickname;

    /// If nickname is null, get user name.
    memNickName ??= user.username;

    /// Trim the role to first 3 letters of the role name.
    String roleNickName = role!.name.substring(0, 3).toUpperCase();

    /// If the member has already a nickname and it has `[something]`,
    /// replace that with ''.
    memNickName = removeStuff(memNickName);

    /// Remove the role from the member.
    await member.addRole(role);

    await member.edit(nick: '[$roleNickName] $memNickName');

    /// Send user a message to inbox.
    await user.sendMessage(MessageContent.roleAdded(
      roleName: role.name,
      userName: user.username,
    ));

    /// Send success message to the user.
    await event.message.channel.sendMessage(MessageContent.roleAdded(
      roleName: role.name,
      userName: user.username,
    ));
  } catch (e) {
    /// Send Exception message to the user.
    await event.message.channel.sendMessage(MessageContent.exception(e));
  }
}
