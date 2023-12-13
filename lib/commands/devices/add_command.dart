// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';
import 'package:interact/interact.dart';
import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/configs/predefined_devices.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/service/remote_controller_service.dart';
import 'package:snapp_cli/service/ssh_service.dart';
import 'package:snapp_cli/utils/common.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
///
///
// TODO: add get platform for example: x64 or arm64
class AddCommand extends BaseSnappCommand {
  AddCommand({
    required super.flutterSdkManager,
  })  : sshService = SshService(flutterSdkManager: flutterSdkManager),
        remoteControllerService =
            RemoteControllerService(flutterSdkManager: flutterSdkManager);

  final SshService sshService;
  final RemoteControllerService remoteControllerService;

  @override
  final name = 'add';

  @override
  final description = 'add a new device to custom devices';

  @override
  Future<int> run() async {
    logger.printSpaces();

    final addCommandOptions = [
      'Express (recommended)',
      'Custom',
    ];

    final commandIndex = Select(
      prompt: 'Please select the type of device you want to add.',
      options: addCommandOptions,
    ).interact();

    if (commandIndex == 0) {
      return _addPredefinedDevice();
    }

    return _addCustomDevice();
  }

  Future<int> _addPredefinedDevice() async {
    logger.printSpaces();

    final selectedPredefinedDevice = Select(
      prompt: 'Select your device',
      options: predefinedDevices.keys.toList(),
    ).interact();

    final deviceKey =
        predefinedDevices.keys.elementAt(selectedPredefinedDevice);

    var predefinedDeviceConfig = predefinedDevices[deviceKey];

    if (predefinedDeviceConfig == null) {
      throwToolExit(
          'Something went wrong while trying to add predefined $deviceKey device.');
    }

    /// check if the device id already exists in the config file
    /// update the id if it
    if (_isDuplicatedDeviceId(predefinedDeviceConfig.id)) {
      predefinedDeviceConfig = predefinedDeviceConfig.copyWith(
        id: _suggestIdForDuplicatedDeviceId(predefinedDeviceConfig.id),
      );
    }

    return _addCustomDevice(predefinedConfig: predefinedDeviceConfig);
  }

