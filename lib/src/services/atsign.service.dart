import 'dart:io';

import 'package:at_bot/src/services/get_atsign.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:nyxx/nyxx.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx_interactions/nyxx_interactions.dart';
import 'package:at_bot/src/utils/constants.util.dart' as consts;

class AtSignService {
  // create singleton
  factory AtSignService() {
    return _singleton;
  }
  AtSignService._internal();
  static final AtSignService _singleton = AtSignService._internal();

  static Future<void> validateEmail(
      List<String> arguments, IMessageReceivedEvent event) async {
    event.message.channel.startTypingLoop();
    if (arguments.isEmpty) {
      await event.message.channel.sendMessage(
          consts.MessageContent.custom('Please provide an email address'));
      event.message.channel.stopTypingLoop();
      return;
    }
    if (arguments.length == 1) {
      if (arguments[0] == 'help') {
        await event.message.channel.sendMessage(
          consts.MessageContent.custom(
            'Use `!email <email> <@sign>` command to register the @sign with you email.',
          ),
        );
        event.message.channel.stopTypingLoop();
        return;
      } else {
        await event.message.channel.sendMessage(
          consts.MessageContent.custom(
            consts.Constants.emailRegExp.hasMatch(arguments[0])
                ? 'Looks like you are missing @sign.'
                : 'Looks like you are missing your email.',
          ),
        );
        event.message.channel.stopTypingLoop();
        return;
      }
    } else if (arguments.length == 2 &&
        !consts.Constants.emailRegExp.hasMatch(arguments[0]) &&
        arguments[1].startsWith('@')) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Looks like your email is wrong.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    }
    String? atSignStatus =
        (await AtSignAPI.checkAtsignStatus(arguments[1]))?.name;
    if (atSignStatus == 'activated') {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Oops, Looks like someone took this @sign.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    } else if (atSignStatus == 'notFound' || atSignStatus == 'unavailable') {
      ComponentMessageBuilder msgBuilder = ComponentMessageBuilder();
      msgBuilder.content =
          'Wooow, Looks like you need some custom @sign. Please refer to out site.';
      await event.message.channel.sendMessage(
        msgBuilder
          ..componentRows = <List<LinkButtonBuilder>>[
            <LinkButtonBuilder>[
              LinkButtonBuilder('Our website', 'https://my.atsign.com/go'),
            ]
          ],
      );
      event.message.channel.stopTypingLoop();
      return;
    }
    Map<String, dynamic> registered =
        await AtSignAPI.registerAtSign(arguments[0], arguments[1]);
    await event.message.channel.sendMessage(
      consts.MessageContent.custom(
        registered['message'].toString().contains('Successfully')
            ? '***`${arguments[1]}`*** is registered on your email successfully.'
            : registered['message'].toString(),
      ),
    );
    if (registered['message'].toString().contains('Successfully')) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'OTP will be sent to your mail shortly.\nUse `!otp <email> <@sign> <OTP>` to verify your email.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    }
    event.message.channel.stopTypingLoop();
    return;
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
    event.message.channel.startTypingLoop();
    if (arguments.length < 3) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Looks like you are missing arguments.\nTry `!otp <email> <@sign> <OTP>` to verify your email.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    } else if (arguments.length == 2 &&
        consts.Constants.emailRegExp.hasMatch(arguments[0]) &&
        arguments.last.length == 4) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Looks like you are missing @sign.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    } else if (arguments[2].length != 4) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          '🔐 OTP is invalid.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    } else if (!consts.Constants.emailRegExp.hasMatch(arguments[0])) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          '📨 Email is invalid.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    }
    Map<String, dynamic> data = await AtSignAPI.validatingOTP(
      arguments[1].toLowerCase(),
      arguments[0],
      arguments[2].toUpperCase(),
    );
    if (data.containsKey('data') &&
        data['data'].length != 0 &&
        (data['data']['atsigns'] as List<dynamic>).length == 10) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          data['data']['message'],
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    } else if (data['data']['newAtsign'] != null) {
      Map<String, dynamic> confirmationData = await AtSignAPI.validatingOTP(
        arguments[1].toLowerCase(),
        arguments[0],
        arguments[2].toUpperCase(),
        confirmation: true,
      );
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          confirmationData.containsKey('cramkey')
              ? 'Congratulations 🎉, You own the atsign.'
              : 'Oops!, Your @sign verification failed 💔.',
        ),
      );
      event.message.channel.stopTypingLoop();
      if (confirmationData.containsKey('cramkey')) {
        await _createCramQR(arguments[0], confirmationData['cramkey'], event);
        event.message.channel.stopTypingLoop();
        return;
      }
    } else {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          data['message'],
        ),
      );
    }
    event.message.channel.stopTypingLoop();
    return;
  }

  static Future<void> _createCramQR(
      String atSign, String? cram, IMessageReceivedEvent event) async {
    event.message.channel.startTypingLoop();
    Map<String, dynamic> query = <String, dynamic>{
      'size': '1000x1000',
      'data': cram,
    };
    http.Response response = await http.get(
      Uri.https(consts.Constants.qrDomain, consts.Constants.qrPath, query),
    );
    File cramPng = File('$atSign.png');
    await cramPng.writeAsBytes(response.bodyBytes);
    await event.message.channel.sendMessage(
      MessageBuilder.content('Here is your QR code.')
        ..addFileAttachment(cramPng),
    );
    print('sent cram QR');
    event.message.channel.stopTypingLoop();
    return;
  }

  static Future<void> getRootStatus(
      IMessageReceivedEvent event, List<String> arguments) async {
    event.message.channel.startTypingLoop();
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
    event.message.channel.stopTypingLoop();
    return;
  }

  static Future<String?> getAtSignStatus(
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
    return status?.name;
  }

  static Future<void> getUserAtSign(IMessageReceivedEvent event) async {
    event.message.channel.startTypingLoop();
    ComponentMessageBuilder componentMessageBuilder = ComponentMessageBuilder();
    ComponentRowBuilder componentRow = ComponentRowBuilder()
      ..addComponent(ButtonBuilder(
          'Get Random @Sign', 'singleAtSign', ComponentStyle.primary));
    // ..addComponent(ButtonBuilder(
    //     'Give me options', 'multiAtSigns', ComponentStyle.secondary));
    // IUser? user = event.message.member?.user.getFromCache();
    // if (user == null) {
    //   await event.message.channel
    //       .sendMessage(consts.MessageContent.custom('User not found'));
    //   return;
    // } else {
    componentMessageBuilder.addComponentRow(componentRow);
    await event.message.channel.sendMessage(componentMessageBuilder
      ..content =
          'Hey ${event.message.author.username}, We got a request from you for a new atsign.\nYou need options or get a random one?');
    event.message.channel.stopTypingLoop();
    return;
    // }
  }
}
