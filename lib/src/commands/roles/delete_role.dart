// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/utils/constants.dart';

/// Create new role for Guild.
Future<void> deleteNewRole(nyxx.MessageReceivedEvent event, nyxx.Guild guild,
    List<String>? args) async {
  try {
    nyxx.Role? role;
    if (args == null || args.length != 2) return;
    if ((args[1].startsWith('<@&') && args[1].endsWith('>'))) {
      role = (event.message as nyxx.GuildMessage)
          .roleMentions
          .first
          .getFromCache();
    } else if (int.parse(args[1]) is int) {
      await event.message.channel.sendMessage(MessageContent.noIdPlease);
      return;
    }

    /// Delete the role from the guild.
    await role!.delete();

    /// Send success message to the user.
    await event.message.channel
        .sendMessage(MessageContent.roleDeleted(role.name));
  } catch (e) {
    /// Send Exception message to the user.
    await event.message.channel.sendMessage(MessageContent.exception(e));
    return;
  }
}
