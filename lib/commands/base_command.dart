// ignore_for_file: implementation_imports

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/flutter_sdk.dart';
import 'package:flutter_tools/src/base/process.dart';

export 'package:flutter_tools/src/base/common.dart';
export 'package:snapp_cli/service/logger_service.dart';
export 'package:snapp_cli/service/interaction_service.dart';

abstract class BaseSnappCommand extends Command<int> {
  BaseSnappCommand({
    required this.flutterSdkManager,
  })  : hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform),
        processRunner = ProcessUtils(
            processManager: flutterSdkManager.processManager,
            logger: flutterSdkManager.logger);

  final FlutterSdkManager flutterSdkManager;
  final ProcessUtils processRunner;

  /// create a HostPlatform instance based on the current platform
  /// with the help of this class we can make the commands platform specific
  /// for example, the ping command is different on windows and linux
  ///
  /// only supports windows, linux and macos
  final HostRunnerPlatform hostPlatform;

  CustomDevicesConfig get customDevicesConfig =>
      flutterSdkManager.customDeviceConfig;
}

extension ArgResultsExtension on ArgResults {
  /// Gets the parsed command-line option named [name] as `bool`.
  bool boolArg(String name) => this[name] == true;

  /// Gets the parsed command-line option named [name] as `String`.
  String? stringArg(String name) {
    final arg = this[name];
    if (arg == 'null' || arg == Null || (arg == null || arg.isEmpty)) {
      return null;
    }
    return arg;
  }

  /// Gets the parsed command-line option named [name] as `List<String>`.
  List<String?> stringsArg(String name) => this[name] as List<String>;
}
