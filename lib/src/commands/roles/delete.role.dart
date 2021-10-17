// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';

/// Create new role for Guild.
Future<void> deleteNewRole(nyxx.MessageReceivedEvent event, nyxx.Guild guild, List<String>? args) async {
  try {
    nyxx.Role? role;
    if (args == null || args.length != 2) return;
    if ((args[1].startsWith('<@&') && args[1].endsWith('>'))) {
      role = (event.message as nyxx.GuildMessage).roleMentions.first.getFromCache();
    } else if (int.parse(args[1]) is int) {
      await event.message.channel.sendMessage(MessageContent.noIdPlease);
      return;
    }
    bool roleExists = guild.roles.find((nyxx.Role item) => role == item).isNotEmpty;

    if (roleExists) {
      /// Delete the role from the guild.
      await role!.delete();

      /// Send success message to the user.
      await logAndSendMessage(
          event, MessageContent.roleDeleted(role.name), LogTypeTag.success, 'Role ${role.name} deleted on request.');
    } else {
      await logAndSendMessage(event, MessageContent.custom('No such role found in guild to delete.'),
          LogTypeTag.warning, 'No such role found in guild to delete.  -by ${event.message.author.username}');
    }
  } catch (e) {
    /// Send Exception message to the user.
    await logAndSendMessage(event, MessageContent.exception(e), LogTypeTag.error, e.toString());
    return;
  }
}
