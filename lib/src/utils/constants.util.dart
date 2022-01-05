// 📦 Package imports:
import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:dotenv/dotenv.dart';

/// Bot general constants
class Constants {
  static bool h = false;
  static IMessage? msg;
  static const String rootDomain = 'root.atsign.org';
  static const int port = 64;
  static const String domain = 'my.atsign.com';
  static const String qrDomain = 'api.qrserver.com';
  static const String qrPath = '/v1/create-qr-code/';
  static const String path = '/api/app/v2/';
  static const String getFreeAtSign = 'get-free-atsign';
  static const String registerAtSign = 'register-person';
  static const String validateOTP = 'validate-person';
  static String devApiKey() =>
      env['DEV_API_KEY'] ?? const String.fromEnvironment('dev-api-key');
  static String prodApiKey() =>
      env['PROD_API_KEY'] ?? const String.fromEnvironment('prod-api-key');
  static final RegExp emailRegExp = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

  /// Enviroment variables file name
  static const String envFile = '.bot.env';

  /// Reg for finding role in user nickname
  static final RegExp _regExp = RegExp(r'\[\S*\] ');

  /// Remoive that role from user nickname
  static String? removeStuff(String input) => input.replaceAll(_regExp, '');

  /// Roles colors
  static Map<String, DiscordColor> colors = <String, DiscordColor>{
    /// Represents no color, or integer 0.
    'none': DiscordColor.none,

    /// A near-black color. Due to API limitations, the color is #010101, rather than #000000, as the latter is treated as no color.
    'black': DiscordColor.black,

    /// White, or #FFFFFF.
    'white': DiscordColor.white,

    /// Gray, or #808080.
    'gray': DiscordColor.gray,

    /// Dark gray, or #A9A9A9.
    'darkGray': DiscordColor.darkGray,

    /// Light gray, or #808080.
    'lightGray': DiscordColor.lightGray,

    /// Very dark gray, or #666666.
    'veryDarkGray': DiscordColor.veryDarkGray,

    /// Flutter blue, or #02569B
    'flutterBlue': DiscordColor.flutterBlue,

    /// Dart's primary blue color, or #0175C2
    'dartBlue': DiscordColor.dartBlue,

    ///  Dart's secondary blue color, or #13B9FD
    'dartSecondary': DiscordColor.dartSecondary,

    /// Discord Blurple, or #7289DA.
    'blurple': DiscordColor.blurple,

    /// Discord Grayple, or #99AAB5.
    'grayple': DiscordColor.grayple,

    /// Discord Dark, But Not Black, or #2C2F33.
    'darkButNotBlack': DiscordColor.darkButNotBlack,

    /// Discord Not QuiteBlack, or #23272A.
    'notQuiteBlack': DiscordColor.notQuiteBlack,

    /// Red, or #FF0000.
    'red': DiscordColor.red,

    /// Dark red, or #7F0000.
    'darkRed': DiscordColor.darkRed,

    /// Green, or #00FF00.
    'green': DiscordColor.green,

    /// Dark green, or #007F00.
    'darkGreen': DiscordColor.darkGreen,

    /// Blue, or #0000FF.
    'blue': DiscordColor.blue,

    /// Dark blue, or #00007F.
    'darkBlue': DiscordColor.darkBlue,

    /// Yellow, or #FFFF00.
    'yellow': DiscordColor.yellow,

    /// Cyan, or #00FFFF.
    'cyan': DiscordColor.cyan,

    /// Magenta, or #FF00FF.
    'magenta': DiscordColor.magenta,

    /// Teal, or #008080.
    'teal': DiscordColor.teal,

    /// Aquamarine, or #00FFBF.
    'aquamarine': DiscordColor.aquamarine,

    /// Gold, or #FFD700.
    'gold': DiscordColor.gold,

    /// Goldenrod, or #DAA520
    'goldenrod': DiscordColor.goldenrod,

    /// Azure, or #007FFF.
    'azure': DiscordColor.azure,

    /// Rose, or #FF007F.
    'rose': DiscordColor.rose,

    /// Spring green, or #00FF7F.
    'springGreen': DiscordColor.springGreen,

    /// Chartreuse, or #7FFF00.
    'chartreuse': DiscordColor.chartreuse,

    /// Orange, or #FFA500.
    'orange': DiscordColor.orange,

    /// Purple, or #800080.
    'purple': DiscordColor.purple,

    /// Violet, or #EE82EE.
    'violet': DiscordColor.violet,

    /// Brown, or #A52A2A.
    'brown': DiscordColor.brown,

    /// Hot pink, or #FF69B4
    'hotPink': DiscordColor.hotPink,

    /// Lilac, or #C8A2C8.
    'lilac': DiscordColor.lilac,

    /// Cornflower blue, or #6495ED.
    'cornflowerBlue': DiscordColor.cornflowerBlue,

    /// Midnight blue, or #191970.
    'midnightBlue': DiscordColor.midnightBlue,

    /// Wheat, or #F5DEB3.
    'wheat': DiscordColor.wheat,

    /// Indian red, or #CD5C5C.
    'indianRed': DiscordColor.indianRed,

    /// Turquoise, or #30D5C8.
    'turquoise': DiscordColor.turquoise,

    /// Sap green, or #507D2A.
    'sapGreen': DiscordColor.sapGreen,

    /// Phthalo blue, or #000F89.
    'phthaloBlue': DiscordColor.phthaloBlue,

    /// Phthalo green, or #123524.
    'phthaloGreen': DiscordColor.phthaloGreen,

    /// Sienna, or #882D17.
    'sienna': DiscordColor.sienna,
  };
}

