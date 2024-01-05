// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:snapp_cli/command_runner.dart';
import 'package:snapp_cli/commands/base_command.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
class DeleteCommand extends BaseSnappCommand {
  DeleteCommand({
    required super.flutterSdkManager,
  });

  @override
  final String description = 'Delete a custom device from the Flutter SDK';

  @override
  final String name = 'delete';

  @override
  FutureOr<int>? run() {
    /// check if the user has provided a device id with the -d option
    if (globalResults!.wasParsed(deviceIdOption)) {
      final deviceId = globalResults!.stringArg(deviceIdOption)!;

      return _deleteDeviceWithId(deviceId);
    }

    /// if the user didn't provide a device id, then we will show an interactive
    /// prompt to select a device to delete
    return _interactiveDeleteDevice();
  }

  int _interactiveDeleteDevice() {
    final selectedDevice = interaction.selectDevice(
      customDevicesConfig,
      title: 'Select a device to delete',
      errorDescription:
          'Before you can delete a device, you need to add one first.',
    );

    final deviceId = selectedDevice.id;

    if (deviceId.isEmpty) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${customDevicesConfig.configPath}"');
    }

    return _deleteDeviceWithId(deviceId);
  }

  /// Delete device with id [deviceId] from the Flutter SDK
  int _deleteDeviceWithId(String deviceId) {
    if (!customDevicesConfig.contains(deviceId)) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${customDevicesConfig.configPath}"');
    }

    customDevicesConfig.remove(deviceId);
    logger.info(
        'Successfully removed device with id "$deviceId" from config at "${customDevicesConfig.configPath}"');

    return 0;
  }
}
