// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';
import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/configs/predefined_devices.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/service/remote_controller_service.dart';
import 'package:snapp_cli/service/ssh_service.dart';
import 'package:snapp_cli/utils/common.dart';

/// Perform a comprehensive setup for a device.(add custom device,ssh connection, install flutter,...)
class BootstrapCommand extends BaseSnappCommand {
  BootstrapCommand({
    required super.flutterSdkManager,
  })  : sshService = SshService(flutterSdkManager: flutterSdkManager),
        remoteControllerService = RemoteControllerService(
          flutterSdkManager: flutterSdkManager,
        );

  final SshService sshService;
  final RemoteControllerService remoteControllerService;

  @override
  final name = 'bootstrap';

  @override
  final description =
      'perform a comprehensive setup for a device.(add custom device,ssh connection, install flutter,...)';

  @override
  Future<int> run() async {
    logger.spaces();

    logger.info('''
Bootstrap command is a way to setup a device from scratch.
It will add a new device to custom devices, create a ssh connection to the device,
install flutter on the device and finally help you to run your app on the device.

let's start! \n
    ''');

    logger.spaces();

    final addCommandOptions = [
      'Express (recommended)',
      'Custom',
    ];

    final commandIndex = interaction.selectIndex(
      'Please select the type of device you want to setup.',
      options: addCommandOptions,
    );

    if (commandIndex == 0) {
      return _setupPredefinedDevice();
    }

    return _setupCustomDevice();
  }

  Future<int> _setupPredefinedDevice() async {
    logger.spaces();

    final deviceKey = interaction.select(
      'Select your device',
      options: predefinedDevices.keys.toList(),
    );

    var predefinedDeviceConfig = predefinedDevices[deviceKey];

    if (predefinedDeviceConfig == null) {
      throwToolExit(
          'Something went wrong while trying to setup predefined $deviceKey device.');
    }

    /// check if the device id already exists in the config file
    /// update the id if it
    if (_isDuplicatedDeviceId(predefinedDeviceConfig.id)) {
      predefinedDeviceConfig = predefinedDeviceConfig.copyWith(
        id: _suggestIdForDuplicatedDeviceId(predefinedDeviceConfig.id),
      );
    }

    return _setupCustomDevice(predefinedConfig: predefinedDeviceConfig);
  }

