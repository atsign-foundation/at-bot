// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/at_bot.dart';
import 'package:at_bot/src/events/on_ready.dart';

Future<void> main(List<String> arguments) async {
  /// Load all the env variables from `.bot.env` file.
  load('.bot.env');

  /// Set logger level to `FINER`.
  Logger.root.level = Level.FINER;

  /// Fetch the bot token from environment variables
  String? token = env['token'];

  /// Logs in the bot.
  Nyxx? client = await login(token, GatewayIntents.allUnprivileged);

  /// On bot ready
  onReadyEvent(client);

  /// On message from the user
  await onMessageEvent(client);
}
