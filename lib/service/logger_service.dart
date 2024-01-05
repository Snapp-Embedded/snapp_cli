import 'package:mason_logger/mason_logger.dart';
import 'package:tint/tint.dart';

/// Sets default logger mode
final LoggerService logger = LoggerService._();

class LoggerService {
  final Logger _logger;

  Logger get loggerInstance => _logger;

  /// Constructor
  LoggerService._({
    Level? level,
  }) : _logger = Logger(level: level ?? Level.info);

  void get spacer => _logger.info('');

  bool get isVerbose => _logger.level == Level.verbose;

  set level(Level newLevel) => _logger.level = newLevel;

  Level get level => _logger.level;

  CliIcons get icons => CliIcons._();

  void spaces([int count = 1]) {
    for (var i = 0; i < count; i++) {
      print('');
    }
  }

  void write(String message) => _logger.write(message);

  void warn(String message) => _logger.warn(message);
  void info(String message) => _logger.info(message);
  void err(String message) => _logger.err(message);
  void detail(String message) => _logger.detail(message);
  void fail(String message) =>
      info(icons.failure.red().bold() + message.bold());
  void success(String message) =>
      info(icons.success.green().bold() + message.bold());

  String get stdout {
    return logger.stdout;
  }

  void get divider {
    _logger.info(
      '------------------------------------------------------------',
    );
  }
}

class CliIcons {
  const CliIcons._();
  // Success: ✓
  String get success => '✓';

  // Failure: ✗
  String get failure => '✗';

  // Information: ℹ
  String get info => 'ℹ';

  // Warning: ⚠
  String get warning => '⚠';

  // Arrow Right: →
  String get arrowRight => '→';

  // Arrow Left: ←
  String get arrowLeft => '←';

  // Check Box: ☑
  String get checkBox => '☑';

  // Star: ★
  String get star => '★';

  // Circle: ●
  String get circle => '●';

  // Square: ■
  String get square => '■';

  String get search => '🔎';
}
