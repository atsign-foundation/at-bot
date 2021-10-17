// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:nyxx/nyxx.dart' as nyxx;

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';

Future<void> onRenameCommand(nyxx.MessageReceivedEvent event, List<String>? args) async {
  try {
    /// args is null or args length is not equal to 3, return.
    if (args == null) return;

    nyxx.Guild? guild = (event.message as nyxx.GuildMessage).guild.getFromCache()!;
    if (args[0] != 'all') {
      nyxx.Message renameWaitingMsg = await event.message.channel.sendMessage(MessageContent.waiting);
      nyxx.Role? role = (event.message as nyxx.GuildMessage).roleMentions.first.getFromCache();
      nyxx.GuildPreview wtf = await guild.fetchGuildPreview();
      Stream<nyxx.Member?> allMembers = guild.fetchMembers(limit: wtf.approxMemberCount);
      await allMembers.forEach((nyxx.Member? mem) async {
        if (mem == null) {
          await event.message.channel.sendMessage(MessageContent.exception('Member is null.'));
          return;
        }
        if (!mem.user.getFromCache()!.bot) {
          if (mem.nickname != null) {
            for (nyxx.Cacheable<nyxx.Snowflake, nyxx.Role> guildRole in mem.roles) {
              if (guildRole.getFromCache() == role) {
                await mem.removeRole(role!);
                await mem.edit(nick: null);
              }
            }
          }
        }
      });

      /// delete waiting message.
      await renameWaitingMsg.delete();

      /// Send success message to the user.
      await logAndSendMessage(event, MessageContent.renameDone(), LogTypeTag.success, 'Renamed all the nick names.');
    } else if (args[0] == 'all') {}
  } catch (e) {
    /// Send Exception message to the user.
    await logAndSendMessage(event, MessageContent.exception(e), LogTypeTag.error, e.toString());
    return;
  }
}