  Future<int> _addCustomDevice({
    CustomDeviceConfig? predefinedConfig,
  }) async {
    logger.printSpaces();

    // get remote device id and label from the user
    final (id, label) = getRemoteDeviceIdAndLabel(predefinedConfig);

    // get remote device ip and username from the user
    final (targetIp, username) = getRemoteIpAndUsername(
      message: 'to add a new device, we need an IP address and a username.',
      getIpDescription:
          'Please enter the IP-address of the device. (example: 192.168.1.101)',
      getUsernameDescription:
          'Please enter the username used for ssh-ing into the remote device. (example: pi)',
    );

    final bool ipv6 = targetIp.isIpv6;

    final InternetAddress loopbackIp =
        ipv6 ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4;

    // SSH expects IPv6 addresses to use the bracket syntax like URIs do too,
    // but the IPv6 the user enters is a raw IPv6 address, so we need to wrap it.
    final String sshTarget = targetIp.sshTarget(username);

    final String formattedLoopbackIp =
        ipv6 ? '[${loopbackIp.address}]' : loopbackIp.address;

    logger.printSpaces();

    bool remoteHasSshConnection =
        await sshService.testPasswordLessSshConnection(username, targetIp);

    if (!remoteHasSshConnection) {
      logger.printFail(
        'could not establish a password-less ssh connection to the remote device. \n',
      );

      logger.printStatus(
          'We can create a ssh connection with the remote device, do you want to try it?');

      final continueWithoutPing = Confirm(
        prompt: 'Create a ssh connection?',
        defaultValue: true, // this is optional
        waitForNewLine: true, // optional and will be false by default
      ).interact();

      if (!continueWithoutPing) {
        logger.printSpaces();
        logger.printStatus(
            'Check your ssh connection with the remote device and try again.');
        return 1;
      }

      logger.printSpaces();

      final sshConnectionCreated =
          await sshService.createPasswordLessSshConnection(username, targetIp);

      if (sshConnectionCreated) {
        logger.printSuccess('SSH connection to the remote device is created!');
        remoteHasSshConnection = true;
      } else {
        logger
            .printFail('Could not create SSH connection to the remote device!');
        return 1;
      }
    }

    logger.printSpaces();

    logger.printStatus(
      'We need the exact path of your flutter command line tools on the remote device. '
      'We will use this path to run flutter commands on the remote device like "flutter build linux --debug". \n',
    );

    String remoteRunnerCommand = '';

    if (remoteHasSshConnection) {
      final possibleFlutterPath =
          await remoteControllerService.findFlutterPath(username, targetIp);

      remoteRunnerCommand = possibleFlutterPath ?? '';
    }

    if (remoteRunnerCommand.isEmpty) {
      logger.printStatus(
        'Could not find flutter in the remote machine automatically. \n\n'
        'You need to provide it manually.'
        'You can use which command to find it in your remote machine: "which flutter" \n'
        '*NOTE: if you added flutter to one of directories in \$PATH variables, you can just enter "flutter" here. \n'
        '(example: /home/pi/sdk/flutter/bin/flutter)',
      );

      remoteRunnerCommand = Input(
        prompt: 'Flutter path on device:',
        validator: (s) {
          if (s.isValidPath) {
            return true;
          }
          throw ValidationError('Invalid Path to flutter. Please try again.');
        },
      ).interact();
    }

    /// path to the icu data file on the host machine
    final hostIcuDataPath = flutterSdkManager.icuDataPath;

    /// path to the build artifacts on the remote machine
    const hostBuildClonePath = 'snapp_embedded';

    /// path to the icu data file on the remote machine
    const hostIcuDataClone = '$hostBuildClonePath/engine';

    CustomDeviceConfig config = CustomDeviceConfig(
      id: id,
      label: label,
      sdkNameAndVersion: label,
      enabled: true,

      // host-platform specific, filled out later
      pingCommand:
          hostPlatform.pingCommand(ipv6: ipv6, pingTarget: targetIp.address),
      pingSuccessRegex: hostPlatform.pingSuccessRegex,
      postBuildCommand: const <String>[],

      // just install to /tmp/${appName} by default
      // returns the command runner for the current platform
      // for example:
      // on windows it returns "powershell -c"
      // on linux and macOS it returns "bash -c"
      installCommand: hostPlatform.commandRunner(
        <String>[
          // create the necessary directories in the remote machine
          hostPlatform
              .sshCommand(
                ipv6: ipv6,
                sshTarget: sshTarget,
                command: 'mkdir -p /tmp/\${appName}/$hostIcuDataClone',
              )
              .asString,

          // copy the current project files from host to the remote
          hostPlatform
              .scpCommand(
                ipv6: ipv6,
                source: '${hostPlatform.currentSourcePath}*',
                dest: '$sshTarget:/tmp/\${appName}',
              )
              .asString,

          // copy the build artifacts from host to the remote
          hostPlatform
              .scpCommand(
                ipv6: ipv6,
                source: r'${localPath}',
                dest: '$sshTarget:/tmp/\${appName}/$hostBuildClonePath',
              )
              .asString,

          // copy the icu data file from host to the remote
          hostPlatform
              .scpCommand(
                ipv6: ipv6,
                source: hostIcuDataPath,
                dest: '$sshTarget:/tmp/\${appName}/$hostIcuDataClone',
                lastCommand: true,
              )
              .asString,
        ],
      ),
      // just uninstall app by removing the /tmp/${appName} directory on the remote
      uninstallCommand: hostPlatform.sshCommand(
        ipv6: ipv6,
        sshTarget: sshTarget,
        command: r'rm -rf "/tmp/${appName}"',
        lastCommand: true,
      ),

      // run the app on the remote
      runDebugCommand: hostPlatform.sshMultiCommand(
        ipv6: ipv6,
        sshTarget: sshTarget,
        commands: <String>[
          'cd /tmp/\${appName} ;',
          '$remoteRunnerCommand build linux --debug ;',
          // remove remote build artifacts
          'rm -rf "/tmp/\${appName}/build/flutter_assets/*" ;',
          'rm -rf "/tmp/\${appName}/build/linux/arm64/debug/bundle/data/flutter_assets/*" ;',
          'rm -rf "/tmp/\${appName}/build/linux/arm64/debug/bundle/data/icudtl.dat" ;',
          // and replace them by host build artifacts
          'cp /tmp/\${appName}/$hostBuildClonePath/flutter_assets/*  /tmp/\${appName}/build/flutter_assets ;',
          'cp /tmp/\${appName}/$hostBuildClonePath/flutter_assets/*  /tmp/\${appName}/build/linux/arm64/debug/bundle/data/flutter_assets ;',
          'cp /tmp/\${appName}/$hostIcuDataClone/icudtl.dat  /tmp/\${appName}/build/linux/arm64/debug/bundle/data ;',
          // finally run the app
          r'DISPLAY=:0 /tmp/\${appName}/build/linux/arm64/debug/bundle/\${appName} ;'
        ],
      ),
      forwardPortCommand: <String>[
        'ssh',
        '-o',
        'BatchMode=yes',
        '-o',
        'ExitOnForwardFailure=yes',
        if (ipv6) '-6',
        '-L',
        '$formattedLoopbackIp:\${hostPort}:$formattedLoopbackIp:\${devicePort}',
        sshTarget,
        "echo 'Port forwarding success'; read",
      ],
      forwardPortSuccessRegex: RegExp('Port forwarding success'),
      screenshotCommand: null,
    );

    customDevicesConfig.add(config);

    logger.printSpaces();

    logger.printSuccess(
      'Successfully added custom device to config file at "${customDevicesConfig.configPath}".',
    );

    logger.printSpaces();

    return 0;
  }

