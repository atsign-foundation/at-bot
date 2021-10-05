// 🌎 Project imports:
import 'package:at_bot/src/services/custom_print.util.dart' as console;

/// LoggerType Enum
enum LogTypeTag { success, info, warning, error }

/// Logger class
class AtBotLogger {
  /// Logger method to log depending on [LogTypeTag]
  static void log(LogTypeTag? tag, String? message) {
    /// Get the current date and time
    DateTime _now = DateTime.now();
    switch (tag) {
      case LogTypeTag.success:
        console.success(
            'SUCCESS [${_now.hour}:${_now.minute}:${_now.second}] - $message');
        break;
      case LogTypeTag.info:
        console.infoln(
            'INFORMATION [${_now.hour}:${_now.minute}:${_now.second}] - $message');
        break;
      case LogTypeTag.warning:
        console.logln(
            'WARNING [${_now.hour}:${_now.minute}:${_now.second}] - $message\n[StackTraces] - ${StackTrace.empty}');
        break;
      case LogTypeTag.error:
        console.errorln(
            'ERROR [${_now.hour}:${_now.minute}:${_now.second}] - $message\n[StackTraces] - ${StackTrace.current}');
        break;
      default:
        console.println(
            'LOG [${_now.hour}:${_now.minute}:${_now.second}] - $message');
    }
  }
}
