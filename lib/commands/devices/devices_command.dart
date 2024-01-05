// ignore_for_file: implementation_imports

import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/commands/devices/commands/add_command.dart';
import 'package:snapp_cli/commands/devices/commands/delete_command.dart';
import 'package:snapp_cli/commands/devices/commands/install_flutter_command.dart';
import 'package:snapp_cli/commands/devices/commands/list_command.dart';
import 'package:snapp_cli/commands/devices/commands/update_ip_command.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
class DevicesCommand extends BaseSnappCommand {
  DevicesCommand({
    required super.flutterSdkManager,
  }) {
    // List command to list all custom devices
    addSubcommand(
      ListCommand(flutterSdkManager: flutterSdkManager),
    );

    // Add command to add a new custom device
    addSubcommand(
      AddCommand(flutterSdkManager: flutterSdkManager),
    );

    // Delete command to delete a custom device
    addSubcommand(
      DeleteCommand(flutterSdkManager: flutterSdkManager),
    );

    // Update IP command to update the IP address of a custom device
    addSubcommand(
      UpdateIpCommand(flutterSdkManager: flutterSdkManager),
    );

    // Install Flutter command to install Flutter on a remote device
    addSubcommand(
      InstallFlutterCommand(flutterSdkManager: flutterSdkManager),
    );
  }

  @override
  final String description = 'Manage custom devices in the Flutter SDK';

  @override
  final String name = 'devices';
}
