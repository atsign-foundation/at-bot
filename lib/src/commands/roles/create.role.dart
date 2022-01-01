// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';

/// Create new role for Guild.
Future<void> createNewRole(nyxx.IMessageReceivedEvent event, nyxx.IGuild guild,
    List<String>? args) async {
  try {
    /// args is null or args length is not equal to 3, return.
    if (args == null || args.length != 3) return;

    /// Check if Role exists.
    bool roleExists = guild.roles.containsKey(args[1]);
    if (roleExists) {
      /// Create a role in the guild.
      nyxx.IRole role = await guild.createRole(
          nyxx.RoleBuilder(args[1])..color = Constants.colors[args[2]]);

      /// Send success message to the user.
      await logAndSendMessage(
          event,
          MessageContent.roleCreated(role.name),
          LogTypeTag.warning,
          'Role ${role.name} created on request.  -by ${event.message.author.username}');
    } else {
      /// Send error message to the user.
      await logAndSendMessage(
          event,
          MessageContent.custom('`${args[1]}` already exist in the server.'),
          LogTypeTag.warning,
          '${args[1]} already exist in the server.  -by ${event.message.author.username}');
    }
  } catch (e) {
    /// Send Exception message to the user.
    await event.message.channel.sendMessage(MessageContent.exception(e));
    return;
  }
}
