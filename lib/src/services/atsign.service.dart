import 'dart:io';

import 'package:at_bot/src/services/get_atsign.dart';
import 'package:at_bot/src/utils/provider.util.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:nyxx/nyxx.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx_interactions/nyxx_interactions.dart';
import 'package:at_bot/src/utils/constants.util.dart' as consts;
import 'package:riverpod/riverpod.dart';

class AtSignService {
  // create singleton
  factory AtSignService() {
    return _singleton;
  }
  AtSignService._internal();
  static final AtSignService _singleton = AtSignService._internal();

  static Future<void> validateEmail(
      List<String> arguments, IMessageReceivedEvent event,
      {required ProviderContainer container}) async {
    bool isdev = container.read(isDev.state).state;
    String email = arguments[0], atSign = arguments[1];
    event.message.channel.startTypingLoop();
    if (arguments.isEmpty) {
      await event.message.channel.sendMessage(
          consts.MessageContent.custom('Please provide an email address'));
      event.message.channel.stopTypingLoop();
      return;
    } else if (arguments.length == 1) {
      if (arguments[0] == 'help') {
        await event.message.channel.sendMessage(
          consts.MessageContent.custom(
            'Use `!${isdev ? 'devemail' : 'email'} <email> <@sign>` command to register the @sign with you email.',
          ),
        );
        event.message.channel.stopTypingLoop();
        return;
      } else {
        await event.message.channel.sendMessage(
          consts.MessageContent.custom(
            consts.Constants.emailRegExp.hasMatch(email)
                ? 'Looks like you are missing @sign.'
                : 'Looks like you are missing your email.',
          ),
        );
        event.message.channel.stopTypingLoop();
        return;
      }
    } else if (arguments.length == 2 &&
        !consts.Constants.emailRegExp.hasMatch(email) &&
        atSign.startsWith('@')) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Looks like your email is wrong.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    }
    String? atSignStatus =
        (await AtSignAPI.checkAtsignStatus(atSign, container: container))?.name;
    event.message.channel.stopTypingLoop();
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
        await AtSignAPI.registerAtSign(email, atSign, isdev);
    if (registered['message'].toString().contains('Successfully')) {
      container.read(atSignMail.state).state[atSign] = email;
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Almost done. We just need to verify your email address. Please check your email for a 4 character code and enter it below. If it\'s not in your inbox, check your spam/junk and promotions folders.',
        ),
      );
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Use `!${isdev ? 'devotp' : 'otp'} <@sign> <OTP>` to verify your email.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    } else {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          registered['message'].toString(),
        ),
      );
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
      IMessageReceivedEvent event, List<String> arguments,
      {required ProviderContainer container}) async {
    String atSign = arguments[0], otp = arguments[1];
    String? email = container.read(atSignMail.state).state[atSign];
    if (email == null) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Looks like you are not registered with this @sign.',
        ),
      );
      return;
    }
    event.message.channel.startTypingLoop();
    if (arguments.length < 2) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Looks like you are missing arguments.\nTry `!${container.read(isDev.state).state ? 'devotp' : 'otp'} <@sign> <OTP>` to verify your email.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    }
    //  else if (arguments.length == 2 &&
    //     consts.Constants.emailRegExp.hasMatch(email) &&
    //     arguments.last.length == 4) {
    //   await event.message.channel.sendMessage(
    //     consts.MessageContent.custom(
    //       'Looks like you are missing @sign.',
    //     ),
    //   );
    //   event.message.channel.stopTypingLoop();
    //   return;
    // }
    else if (otp.length != 4) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          '🔐 OTP is invalid.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    } else if (!consts.Constants.emailRegExp.hasMatch(email)) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          '📨 Email is invalid.',
        ),
      );
      event.message.channel.stopTypingLoop();
      return;
    }
    Map<String, dynamic> data = await AtSignAPI.validatingOTP(
      atSign.toLowerCase(),
      email,
      otp.toUpperCase(),
      isDev: container.read(isDev.state).state,
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
        atSign.toLowerCase(),
        email,
        otp.toUpperCase(),
        confirmation: true,
        isDev: container.read(isDev.state).state,
      );
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          confirmationData.containsKey('cramkey')
              ? 'Congratulations! 🎉  You are now the proud owner of $atSign !\nIf you\'re on a laptop or desktop computer, get started with your shiny new @sign now by using an @app on your mobile device to scan the QR Code below. If you\'re on a mobile device, get started by entering the @sign into the “Setting up your account”  screen in any @app.'
              : 'Oops!, Your ${container.read(isDev.state).state ? 'Dev-' : ''}@sign verification failed 💔.',
        ),
      );
      event.message.channel.stopTypingLoop();
      if (confirmationData.containsKey('cramkey')) {
        await _createCramQR(email, confirmationData['cramkey'], event);
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
    await cramPng.delete(recursive: true);
    event.message.channel.stopTypingLoop();
    return;
  }

  static Future<void> getRootStatus(IMessageReceivedEvent event,
      List<String> arguments, ProviderContainer container) async {
    String atSign = arguments[0];
    event.message.channel.startTypingLoop();
    if (event.message.guild != null) {
      MessageBuilder statusBuilder = MessageBuilder();
      AtStatus? status =
          await AtSignAPI.checkAtSignServerStatus(atSign, container: container);
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
    } else {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Looks like you are not in a server.',
        ),
      );
    }
    event.message.channel.stopTypingLoop();
    return;
  }

  static Future<String?> getAtSignStatus(IMessageReceivedEvent event,
      List<String> arguments, ProviderContainer container) async {
    if (event.message.guild == null) {
      await event.message.channel.sendMessage(
        consts.MessageContent.custom(
          'Looks like you are not in a server.',
        ),
      );
      return null;
    }
    String atSign = arguments[0];
    event.message.channel.startTypingLoop();
    AtSignStatus? status =
        await AtSignAPI.checkAtsignStatus(atSign, container: container);
    event.message.channel.stopTypingLoop();
    MessageBuilder builder = MessageBuilder();
    builder.addEmbed((EmbedBuilder embed) {
      embed
        ..title = '@Sign Status'
        ..description =
            '***`$atSign`*** status is : ${status?.name.toUpperCase()}'
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
    bool isDev = event.message.content.contains('dev');
    ComponentMessageBuilder componentMessageBuilder = ComponentMessageBuilder();
    ComponentRowBuilder componentRow = ComponentRowBuilder()
      ..addComponent(ButtonBuilder('Generate a free @sign',
          isDev ? 'singleAtSignDev' : 'singleAtSign', ComponentStyle.primary))
      ..addComponent(
        LinkButtonBuilder('Go to website', 'https://my.atsign.com/go'),
      );
    IUser? user;
    try {
      user = event.message.member?.user.getFromCache();
    } catch (e) {
      user = event.message.author as IUser?;
    }
    if (user == null) {
      await event.message.channel
          .sendMessage(consts.MessageContent.custom('User not found'));
      return;
    } else {
      componentMessageBuilder.addComponentRow(componentRow);
      await user.sendMessage(componentMessageBuilder
        ..content =
            'Hey ${user.username}, We received your request for a new @sign. Would you like to generate a free random @sign here or head over to our website for more options?');
      return;
    }
  }
}
