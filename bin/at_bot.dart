// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/at_bot.dart';
import 'package:at_bot/src/events/on_ready.dart';
import 'package:at_bot/src/utils/load_env.dart';

Future<void> main(List<String> arguments) async {
  /// Load all the env variables from `.bot.env` file.
  await loadEnv();

  /// Set logger level to `FINER`.
  Logger.root.level = Level.OFF;

  /// Fetch the bot token from environment variables
  String? token = env['token'];

  /// Logs in the bot.
  Nyxx? client = await login(token, GatewayIntents.allUnprivileged);

  /// On bot ready
  onReadyEvent(client);

  /// On message from the user
  await onMessageEvent(client);
}
