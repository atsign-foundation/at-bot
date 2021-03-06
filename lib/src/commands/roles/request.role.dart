// 📦 Package imports:
// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';
import 'package:nyxx/nyxx.dart' as nyxx;
import 'package:nyxx_interactions/nyxx_interactions.dart';

Future<void> requestRoleToUser(nyxx.IMessageReceivedEvent event,
    nyxx.IGuild guild, List<String>? args) async {
  nyxx.IRole? role;
  nyxx.IUser? user;
  try {
    ComponentMessageBuilder componentMessageBuilder = ComponentMessageBuilder();

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
    nyxx.IMember member = await guild.fetchMember(user!.id);
    bool userHasRole = member.roles
        .where((nyxx.Cacheable<nyxx.Snowflake, nyxx.IRole> element) =>
            element.id == role!.id)
        .isNotEmpty;
    // / Fetch the member from the guild.
    // nyxx.Member member = await guild.fetchMember(user!.id);
    ComponentRowBuilder componentRow = ComponentRowBuilder()
      ..addComponent(ButtonBuilder(
          'Accept', 'req_${role!.id}_accept', nyxx.ButtonStyle.primary))
      ..addComponent(ButtonBuilder(
          'Reject', 'req_${role.id}_reject', nyxx.ButtonStyle.danger));
    componentMessageBuilder.addComponentRow(componentRow);

    /// Remove the role from the member.u
    // await member.addRole(role!);
    if (userHasRole) {
      await logAndSendMessage(
        event,
        MessageContent.custom(
            'Oopps... Looks like user `${user.username}` already have `${role.name}` role.'),
        LogTypeTag.warning,
        'Oopps... Looks like user `${user.username}` already have `${role.name}` role.  -by ${event.message.author.username}',
      );
      return;
    } else {
      await user.sendMessage(componentMessageBuilder
        ..content = 'Admin has requested you to join **${role.name}** role.');
      await logAndSendMessage(
        event,
        MessageContent.custom(
            'Request sent to `${user.username}` to join as `${role.name}`.'),
        LogTypeTag.info,
        'Request sent to `${user.username}` to join as `${role.name}`.  -by ${event.message.author.username}',
      );
    }
  } catch (e) {
    /// Send Exception message to the user.
    await event.message.channel.sendMessage(MessageContent.exception(e));
  }
}
