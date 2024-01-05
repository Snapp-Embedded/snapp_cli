// ignore_for_file: implementation_imports

import 'dart:async';
import 'package:snapp_cli/command_runner.dart';
import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:snapp_cli/utils/custom_device.dart';

const _ipOption = 'ip';

class UpdateIpCommand extends BaseSnappCommand {
  UpdateIpCommand({
    required super.flutterSdkManager,
  }) {
    argParser.addOption(
      _ipOption,
      abbr: 'i',
      help: 'The IP address of the remote device',
    );
  }

  @override
  String get description => 'Update the IP address of the remote device';

  @override
  String get name => 'update-ip';

  @override
  FutureOr<int>? run() {
    if (customDevicesConfig.devices.isEmpty) {
      throwToolExit(
        '''
No devices found in config at "${customDevicesConfig.configPath}"

Before you can update a device, you need to add one first.
''',
      );
    }

    String? deviceId;
    if (globalResults!.wasParsed(deviceIdOption)) {
      deviceId = globalResults!.stringArg(deviceIdOption)!;
    }

    String? ip;
    if (argResults!.wasParsed(_ipOption)) {
      ip = argResults!.stringArg(_ipOption)!;
    }

    if (deviceId != null && ip != null) {
      if (!ip.isValidIpAddress) {
        usageException('Ip address passed to this command is not valid');
      }

      return _updateIp(deviceId, ip);
    }

    return _interactiveUpdateIp(deviceId, ip);
  }

  int _interactiveUpdateIp(String? deviceId, String? ip) {
    if (deviceId == null) {
      final selectedDevice = interaction.selectDevice(
        customDevicesConfig,
        description: 'Please select a device to update its IP address.',
        errorDescription:
            'Before you can update a device, you need to add one first.',
      );

      deviceId = selectedDevice.id;
    }

    if (deviceId.isEmpty) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${customDevicesConfig.configPath}"');
    }

    if (ip == null) {
      logger.info(
        'Please enter the new IP-address of the device. (example: 192.168.1.101)',
      );

      final newIp = interaction.readDeviceIp(
        description:
            'Please enter the new IP-address of the device. (example: 192.168.1.101)',
        title: 'New IP-address:',
      );

      ip = newIp.address;
    }

    return _updateIp(deviceId, ip);
  }

  int _updateIp(String deviceId, String newIp) {
    if (!customDevicesConfig.contains(deviceId)) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${customDevicesConfig.configPath}"');
    }

    final currentDeviceConfig = customDevicesConfig.devices
        .firstWhere((element) => element.id == deviceId);

    final oldIp = currentDeviceConfig.tryFindDeviceIp;

    if (oldIp == null) {
      throwToolExit(
        '''
Couldn't find device old IP in pingCommand for the device with id "$deviceId" in config at "${customDevicesConfig.configPath}"
This could be because of a malformed ping command
Or Maybe you entered a host name instead of IpAddress in add command
        ''',
      );
    }

    final newDeviceConfig = currentDeviceConfig.replaceDeviceIp(oldIp, newIp);

    final newDeviceRemoved = customDevicesConfig.remove(currentDeviceConfig.id);

    if (!newDeviceRemoved) {
      throwToolExit(
        'Something went wrong in removing old device process. Device id: "$deviceId" in config at "${customDevicesConfig.configPath}"',
      );
    }

    customDevicesConfig.add(newDeviceConfig);

    logger.info(
      'IP address of device with id "$deviceId" successfully changed from "$oldIp" to "$newIp" in config at "${customDevicesConfig.configPath}"',
    );

    return 0;
  }
}
