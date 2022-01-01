// 📦 Package imports:
import 'package:intl/intl.dart';
import 'package:nyxx/nyxx.dart';

// 🌎 Project imports:
import 'package:at_bot/src/services/custom_print.util.dart' as console;

/// LoggerType Enum
enum LogTypeTag { success, info, warning, error }

/// Logger class
class AtBotLogger {
  /// Logger method to log depending on [LogTypeTag]
  static void log(LogTypeTag? tag, String? message) {
    /// Get the current date and time
    String time = DateFormat.yMEd().add_jms().format(DateTime.now());
    switch (tag) {
      case LogTypeTag.success:
        console.success('SUCCESS [$time] - $message');
        break;
      case LogTypeTag.info:
        console.info('INFORMATION [$time] - $message');
        break;
      case LogTypeTag.warning:
        console.log('WARNING [$time] - $message');
        break;
      case LogTypeTag.error:
        console.error('ERROR [$time] - $message\n[StackTraces] - ${StackTrace.current}');
        break;
      default:
        print('LOG [$time] - $message');
    }
  }

  static void logln(LogTypeTag? tag, String? message) {
    /// Get the current date and time
    String time = DateFormat.yMEd().add_jms().format(DateTime.now());
    switch (tag) {
      case LogTypeTag.success:
        console.successln('SUCCESS [$time] - $message');
        break;
      case LogTypeTag.info:
        console.infoln('INFORMATION [$time] - $message');
        break;
      case LogTypeTag.warning:
        console.logln('WARNING [$time] - $message');
        break;
      case LogTypeTag.error:
        console.errorln('ERROR [$time] - $message\n[StackTraces] - ${StackTrace.current}');
        break;
      default:
        console.println('LOG [$time] - $message');
    }
  }
}

/// Sends the message to the channel and logs it.
Future<void> logAndSendMessage(
    IMessageReceivedEvent event, MessageBuilder messageBuilder, LogTypeTag logType, String logMessage) async {
  await event.message.channel.sendMessage(messageBuilder);
  AtBotLogger.logln(logType, logMessage);
}
