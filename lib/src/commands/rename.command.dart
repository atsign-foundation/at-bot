// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';

Future<void> onRenameCommand(
    nyxx.IMessageReceivedEvent event, List<String>? args) async {
  try {
    /// args is null or args length is not equal to 3, return.
    if (args == null) return;

    nyxx.IGuild? guild = event.message.guild?.getFromCache()!;
    if (args[0] != 'all') {
      nyxx.IMessage renameWaitingMsg =
          await event.message.channel.sendMessage(MessageContent.waiting);
      nyxx.IRole? role = event.message.roleMentions.first.getFromCache();
      nyxx.IGuildPreview wtf = await guild!.fetchGuildPreview();
      Stream<nyxx.IMember?> allMembers =
          guild.fetchMembers(limit: wtf.approxMemberCount);
      await allMembers.forEach((nyxx.IMember? mem) async {
        if (mem == null) {
          await event.message.channel
              .sendMessage(MessageContent.exception('Member is null.'));
          return;
        }
        if (!mem.user.getFromCache()!.bot) {
          if (mem.nickname != null) {
            for (nyxx.Cacheable<nyxx.Snowflake, nyxx.IRole> guildRole
                in mem.roles) {
              if (guildRole.getFromCache() == role) {
                await mem.removeRole(role!);
                await mem.edit(builder: nyxx.MemberBuilder()..nick = null);
              }
            }
          }
        }
      });

      /// delete waiting message.
      await renameWaitingMsg.delete();

      /// Send success message to the user.
      await logAndSendMessage(event, MessageContent.renameDone(),
          LogTypeTag.success, 'Renamed all the nick names.');
    } else if (args[0] == 'all') {}
  } catch (e) {
    /// Send Exception message to the user.
    await logAndSendMessage(
        event, MessageContent.exception(e), LogTypeTag.error, e.toString());
    return;
  }
}