  Future<int> _setupCustomDevice({CustomDeviceConfig? predefinedConfig}) async {
    logger.spaces();

    // get remote device id and label from the user
    final id = predefinedConfig?.id.isNotEmpty == true
        ? predefinedConfig!.id
        : interaction.readDeviceId(customDevicesConfig);

    final label = predefinedConfig?.label.isNotEmpty == true
        ? predefinedConfig!.label
        : interaction.readDeviceLabel();

    // get remote device ip and username from the user
    logger.spaces();

    logger.info('to setup a new device, we need an IP address and a username.');

    final targetIp = interaction.readDeviceIp(
        description:
            'Please enter the IP-address of the device. (example: 192.168.1.101)');

    final username = interaction.readDeviceUsername(
      description:
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

    logger.spaces();

    bool remoteHasSshConnection =
        await sshService.testPasswordLessSshConnection(username, targetIp);

    if (!remoteHasSshConnection) {
      logger.fail(
        'could not establish a password-less ssh connection to the remote device. \n',
      );

      logger.info(
          'We can create a ssh connection with the remote device, do you want to try it?');

      final continueWithoutPing = interaction.confirm(
        'Create a ssh connection?',
        defaultValue: true,
      );

      if (!continueWithoutPing) {
        logger.spaces();
        logger.info(
            'Check your ssh connection with the remote device and try again.');
        return 1;
      }

      logger.spaces();

      final sshConnectionCreated =
          await sshService.createPasswordLessSshConnection(username, targetIp);

      if (sshConnectionCreated) {
        logger.success('SSH connection to the remote device is created!');
        remoteHasSshConnection = true;
      } else {
        logger.fail('Could not create SSH connection to the remote device!');
        return 1;
      }
    }

    logger.spaces();

    logger.info(
      'We need the exact path of your flutter command line tools on the remote device. '
      'We will use this path to run flutter commands on the remote device like "flutter build linux --debug". \n',
    );

    String remoteRunnerCommand =
        await _provideFlutterCommandRunner(username, targetIp);

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

    logger.spaces();

    logger.success(
      'Successfully added custom device to config file at "${customDevicesConfig.configPath}".',
    );

    logger.spaces();

    return 0;
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

  Future<String> _provideFlutterCommandRunner(
    String username,
    InternetAddress targetIp,
  ) async {
    final hostFlutterVersion =
        flutterSdkManager.flutterVersion.frameworkVersion;

    final possibleFlutterPath =
        await remoteControllerService.findFlutterPath(username, targetIp);

    // if we found the flutter path on the remote machine
    // then we need to check if the version of the remote flutter is the same as the host flutter
    if (possibleFlutterPath != null) {
      final remoteFlutterVersion =
          await remoteControllerService.findFlutterVersion(
        username,
        targetIp,
        possibleFlutterPath,
      );

      logger.detail('remote flutter version: $remoteFlutterVersion');
      logger.detail('host flutter version: $hostFlutterVersion');

      if (remoteFlutterVersion == hostFlutterVersion) {
        logger.success(
            'You have flutter installed on the remote machine with the same version as your host machine.');
        logger.spaces();

        return possibleFlutterPath;
      } else {
        return _fixConflictVersions(
          username,
          targetIp,
          hostFlutterVersion,
          remoteFlutterVersion!,
        );
      }
    }

    logger.info(
        'Could not find flutter in the remote machine automatically. \n\n'
        'We need the exact path of your flutter command line tools on the remote device. \n'
        'Now you have two options: \n'
        '1. You can enter the path to flutter manually. \n'
        '2. We can install flutter on the remote machine for you. \n');

    logger.spaces();

    final provideFlutterPathOption = interaction.selectIndex(
      'Please select one of the options:',
      options: [
        'Enter the path to flutter manually',
        'Install flutter on the remote machine',
      ],
    );

    logger.spaces();

    if (provideFlutterPathOption == 0) {
      return interaction.readFlutterManualPath();
    }

    return _installFlutterOnRemote(username, targetIp, hostFlutterVersion);
  }

  Future<String> _fixConflictVersions(
    String username,
    InternetAddress targetIp,
    String hostFlutterVersion,
    String remoteFlutterVersion,
  ) {
    logger.info(
      'To be able to run your app on the remote device, You need to have the same version of flutter on both machines. \n\n'
      'Currently, you have a different version of flutter on the remote machine. \n'
      'Remote flutter version: $remoteFlutterVersion \n'
      'Host flutter version: $hostFlutterVersion \n\n'
      'Now you have two options: \n'
      '1. You can manually update your host machine to the same version as the remote machine. \n'
      '2. We can install the same version of flutter on the remote machine for you. \n',
    );

    logger.spaces();

    final provideFlutterPathOption = interaction.selectIndex(
      'Please select one of the options:',
      options: [
        'Manually update your host',
        'Install the same version on the remote',
      ],
    );

    logger.spaces();

    if (provideFlutterPathOption == 0) {
      logger.info(
        'Please update your host machine to the same version as the remote machine and try again.',
      );

      throwToolExit('Host flutter version is different from the remote.');
    }

    return _installFlutterOnRemote(username, targetIp, hostFlutterVersion);
  }

  Future<String> _installFlutterOnRemote(
    String username,
    InternetAddress ip,
    String version,
  ) async {
    final snappInstallerPath = await remoteControllerService
        .findSnappInstallerPathInteractive(username, ip);

    if (snappInstallerPath == null) {
      logger.info(
        '''
snapp_installer is not installed on the device
but don't worry, we will install it for you.
''',
      );

      logger.spaces();

      final snappInstallerInstalled = await remoteControllerService
          .installSnappInstallerOnRemote(username, ip);

      if (!snappInstallerInstalled) {
        throwToolExit('Could not install snapp_installer on the device!');
      }

      logger.success(
        '''
snapp_installer is installed on the device!
Now we can install flutter on the device with the help of snapp_installer.
''',
      );
    }

    logger.spaces();

    final flutterInstalled = await remoteControllerService
        .installFlutterOnRemote(username, ip, version: version);

    if (!flutterInstalled) {
      throwToolExit('Could not install flutter on the device!');
    }

    logger.success('Flutter is installed on the device!');

    return (await remoteControllerService.findFlutterPathInteractive(
      username,
      ip,
    ))!;
  }
}
