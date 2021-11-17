part of logging_utils;

/// A custom logger to make debugging much easier. Use this instead of `print()` in production.
class CustomLogger {
  CustomLogger._();

  /// Makes error logging much easier.
  static void error(Object? e) => log("ERROR", e.toString());

  /// Logs a title and a message.
  static void log(String object, String text) {
    LogsManager.saveLogs(logs: [YLog(category: object, comment: text)], category: object);
    debugPrint('[${object.toUpperCase()}] ${text.toString()}');
  }

  /// Same as [log], but on multiple lines. Useful when there is a huge amount of text.
  static void logWrapped(String object, String description, String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    LogsManager.saveLogs(logs: [YLog(category: object, comment: "$description: $text")], category: object);
    pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));
  }
}
