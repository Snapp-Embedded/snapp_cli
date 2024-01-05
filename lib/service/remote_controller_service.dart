// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_tools/src/base/process.dart';
import 'package:process/process.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/service/logger_service.dart';
import 'package:snapp_cli/snapp_cli.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:snapp_cli/service/interaction_service.dart';
import 'package:snapp_cli/utils/process.dart';

class RemoteControllerService {
  RemoteControllerService({
    required FlutterSdkManager flutterSdkManager,
  })  : hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform),
        processManager = flutterSdkManager.processManager,
        processRunner = ProcessUtils(
          processManager: flutterSdkManager.processManager,
          logger: flutterSdkManager.logger,
        );

  final HostRunnerPlatform hostPlatform;

  final ProcessManager processManager;
  final ProcessUtils processRunner;

  /// finds flutter in the remote machine using ssh connection
  /// returns the path of flutter if found it
  /// otherwise returns null
  Future<String?> findFlutterPath(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final spinner = interaction.spinner(
      inProgressMessage: 'search for flutter path on remote device.',
      doneMessage: 'search for flutter path completed',
      failedMessage: 'search for flutter path failed',
    );

    final output = await processRunner.runCommand(
      hostPlatform.sshCommand(
        ipv6: ip.type == InternetAddressType.IPv6,
        sshTarget: ip.sshTarget(username),
        command:
            'find / -type f -name "flutter" -path "*/flutter/bin/*" 2>/dev/null',
        addHostToKnownHosts: addHostToKnownHosts,
      ),
      throwOnError: false,
      parseResult: (runResult) {
        final output = runResult.stdout.trim();

        if (runResult.exitCode != 0 && output.isEmpty) {
          logger.spaces();

          return null;
        }

        return output;
      },
      parseFail: (e, s) {
        logger.detail(
          'Something went wrong while trying to find flutter. \n $e \n $s',
        );

        logger.spaces();

        return null;
      },
      spinner: spinner,
      label: 'Find Flutter',
      logger: logger,
    );

    logger.detail('Find Flutter output: $output');

    logger.spaces();

    if (output == null) return null;

    final outputLinesLength = output.split('\n').length;
    final isOutputMultipleLines = outputLinesLength > 1;

    if (!isOutputMultipleLines) {
      logger.info('We found flutter in "$output" in the remote machine. ');

      final flutterSdkPathConfirmation = interaction.confirm(
        'Do you want to use this path?',
        defaultValue: true, // this is optional
      );

      return flutterSdkPathConfirmation ? output : null;
    } else {
      final outputLines = output
          .split('\n')
          .map((e) => e.trim())
          .toList()
          .sublist(0, min(2, outputLinesLength));

      logger.info('We found multiple flutter paths in the remote machine. ');

      return interaction.select(
        'Please select the path of flutter you want to use.',
        options: outputLines,
      );
    }
  }

  Future<String?> findFlutterPathInteractive(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    return processRunner.runCommand<String>(
      hostPlatform.sshCommand(
        ipv6: ip.type == InternetAddressType.IPv6,
        sshTarget: ip.sshTarget(username),
        command:
            'find / -type f -name "flutter" -path "*/flutter/bin/*" 2>/dev/null',
        addHostToKnownHosts: addHostToKnownHosts,
      ),
      throwOnError: false,
      parseResult: (runResult) {
        final output = runResult.stdout.trim();

        if (runResult.exitCode != 0 && output.isEmpty) {
          return null;
        }

        final outputLines = output.split('\n').map((e) => e.trim()).toList();
        final outputLinesLength = outputLines.length;
        final isOutputMultipleLines = outputLinesLength > 1;

        return isOutputMultipleLines ? outputLines.first : output;
      },
      parseFail: (e, s) {
        logger.detail(
          'Something went wrong while trying to find flutter. \n $e \n $s',
        );

        return null;
      },
      label: 'Find Flutter',
      logger: logger,
    );
  }

  /// finds snapp_installer in the remote machine using ssh connection
  /// returns the path of snapp_installer if found it
  /// otherwise returns null
  Future<String?> findSnappInstallerPath(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final spinner = interaction.spinner(
      inProgressMessage: 'search for snapp_installer path on remote device.',
      doneMessage: 'search for snapp_installer path completed',
      failedMessage: 'search for snapp_installer path failed',
    );

    final output = await processRunner.runCommand(
      hostPlatform.sshCommand(
        ipv6: ip.type == InternetAddressType.IPv6,
        sshTarget: ip.sshTarget(username),
        command:
            'find / -type f -name "snapp_installer" -path "*/snapp_installer/bin/*" 2>/dev/null',
        addHostToKnownHosts: addHostToKnownHosts,
      ),
      throwOnError: false,
      parseResult: (runResult) {
        final output = runResult.stdout.trim();

        if (runResult.exitCode != 0 && output.isEmpty) {
          logger.spaces();

          return null;
        }

        return output;
      },
      parseFail: (e, s) {
        logger.detail(
          'Something went wrong while trying to find flutter. \n $e \n $s',
        );

        logger.spaces();

        return null;
      },
      spinner: spinner,
      label: 'Find Snapp Installer',
      logger: logger,
    );

    logger.spaces();

    if (output == null) return null;

    final outputLinesLength = output.split('\n').length;
    final isOutputMultipleLines = outputLinesLength > 1;

    if (!isOutputMultipleLines) {
      logger.info(
          'We found snapp_installer in "$output" in the remote machine. ');

      final snappInstallerPathConfirmation = interaction.confirm(
        'Do you want to use this path?',
        defaultValue: true,
      );

      return snappInstallerPathConfirmation ? output : null;
    }

    return null;
  }

  /// finds snapp_installer in the remote machine using ssh connection interactively
  ///
  /// this method is not communicating with the user directly
  Future<String?> findSnappInstallerPathInteractive(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    return processRunner.runCommand<String>(
      hostPlatform.sshCommand(
        ipv6: ip.type == InternetAddressType.IPv6,
        sshTarget: ip.sshTarget(username),
        command:
            'find / -type f -name "snapp_installer" -path "*/snapp_installer/bin/*" 2>/dev/null',
        addHostToKnownHosts: addHostToKnownHosts,
      ),
      throwOnError: false,
      parseResult: (runResult) {
        final output = runResult.stdout.trim();

        if (runResult.exitCode != 0 && output.isEmpty) {
          return null;
        }

        final outputLines = output.split('\n').map((e) => e.trim()).toList();
        final outputLinesLength = outputLines.length;
        final isOutputMultipleLines = outputLinesLength > 1;

        return isOutputMultipleLines ? outputLines.first : output;
      },
      parseFail: (e, s) {
        logger.detail(
          'Something went wrong while trying to find snapp_installer. \n $e \n $s',
        );

        return null;
      },
      logger: logger,
      label: 'Find Snapp Installer',
    );
  }

  /// install snapp_installer in the remote machine using ssh connection
  ///
  /// we will use snapp_installer[https://github.com/Snapp-Embedded/snapp_installer] to install flutter in the remote machine
  /// with this method you can first install snapp_installer
  ///
  /// returns true if snapp_installer installed successfully
  /// otherwise returns false
  Future<bool> installSnappInstallerOnRemote(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final RunResult result;
    try {
      result = await processRunner.runWithOutput(
        hostPlatform.sshCommand(
          ipv6: ip.isIpv6,
          sshTarget: ip.sshTarget(username),
          lastCommand: true,
          command:
              'bash <(curl -fSL https://raw.githubusercontent.com/Snapp-Embedded/snapp_installer/main/installer.sh)',
          addHostToKnownHosts: addHostToKnownHosts,
        ),
        processManager: processManager,
        logger: logger,
      );
    } catch (e, s) {
      logger.detail(
        'Something went wrong while trying to find snapp_installer. \n $e \n $s',
      );

      return false;
    } finally {
      logger.spaces();
    }

    if (result.exitCode != 0) {
      logger.info('Snapp Installer ExitCode: ${result.exitCode}');
      logger.info('Snapp Installer Stdout: ${result.stdout.trim()}');
      logger.info('Snapp Installer Stderr: ${result.stderr}');
    }

    return result.exitCode == 0;
  }

  /// in
  /// install flutter in the remote machine using ssh connection
  ///
  /// we will use snapp_installer[https://github.com/Snapp-Embedded/snapp_installer] to install flutter in the remote machine
  ///
  /// returns true if snapp_installer installed successfully
  /// otherwise returns false
  Future<bool> installFlutterOnRemote(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final snappInstallerPath = await findSnappInstallerPathInteractive(
      username,
      ip,
    );

    final RunResult result;
    try {
      result = await processRunner.runWithOutput(
        hostPlatform.sshCommand(
          ipv6: ip.isIpv6,
          sshTarget: ip.sshTarget(username),
          lastCommand: true,
          command: '$snappInstallerPath install',
          addHostToKnownHosts: addHostToKnownHosts,
        ),
        processManager: processManager,
        logger: logger,
      );
    } catch (e, s) {
      logger.detail(
        'Something went wrong while trying to install flutter on the remote. \n $e \n $s',
      );

      return false;
    } finally {
      logger.spaces();
    }

    if (result.exitCode != 0) {
      logger.info('Flutter Installer ExitCode: ${result.exitCode}');
      logger.info('Flutter Installer Stdout: ${result.stdout.trim()}');
      logger.info('Flutter Installer Stderr: ${result.stderr}');
    }

    return result.exitCode == 0;
  }
}
