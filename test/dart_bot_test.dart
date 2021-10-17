// 🎯 Dart imports:
import 'dart:io';

// 📦 Package imports:
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:at_bot/at_bot.dart';
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/load_env.util.dart';

Future<void> main() async {
  AtBotLogger.log(LogTypeTag.info, 'Starting tests...');
  Logger.root.level = Level.OFF;
  await loadEnv();
  AtBotLogger.log(LogTypeTag.success, 'Loaded env');
  test('Bot login test', () async {
    String? token = env['token'];
    AtBotLogger.log(LogTypeTag.info, 'prefix is - ${env['prefix']}');
    Nyxx? client = await login(token, GatewayIntents.all);
    client!.onReady.listen((_) {
      AtBotLogger.log(LogTypeTag.success, '${client.self.tag} is logged in...');
      expect(client.self.tag, 'JS Bot#1811');
      exit(0);
    });
  });
}