/// Bot Message content constants
class MessageContent {
  /// Private function returns message content builder.
  static MessageBuilder _messgaeContent(String message) {
    return MessageBuilder.content(message);
  }

  /// User need to be admin.
  static MessageBuilder get needToBeAdmin =>
      _messgaeContent('You need to be an admin to use this command');

  /// Don't DM commands please.
  static MessageBuilder get noDMs =>
      _messgaeContent('Sorry you can\'t use this command in DMs.');

  /// Don't use element ID in commands please.
  static MessageBuilder get noIdPlease =>
      _messgaeContent('Sorry, I don\'t support ID.');

  /// Removed the role from an user.
  static MessageBuilder roleRemoved({String? roleName, String? userName}) =>
      _messgaeContent('Role **`$roleName`** removed from **`$userName`**');

  /// Added the role from an user.
  static MessageBuilder roleAdded({String? roleName, String? userName}) =>
      _messgaeContent('Role **$roleName** added to **`$userName`**');

  /// Requested the user to join in the role.
  static MessageBuilder roleRequested({String? roleName}) =>
      _messgaeContent('Admin has requested you to join **$roleName** role.');

  /// Created the role on a request.
  static MessageBuilder roleCreated(String roleName) =>
      _messgaeContent('Role **$roleName** created on request.');

  /// Deleted the role on a request from guild.
  static MessageBuilder roleDeleted(String roleName) =>
      _messgaeContent('Role **`$roleName`** deleted on request.');

  /// Exception message.
  static MessageBuilder exception(Object? e) =>
      _messgaeContent('Something went wrong. \nException : ${e.toString()}');

  /// Welcome message.
  static MessageBuilder welcome(IUser user, IGuild guild) => _messgaeContent(
      'Hello **${user.username}**, Welcome to **${guild.name}**.');

  /// Renaming done.
  static MessageBuilder renameDone() =>
      _messgaeContent('Renamed all the nick names.');

  /// Waiting message for long interactions.
  static MessageBuilder get waiting => _messgaeContent('waiting...');

  /// Custom message.
  static MessageBuilder custom(String message) => _messgaeContent(message);
}

String millisToMinutesAndSeconds(int millis) {
  int minutes = (millis / 60000).floor();
  int seconds = ((millis % 60000) / 1000).floor();
  return '$minutes : $seconds';
}

String generateRandomToken(int length) {
  String alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';
  Random rng = Random();
  StringBuffer token = StringBuffer();
  for (int i = 0; i < length; i++) {
    token.write(alphabet[rng.nextInt(alphabet.length)]);
  }
  print(token.toString());
  return token.toString();
}

class Commands {
  static const String music = 'music';
  static const String rename = 'rename';
  static const String role = 'role';
  static const String node = 'node';
  static const String getAtSign = 'get';
}
