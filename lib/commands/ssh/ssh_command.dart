// ignore_for_file: implementation_imports

import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/commands/ssh/commands/create_connection_command.dart';
import 'package:snapp_cli/commands/ssh/commands/test_connection_command.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
class SshCommand extends BaseSnappCommand {
  SshCommand({
    required super.flutterSdkManager,
  }) {
    // Create an SSH connection to the remote device
    addSubcommand(
      CreateConnectionCommand(flutterSdkManager: flutterSdkManager),
    );

    // Test an SSH connection to the remote device
    addSubcommand(
      TestConnectionCommand(flutterSdkManager: flutterSdkManager),
    );
  }

  @override
  final String description = 'Create and manage SSH connections';

  @override
  final String name = 'ssh';
}
