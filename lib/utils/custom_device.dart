// ignore_for_file: implementation_imports

import 'package:collection/collection.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:snapp_cli/commands/base_command.dart';

extension CustomDevicesConfigX on CustomDevicesConfig {
  bool isDuplicatedDeviceId(String s) =>
      devices.any((element) => element.id == s);
}

extension CustomDeviceConfigX on CustomDeviceConfig {
  /// Try to find the device ip address in the ping command
  String? get tryFindDeviceIp => pingCommand.firstWhereOrNull(
        (element) => InternetAddress.tryParse(element) != null,
      );

  /// Get the device ip address from the ping command
  /// If the ping command doesn't contain an ip address, then throw an error
  String get deviceIp => pingCommand.firstWhere(
        (element) => InternetAddress.tryParse(element) != null,
      );

  /// Get the device username
  /// Check if the username is defined before the ip address in the ping command
  /// sample: username@192.168.1.1
  /// If the ping command doesn't contain a username, then throw an error
  String get deviceUsername {
    final deviceIp = this.deviceIp;

    final targetSsh = uninstallCommand.firstWhere(
      (element) {
        if (element.contains(deviceIp)) {
          final username = element.split('@').first;

          if (username.isNotEmpty) return true;
        }
        return false;
      },
      orElse: () => throwToolExit(
        'Could not find the device username in the device config file',
      ),
    );

    return targetSsh.split('@').first;
  }

  CustomDeviceConfig replaceDeviceIp(String oldIp, String newIp) {
    final newDevice = copyWith();

    final newPingCommand = _replaceNewIpInCommand(
      newDevice.pingCommand,
      oldIp,
      newIp,
    );

    final newPostBuildCommand = _replaceNewIpInCommand(
      newDevice.postBuildCommand,
      oldIp,
      newIp,
    );

    final newInstallCommand = _replaceNewIpInCommand(
      newDevice.installCommand,
      oldIp,
      newIp,
    );

    final newUninstallCommand = _replaceNewIpInCommand(
      newDevice.uninstallCommand,
      oldIp,
      newIp,
    );

    final newRunDebugCommand = _replaceNewIpInCommand(
      newDevice.runDebugCommand,
      oldIp,
      newIp,
    );

    final newForwardPortCommand = _replaceNewIpInCommand(
      newDevice.forwardPortCommand,
      oldIp,
      newIp,
    );

    final newScreenshotCommand = _replaceNewIpInCommand(
      newDevice.screenshotCommand,
      oldIp,
      newIp,
    );

    return newDevice.copyWith(
      pingCommand: newPingCommand,
      postBuildCommand: newPostBuildCommand,
      installCommand: newInstallCommand,
      uninstallCommand: newUninstallCommand,
      runDebugCommand: newRunDebugCommand,
      forwardPortCommand: newForwardPortCommand,
      screenshotCommand: newScreenshotCommand,
    );
  }

  List<String>? _replaceNewIpInCommand(
    List<String>? command,
    String oldIp,
    String newIp,
  ) =>
      command?.map((item) {
        final hasOldInText = item.contains(oldIp);

        if (hasOldInText) {
          return item.replaceAll(oldIp, newIp);
        }
        return item;
      }).toList();
}
