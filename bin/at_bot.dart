// 🎯 Dart imports:
import 'dart:async';

// 📦 Package imports:
import 'package:at_bot/src/events/on_music.event.dart';
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
import 'package:nyxx_lavalink/lavalink.dart';

Future<void> main(List<String> arguments) async {
  try {
    /// Load all the env variables from `.bot.env` file.
    await loadEnv();

    /// Set logger level to `FINER`.
    Logger.root.level = Level.OFF;

    /// Fetch the bot token from environment variables
    String? token = env['token'];
    Snowflake clientID = Snowflake(env['botID']);

    /// Logs in the bot.
    Nyxx? client = await login(token, GatewayIntents.all);
    Cluster cluster = Cluster(client!, clientID);
    try {
      await cluster.addNode(NodeOptions(
        host: 'lavalink.yahu1031.repl.co',
        port: 443,
        ssl: true,
      ));
    } on Exception catch (e) {
      print(e.toString());
    }

    /// User interaction.
    Interactions(client)
      ..onButtonEvent.listen((ButtonInteractionEvent event) => buttonInteraction(event, cluster: cluster))
      ..syncOnReady();

    /// On bot ready
    await onReadyEvent(client);

    await onMusicEvent(cluster);

    /// On new user joined.
    await onMemberJoined(client);

    /// On message from the user
    await onMessageEvent(client, cluster: cluster);
  } catch (e) {
    AtBotLogger.logln(LogTypeTag.error, e.toString());
    throw Exception(e.toString());
  }
}
