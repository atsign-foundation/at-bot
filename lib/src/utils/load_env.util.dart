// 🎯 Dart imports:
import 'dart:io';

// 📦 Package imports:
import 'package:dotenv/dotenv.dart';

// 🌎 Project imports:
import 'package:at_bot/src/services/logs.dart';
import 'package:at_bot/src/utils/constants.util.dart';

/// Load all the env variables from `.bot.env` file.
/// If the file is not found, it will throw an exception.
Future<void> loadEnv() async {
  try {
    /// Check if file exist in the current working directory.
    if (await File(Constants.envFile).exists()) {
      /// Load the env variables from the file.
      load(Constants.envFile);

      ///
      if (env['token'] == null) {
        AtBotLogger.logln(LogTypeTag.error, 'Missing token in `.bot.env` file');
        exit(-1);
      }
    } else {
      /// If the file is not found, throw FileSystemException.
      throw const FileSystemException();
    }
  } on FileSystemException catch (_) {
    /// Throw an exception if the file is not found.
    throw FileSystemException(
      'File `${Constants.envFile}` not found.',
      Directory.current.path,
    );
  } catch (e) {
    throw Exception('Exception : ' + e.toString());
  }
}
