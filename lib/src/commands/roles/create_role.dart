// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/utils/constants.dart';

/// Create new role for Guild.
Future<void> createNewRole(nyxx.MessageReceivedEvent event, nyxx.Guild guild,
    List<String>? args) async {
  try {
    /// args is null or args length is not equal to 3, return.
    if (args == null || args.length != 3) return;

    /// Create a role in the guild.
    nyxx.Role role = await guild.createRole(
        nyxx.RoleBuilder(args[1])..color = Constants.colors[args[2]]);

    /// Send success message to the user.
    await event.message.channel
        .sendMessage(MessageContent.roleCreated(role.name));
  } catch (e) {
    /// Send Exception message to the user.
    await event.message.channel.sendMessage(MessageContent.exception(e));
    return;
  }
}
