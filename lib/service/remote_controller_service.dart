// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:interact/interact.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:process/process.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/snapp_cli.dart';
import 'package:snapp_cli/utils/common.dart';

class RemoteControllerService {
  RemoteControllerService({
    required FlutterSdkManager flutterSdkManager,
  })  : logger = flutterSdkManager.logger,
        hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform),
        processManager = flutterSdkManager.processManager,
        processRunner = ProcessUtils(
          processManager: flutterSdkManager.processManager,
          logger: flutterSdkManager.logger,
        );

  final Logger logger;

  final HostRunnerPlatform hostPlatform;

  final ProcessManager processManager;
  final ProcessUtils processRunner;

  /// finds flutter in the remote machine using ssh connection
  /// returns the path of flutter if found it
  /// otherwise returns null
  Future<String?> findFlutterPath(String username, InternetAddress ip) async {
    final spinner = Spinner(
      icon: logger.successIcon,
      rightPrompt: (done) => done
          ? 'search for Flutter path completed'
          : 'search for Flutter path on remote device.',
    ).interact();

    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.sshCommand(
          ipv6: ip.type == InternetAddressType.IPv6,
          sshTarget: ip.sshTarget(username),
          command:
              'find / -type f -name "flutter" -path "*/flutter/bin/*" 2>/dev/null',
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong while trying to find flutter. \n $e \n $s',
      );

      return null;
    } finally {
      spinner.done();

      logger.printSpaces();
    }

    logger.printTrace('Find Flutter ExitCode: ${result.exitCode}');
    logger.printTrace('Find Flutter Stdout: ${result.stdout.trim()}');
    logger.printTrace('Find Flutter Stderr: ${result.stderr}');

    final output = result.stdout.trim();

    if (result.exitCode != 0 && output.isEmpty) {
      return null;
    }

    final outputLinesLength = output.split('\n').length;
    final isOutputMultipleLines = outputLinesLength > 1;

    if (!isOutputMultipleLines) {
      logger
          .printStatus('We found flutter in "$output" in the remote machine. ');

      final flutterSdkPathConfirmation = Confirm(
        prompt: 'Do you want to use this path?',
        defaultValue: true, // this is optional
        waitForNewLine: true, // optional and will be false by default
      ).interact();

      return flutterSdkPathConfirmation ? output : null;
    } else {
      final outputLines = output
          .split('\n')
          .map((e) => e.trim())
          .toList()
          .sublist(0, min(2, outputLinesLength));

      logger.printStatus(
          'We found multiple flutter paths in the remote machine. ');

      final flutterSdkPathSelection = Select(
        prompt: 'Please select the path of flutter you want to use.',
        options: outputLines,
      ).interact();

      return outputLines[flutterSdkPathSelection];
    }
  }

  /// finds snapp_installer in the remote machine using ssh connection
  /// returns the path of snapp_installer if found it
  /// otherwise returns null
  Future<String?> findSnappInstallerPath(
    String username,
    InternetAddress ip,
  ) async {
    final spinner = Spinner(
      icon: logger.successIcon,
      rightPrompt: (done) => done
          ? 'search for snapp_installer path completed'
          : 'search for snapp_installer path on remote device.',
    ).interact();

    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.sshCommand(
          ipv6: ip.type == InternetAddressType.IPv6,
          sshTarget: ip.sshTarget(username),
          command:
              'find / -type f -name "snapp_installer" -path "*/snapp_installer/bin/*" 2>/dev/null',
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong while trying to find snapp_installer. \n $e \n $s',
      );

      return null;
    } finally {
      spinner.done();

      logger.printSpaces();
    }

    logger.printTrace('Find snapp_installer ExitCode: ${result.exitCode}');
    logger.printTrace('Find snapp_installer Stdout: ${result.stdout.trim()}');
    logger.printTrace('Find snapp_installer Stderr: ${result.stderr}');

    final output = result.stdout.trim();

    if (result.exitCode != 0 && output.isEmpty) {
      return null;
    }

    final outputLinesLength = output.split('\n').length;
    final isOutputMultipleLines = outputLinesLength > 1;

    if (!isOutputMultipleLines) {
      logger.printStatus(
          'We found snapp_installer in "$output" in the remote machine. ');

      final snappInstallerPathConfirmation = Confirm(
        prompt: 'Do you want to use this path?',
        defaultValue: true, // this is optional
        waitForNewLine: true, // optional and will be false by default
      ).interact();

      return snappInstallerPathConfirmation ? output : null;
    }

    return null;
  }

  /// finds snapp_installer in the remote machine using ssh connection interactively
  ///
  /// this method is not communicating with the user directly
  Future<String?> findSnappInstallerPathInteractive(
    String username,
    InternetAddress ip,
  ) async {
    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.sshCommand(
          ipv6: ip.type == InternetAddressType.IPv6,
          sshTarget: ip.sshTarget(username),
          command:
              'find / -type f -name "snapp_installer" -path "*/snapp_installer/bin/*" 2>/dev/null',
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong while trying to find snapp_installer. \n $e \n $s',
      );

      return null;
    } finally {
      logger.printSpaces();
    }

    logger.printTrace('Find snapp_installer ExitCode: ${result.exitCode}');
    logger.printTrace('Find snapp_installer Stdout: ${result.stdout.trim()}');
    logger.printTrace('Find snapp_installer Stderr: ${result.stderr}');

    final output = result.stdout.trim();

    if (result.exitCode != 0 && output.isEmpty) {
      return null;
    }

    final outputLinesLength = output.split('\n').length;
    final isOutputMultipleLines = outputLinesLength > 1;

    return isOutputMultipleLines ? null : output;
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
    InternetAddress ip,
  ) async {
    final process = await processRunner.runWithOutput(
      hostPlatform.sshCommand(
        ipv6: ip.isIpv6,
        sshTarget: ip.sshTarget(username),
        lastCommand: true,
        command:
            'bash <(curl -fSL https://raw.githubusercontent.com/Snapp-Embedded/snapp_installer/main/installer.sh)',
      ),
      processManager: processManager,
      logger: logger,
    );

    return process.exitCode == 0;
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
    InternetAddress ip,
  ) async {
    final snappInstallerPath = await findSnappInstallerPathInteractive(
      username,
      ip,
    );

    final process = await processRunner.runWithOutput(
      hostPlatform.sshCommand(
        ipv6: ip.isIpv6,
        sshTarget: ip.sshTarget(username),
        lastCommand: true,
        command: '$snappInstallerPath install',
      ),
      processManager: processManager,
      logger: logger,
      showStderr: true,
    );

    return process.exitCode == 0;
  }
}