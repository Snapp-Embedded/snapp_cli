// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/service/ssh_service.dart';

class TestConnectionCommand extends BaseSnappCommand {
  TestConnectionCommand({
    required super.flutterSdkManager,
  }) : sshService = SshService(flutterSdkManager: flutterSdkManager);

  @override
  String get description =>
      'Test a PasswordLess SSH connection to the remote device';

  @override
  String get name => 'test-connection';

  final SshService sshService;

  @override
  FutureOr<int>? run() async {
    logger.spaces();

    final (ip, username) = interaction.getDeviceInfoInteractively(
      customDevicesConfig,
      'To test an SSH connection to the remote device, we need an IP address and a username',
    );

    final sshConnectionCreated = await sshService.testPasswordLessSshConnection(
      username,
      ip,
    );

    if (sshConnectionCreated) {
      logger.success('SSH connection to the remote device is working!');
      return 0;
    } else {
      logger.fail('SSH connection to the remote device is not working!');
      return 1;
    }
  }
}
