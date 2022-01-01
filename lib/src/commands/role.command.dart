// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/commands/roles/add.role.dart';
import 'package:at_bot/src/commands/roles/create.role.dart';
import 'package:at_bot/src/commands/roles/delete.role.dart';
import 'package:at_bot/src/commands/roles/remove.role.dart';
import 'package:at_bot/src/commands/roles/request.role.dart';
import 'package:at_bot/src/utils/constants.util.dart';

/// Listening to role command in the guild.
Future<void> onRoleCommand(nyxx.IMessageReceivedEvent event, List<String>? args,
    nyxx.IPermissions? permissions,
    {nyxx.INyxxWebsocket? client}) async {
  nyxx.IGuild guild = event.message.guild!.getFromCache()!;
  if (permissions != null) {
    /// If user has permissions to use this command.
    if (permissions.administrator) {
      switch (args?.first) {
        case 'add':
          await addRoleToUser(event, guild, args);
          break;
        case 'create':
          await createNewRole(event, guild, args);
          break;
        case 'delete':
          await deleteNewRole(event, guild, args);
          break;
        case 'remove':
          await removeRoleToUser(event, guild, args);
          break;
        case 'request':
          await requestRoleToUser(event, guild, args);
          break;
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
  if (event.message.guild == null) {
    /// Send message to the user.
    await event.message.channel.sendMessage(MessageContent.noDMs);
  }
}
