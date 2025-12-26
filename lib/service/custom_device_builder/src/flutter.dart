import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/service/custom_device_builder/custom_device_builder.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';
// ignore: implementation_imports
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';

class FlutterCustomDeviceBuilder extends CustomDeviceBuilder {
  const FlutterCustomDeviceBuilder({
    required super.flutterSdkManager,
    required super.hostPlatform,
  });

  @override
  Future<CustomDeviceConfig> buildDevice(
    final DeviceConfigContext context,
  ) async {
    if (!isContextValid(context)) {
      logger.err('Device context: $context');
      throw Exception("Device setup did not produce a valid configuration.");
    }

    /// path to the icu data file on the host machine
    final hostIcuDataPath = flutterSdkManager.icuDataPath;

    /// path to the build artifacts on the remote machine
    const hostBuildClonePath = 'snapp_embedded';

    /// path to the icu data file on the remote machine
    const hostIcuDataClone = '$hostBuildClonePath/engine';

    final ipv6 = context.ipv6!;

    final sshTarget = context.sshTarget!;

    final formattedLoopbackIp = context.formattedLoopbackIp!;

    final remoteAppExecuter = context.appExecuterPath!;

    final appArchiveName = '\${appName}.tar.gz';

    return CustomDeviceConfig(
      id: context.id!,
      label: context.formattedLabel,
      sdkNameAndVersion: context.sdkName!,
      enabled: true,

      // host-platform specific, filled out later
      pingCommand: hostPlatform.pingCommand(
        ipv6: ipv6,
        pingTarget: context.targetIp!.address,
      ),
      pingSuccessRegex: hostPlatform.pingSuccessRegex,
      postBuildCommand: const <String>[],

      /// installing process of the app on the remote machine
      ///
      /// 1. create the necessary directories in the remote machine
      /// 2. compress the current project on the host without unnecessary files
      /// 3. copy the archive project file to the remote
      /// 4. extract the project on the remote
      /// 5. copy the build artifacts from host to the remote
      /// 6. copy the icu data file from host to the remote
      /// 7. remove the archive file on host after sending it to the remote
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

          // compress the current project on the host
          hostPlatform
              .compressCurrentProjectCommand(
                compressedFileName: appArchiveName,
              )
              .asString,

          // copy the archive project file to the remote
          hostPlatform
              .scpCommand(
                ipv6: ipv6,
                source: appArchiveName,
                dest: '$sshTarget:/tmp/\${appName}',
              )
              .asString,

          // extract the project on the remote
          hostPlatform
              .sshCommand(
                ipv6: ipv6,
                sshTarget: sshTarget,
                command:
                    'tar -xvf /tmp/\${appName}/$appArchiveName -C /tmp/\${appName}',
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
              )
              .asString,

          // remove the archive file on host after sending it to the remote
          hostPlatform
              .deleteFile(
                target: appArchiveName,
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
          '$remoteAppExecuter build linux --debug ;',
          // remove remote build artifacts
          'rm -rf "/tmp/\${appName}/build/flutter_assets/*" ;',
          'rm -rf "/tmp/\${appName}/build/linux/arm64/debug/bundle/data/flutter_assets/*" ;',
          'rm -rf "/tmp/\${appName}/build/linux/arm64/debug/bundle/data/icudtl.dat" ;',
          // and replace them by host build artifacts
          'cp -r /tmp/\${appName}/$hostBuildClonePath/flutter_assets/*  /tmp/\${appName}/build/flutter_assets ;',
          'cp -r /tmp/\${appName}/$hostBuildClonePath/flutter_assets/*  /tmp/\${appName}/build/linux/arm64/debug/bundle/data/flutter_assets ;',
          'cp -r /tmp/\${appName}/$hostIcuDataClone/icudtl.dat  /tmp/\${appName}/build/linux/arm64/debug/bundle/data ;',
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
  }
}
