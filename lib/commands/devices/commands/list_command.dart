// ignore_for_file: implementation_imports

import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/utils/process.dart';

/// List all custom devices added to the Flutter SDK with custom-devices command
/// it will utilize the `flutter custom-devices list` command to show the list
class ListCommand extends BaseSnappCommand {
  ListCommand({
    required super.flutterSdkManager,
  });

  @override
  final name = 'list';

  @override
  final description = 'List all custom devices added to the Flutter SDK';

  @override
  Future<int> run() async {
    final result = await processRunner.runCommand(
      ['flutter', 'custom-devices', 'list'],
      parseResult: (result) => result,
      spinner: interaction.spinner(
        inProgressMessage: 'Searching for custom devices...',
        doneMessage: 'Searching for custom devices completed!',
        failedMessage: 'Searching for custom devices failed!',
      ),
    );

    logger.spaces();

    logger.info(result!.stdout);

    return result.exitCode;
  }
}
