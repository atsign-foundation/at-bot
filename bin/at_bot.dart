// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/interactions.dart';

// 🌎 Project imports:
import 'package:at_bot/at_bot.dart';
import 'package:at_bot/src/events/on_ready.event.dart';
import 'package:at_bot/src/events/welcome.event.dart';
import 'package:at_bot/src/interactions/button.interaction.dart';
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/load_env.util.dart';

Future<void> main(List<String> arguments) async {
  try {
    /// Load all the env variables from `.bot.env` file.
    await loadEnv();

    /// Set logger level to `FINER`.
    Logger.root.level = Level.OFF;

    /// Fetch the bot token from environment variables
    String? token = env['token'];

    /// Logs in the bot.
    Nyxx? client = await login(token, GatewayIntents.all);

    /// User interaction.
    Interactions(client!)
      ..onButtonEvent.listen(buttonInteraction)
      ..syncOnReady();

    /// On bot ready
    await onReadyEvent(client);

    /// On new user joined.
    await onMemberJoined(client);

    /// On message from the user
    await onMessageEvent(client);
  } catch (e) {
    AtBotLogger.log(LogTypeTag.error, e.toString());
    throw Exception(e.toString());
  }
}