  (String id, String label) getRemoteDeviceIdAndLabel(
    CustomDeviceConfig? predefinedConfig,
  ) {
    String id = predefinedConfig?.id ?? '';
    String label = predefinedConfig?.label ?? '';

    if (id.isEmpty) {
      logger.printStatus(
        'Please enter the id you want to device to have. Must contain only alphanumeric or underscore characters. (example: pi)',
      );

      id = Input(
        prompt: 'Device Id:',
        validator: (s) {
          if (!RegExp(r'^\w+$').hasMatch(s.trim())) {
            throw ValidationError('Invalid input. Please try again.');
          } else if (_isDuplicatedDeviceId(s.trim())) {
            throw ValidationError('Device with this id already exists.');
          }
          return true;
        },
      ).interact().trim();

      logger.printSpaces();
    }

    if (label.isEmpty) {
      logger.printStatus(
        'Please enter the label of the device, which is a slightly more verbose name for the device. (example: Raspberry Pi Model 4B)',
      );
      label = Input(
        prompt: 'Device label:',
        validator: (s) {
          if (s.trim().isNotEmpty) {
            return true;
          }
          throw ValidationError('Input is empty. Please try again.');
        },
      ).interact();

      logger.printSpaces();
    }

    return (id, label);
  }

  bool _isDuplicatedDeviceId(String s) {
    return customDevicesConfig.devices.any((element) => element.id == s);
  }

  /// returns new device id by adding a number to the end of it
  ///
  /// for example: if the id is "pi-4" and this id already exists
  /// then we update the id to "pi-4-1" and check again
  /// if the new id already exists, then we update it to "pi-4-2" and so on
  String _suggestIdForDuplicatedDeviceId(String s) {
    int i = 1;

    while (_isDuplicatedDeviceId('$s-$i')) {
      i++;
    }

    return '$s-$i';
  }
}
