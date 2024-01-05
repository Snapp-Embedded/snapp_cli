// ignore_for_file: implementation_imports

import 'dart:io' as io;

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';
import 'package:path/path.dart' as path;

/// singleton class to manage flutter sdk
/// responsible for find the flutter path and initialize the flutter sdk
class FlutterSdkManager {
  static const FlutterSdkManager _instance = FlutterSdkManager._();

  const FlutterSdkManager._();

  factory FlutterSdkManager() => _instance;

  bool get isInitialized => Cache.flutterRoot != null;

  /// get the flutter sdk file system
  FileSystem get flutterSdkFileSystem => _provider(globals.localFileSystem);
  CustomDevicesConfig get customDeviceConfig =>
      _provider(globals.customDevicesConfig);

  ProcessManager get processManager => _provider(globals.processManager);
  ProcessUtils get processRunner =>
      ProcessUtils(processManager: processManager, logger: logger);

  Terminal get terminal => _provider(globals.terminal);
  Platform get platform => _provider(globals.platform);
  Logger get logger => _provider(globals.logger);
  String get icuDataPath => _provider(
        globals.artifacts!.getArtifactPath(
          Artifact.icuData,
          mode: BuildMode.debug,
        ),
      );

  bool get areCustomDevicesEnabled =>
      _provider(featureFlags.areCustomDevicesEnabled);

  bool get isLinuxEnabled => _provider(featureFlags.isLinuxEnabled);

  /// initialize the flutter sdk
  Future<void> initialize() async {
    if (isInitialized) return;

    final flutterRoot = await _getFlutterRootDirectory();

    final flutterDirectory = LocalFileSystem()..currentDirectory = flutterRoot;

    Cache.flutterRoot = Cache.defaultFlutterRoot(
      platform: const LocalPlatform(),
      fileSystem: flutterDirectory,
      userMessages: UserMessages(),
    );
  }

  T _provider<T>(T value) {
    if (!isInitialized) {
      throw Exception(
        'Flutter SDK is not initialized: use initialize() method first',
      );
    }
    return value;
  }

  /// get the flutter sdk path
  Future<String> _getFlutterRootDirectory() async {
    final pkgConfig = (await findPackageConfigUri(io.Platform.script))!;

    final flutterToolsPath =
        pkgConfig.resolve(Uri.parse('package:flutter_tools/'))!.toFilePath();

    const dirname = path.dirname;

    return dirname(dirname(dirname(flutterToolsPath)));
  }
}
