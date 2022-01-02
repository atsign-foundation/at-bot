import 'package:at_bot/src/services/get_atsign.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';
import 'package:at_bot/src/utils/constants.util.dart' as consts;

class AtSignService {
  // create singleton
  factory AtSignService() {
    return _singleton;
  }
  AtSignService._internal();
  static Future<void> validateEmail(
      List<String> arguments, IMessageReceivedEvent event) async {
    bool registered =
        await AtSignAPI.registerAtSign(arguments[0], arguments[1]);
    await event.message.channel.sendMessage(
      consts.MessageContent.custom(
        registered
            ? '***`${arguments[1]}`*** is registered on your email successfully.'
            : 'Sorry, Failed to register ***`${arguments[1]}`*** on your email.',
      ),
    );
    await event.message.channel.sendMessage(
      consts.MessageContent.custom(
        'OTP will be sent to your mail shortly.\nUse `!otp <@sign> <email> <OTP>` to verify your email.',
      ),
    );
  }

  static String? formatAtSign(String? atsign) {
    if (atsign == null || atsign == '') {
      return null;
    }
    atsign = atsign.trim().toLowerCase().replaceAll(' ', '');
    atsign = !atsign.startsWith('@') ? '@' + atsign : atsign;
    return atsign;
  }

  static Future<void> validatingOTP(
      IMessageReceivedEvent event, List<String> arguments) async {
    if (arguments.length < 3 &&
        consts.Constants.emailRegExp.hasMatch(arguments[1])) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          '@ Looks like you are missing @sign.',
        ),
      );
      return;
    } else if (arguments[2].length != 4) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          '🔐 OTP is invalid.',
        ),
      );
      return;
    } else if (!consts.Constants.emailRegExp.hasMatch(arguments[1])) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          '📨 Email is invalid.',
        ),
      );
      return;
    }
    Map<String, dynamic> data = await AtSignAPI.validatingOTP(
      arguments[0],
      arguments[1].toLowerCase(),
      arguments[2].toUpperCase(),
    );
    if (data['data']['atsigns'].length == 10) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          data['data']['message'],
        ),
      );
      return;
    } else if (data['data']['newAtsign'] != null) {
      Map<String, dynamic> confirmationData = await AtSignAPI.validatingOTP(
        arguments[0],
        arguments[1].toLowerCase(),
        arguments[2].toUpperCase(),
        confirmation: true,
      );
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          confirmationData.containsKey('cramkey')
              ? 'Your @sign verification passed 🎉.'
              : 'Your @sign verification failed ❌',
        ),
      );
    }
    return;
  }

  static Future<void> getRootStatus(
      IMessageReceivedEvent event, List<String> arguments) async {
    if (event.message.guild != null) {
      event.message.channel.startTypingLoop();
      MessageBuilder statusBuilder = MessageBuilder();
      AtStatus? status = await AtSignAPI.checkAtSignServerStatus(arguments[0]);
      print(status?.status());
      event.message.channel.stopTypingLoop();
      statusBuilder.addEmbed((EmbedBuilder embed) {
        embed
          ..title = 'Root Status'
          ..description =
              '**Root status is :** ${status?.rootStatus?.name.toUpperCase()}'
          ..color = status?.rootStatus?.name == 'found'
              ? DiscordColor.green
              : DiscordColor.red
          ..addField(
            name: '@Sign :',
            content: status?.atSign?.replaceAll('@', ''),
          )
          ..addField(
            name: '@Sign status :',
            content: status?.atSignStatus?.name.toUpperCase(),
          )
          ..addField(
            name: 'Server location :',
            content: status?.serverLocation,
          )
          ..addField(
            name: 'Server Status :',
            content: status?.serverStatus?.name.toUpperCase(),
          )
          ..addFooter((EmbedFooterBuilder footer) {
            footer.text = 'By ' + event.message.author.username;
            footer.iconUrl = event.message.author.avatarURL();
          })
          ..timestamp = DateTime.now();
      });
      await event.message.channel.sendMessage(statusBuilder);
    }
    return;
  }

  static final AtSignService _singleton = AtSignService._internal();
  static Future<void> getAtSignStatus(
      IMessageReceivedEvent event, List<String> arguments) async {
    event.message.channel.startTypingLoop();
    AtSignStatus? status = await AtSignAPI.checkAtsignStatus(arguments[0]);
    event.message.channel.stopTypingLoop();
    MessageBuilder builder = MessageBuilder();
    builder.addEmbed((EmbedBuilder embed) {
      embed
        ..title = '@Sign Status'
        ..description =
            '***`${arguments[0]}`*** status is : ${status?.name.toUpperCase()}'
        ..color = status?.name == 'activated'
            ? DiscordColor.green
            : status?.name == 'teapot'
                ? DiscordColor.orange
                : DiscordColor.red
        ..addFooter((EmbedFooterBuilder footer) {
          footer.text = 'By ' + event.message.author.username;
          footer.iconUrl = event.message.author.avatarURL();
        })
        ..timestamp = DateTime.now();
    });
    await event.message.channel.sendMessage(builder);
    return;
  }

  static Future<void> getUserAtSign(IMessageReceivedEvent event) async {
    ComponentMessageBuilder componentMessageBuilder = ComponentMessageBuilder();
    ComponentRowBuilder componentRow = ComponentRowBuilder()
      ..addComponent(ButtonBuilder(
          'Get Random @Sign', 'singleAtSign', ComponentStyle.primary));
    // ..addComponent(ButtonBuilder(
    //     'Give me options', 'multiAtSigns', ComponentStyle.secondary));
    IUser? user = event.message.member?.user.getFromCache();
    if (user == null) {
      await event.message.channel
          .sendMessage(consts.MessageContent.custom('User not found'));
      return;
    } else {
      componentMessageBuilder.addComponentRow(componentRow);
      await user.sendMessage(componentMessageBuilder
        ..content =
            'Hey ${user.username}, We got a request from you for a new atsign.\nYou need options or get a random one?');
      return;
    }
  }
}
