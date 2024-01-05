// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/base/common.dart';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:snapp_cli/commands/devices/devices_command.dart';
import 'package:snapp_cli/commands/bootstrap/bootstarp_command.dart';
import 'package:snapp_cli/commands/ssh/ssh_command.dart';
import 'package:snapp_cli/flutter_sdk.dart';
import 'package:snapp_cli/service/logger_service.dart';
import 'package:snapp_cli/service/interaction_service.dart';
import 'package:snapp_cli/utils/process.dart';
import 'package:snapp_cli/service/update_service.dart';

const deviceIdOption = FlutterGlobalOptions.kDeviceIdOption;

class SnappCliCommandRunner extends CommandRunner<int> {
  SnappCliCommandRunner({required this.flutterSdkManager})
      : super(
          'snapp_cli',
          'A command-line tool to manage custom devices for flutter',
        ) {
    // Add the device id option to all commands
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Print verbose output.',
        negatable: false,
      )
      ..addOption(
        deviceIdOption,
        abbr: 'd',
        help: 'Target device id or name (prefixes allowed).',
      );

    // Add the setup command to the command runner
    addCommand(BootstrapCommand(flutterSdkManager: flutterSdkManager));

    // Add the devices command to the command runner
    addCommand(DevicesCommand(flutterSdkManager: flutterSdkManager));

    // Create and manage SSH connections
    addCommand(SshCommand(flutterSdkManager: flutterSdkManager));
  }

  final FlutterSdkManager flutterSdkManager;

  final UpdateService updateService = UpdateService();

  @override
  Future<int?> run(Iterable<String> args) async {
    final argResults = parse(args);

    if (argResults['verbose'] == true) {
      logger.level = Level.verbose;

      logger.detail('Verbose mode enabled');
    }

    logger.spacer;

    await _checkConfigs();

    await _checkForUpdates();

    logger.spaces();

    return runCommand(argResults);
  }

  Future<void> _checkConfigs() async {
    final areCustomDevicesEnabled = flutterSdkManager.areCustomDevicesEnabled;

    final isLinuxEnabled = flutterSdkManager.isLinuxEnabled;

    if (!areCustomDevicesEnabled || !isLinuxEnabled) {
      logger.spaces();

      logger.info(
        '''
To use snapp_cli you need to enable custom devices and linux configs.
This is a one time setup and will not be required again.
''',
      );

      logger.spaces();

      final enableConfigs = interaction.confirm(
        'Do you want to enable them now?',
        defaultValue: true, // this is optional
      );

      logger.spaces();

      if (!enableConfigs) {
        throwToolExit('''
Custom devices and linux configs are required.
if don't want to enable them now, you can enable them manually by running the following command:

flutter config --enable-custom-devices --enable-linux-desktop
        ''');
      }

      final processRunner = flutterSdkManager.processRunner;

      await processRunner.runCommand(
        <String>[
          'flutter',
          'config',
          '--enable-custom-devices',
          '--enable-linux-desktop',
        ],
        parseResult: (runResult) {},
        parseFail: (e, s) {
          throwToolExit('''
Something went wrong.
Could not enable custom devices and linux configs.
Please enable them manually by running the following command:

flutter config --enable-custom-devices --enable-linux-desktop

Error: $e
Stacktrace: $s
''');
        },
        spinner: interaction.spinner(
          inProgressMessage: 'Enabling custom devices and linux configs...',
          doneMessage: 'Configs enabled successfully!',
          failedMessage: 'Enabling custom devices and linux configs failed!',
        ),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    final bool isUpdateAvailable;
    try {
      isUpdateAvailable = await updateService.isUpdateAvailable();
    } catch (e, s) {
      logger.detail(
        'Something went wrong. During checking for updates. \n $e \n $s',
      );

      return;
    }

    logger.spaces();

    if (isUpdateAvailable) {
      logger.info('A new version of snapp_cli is available!');

      final updateConfirmed = interaction.confirm(
        'Do you want to update now?',
        defaultValue: true,
      );

      logger.spaces();

      if (!updateConfirmed) return;

      final spinner = interaction.runSpinner(
        inProgressMessage: 'Updating snapp_cli...',
        doneMessage: 'Update process completed!',
        failedMessage: 'snapp_cli update failed!',
      );

      final result = await updateService.update();

      if (result.exitCode != 0) {
        spinner.failed();
        throwToolExit('Something went wrong. \n ${result.stderr}');
      }

      spinner.done();

      logger.spaces();

      logger.info(result.stdout);

      logger.spaces();

      logger.success('Snapp_cli updated successfully! 🎉');

      exit(0);
    }
  }
}
