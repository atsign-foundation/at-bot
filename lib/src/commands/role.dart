// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/commands/roles/add_role.dart';
import 'package:at_bot/src/commands/roles/create_role.dart';
import 'package:at_bot/src/commands/roles/delete_role.dart';
import 'package:at_bot/src/commands/roles/remove_role.dart';
import 'package:at_bot/src/utils/constants.dart';

/// Listening to role command in the guild.
Future<void> onRoleCommand(nyxx.MessageReceivedEvent event, List<String>? args,
    nyxx.Permissions? permissions,
    {nyxx.Nyxx? client}) async {
  nyxx.Guild guild = (event.message as nyxx.GuildMessage).guild.getFromCache()!;
  if (permissions != null) {
    /// If user has permissions to use this command.
    if (permissions.administrator) {
      switch (args?.first) {
        case 'add':
          await addRoleToUser(event, guild, args);
          break;
        case 'remove':
          await removeRoleToUser(event, guild, args);
          break;
        case 'create':
          await createNewRole(event, guild, args);
          break;
        case 'delete':
          await deleteNewRole(event, guild, args);
          break;
        default:
      }
    } else

    /// If user has no permission to use this command.
    /// send a message to saying he/she needs to be admin to use this command.
    if (!permissions.administrator) {
      await event.message.channel.sendMessage(MessageContent.needToBeAdmin);
    }
  } else

  /// However if permissions is null, that means member might be null.
  /// So we check if the command is used in bot's inbox.
  if (event.message is nyxx.DMMessage) {
    /// Send message to the user.
    await event.message.channel.sendMessage(MessageContent.noDMs);
  }
}
