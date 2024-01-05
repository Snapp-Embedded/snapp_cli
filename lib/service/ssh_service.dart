// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/service/logger_service.dart';
import 'package:snapp_cli/snapp_cli.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:snapp_cli/service/interaction_service.dart';
import 'package:snapp_cli/utils/process.dart';

class SshService {
  SshService({
    required FlutterSdkManager flutterSdkManager,
  })  : hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform),
        processRunner = ProcessUtils(
          processManager: flutterSdkManager.processManager,
          logger: flutterSdkManager.logger,
        );

  final HostRunnerPlatform hostPlatform;

  final ProcessUtils processRunner;

  Future<bool> tryPingDevice(String pingTarget, bool ipv6) async {
    final spinner = interaction.spinner(
      inProgressMessage: 'Pinging device to check if it is reachable',
      doneMessage: 'Pinging device completed',
      failedMessage: 'Pinging device failed',
    );

    await Future.delayed(Duration(seconds: 2));

    final RunResult? result = await processRunner.runCommand(
      hostPlatform.pingCommand(ipv6: ipv6, pingTarget: pingTarget),
      parseResult: (result) => result,
      parseFail: (e, s) {
        logger.info(
          'Something went wrong while pinging the device.',
        );
        logger.detail(
          'Exception: $e \nStack: $s',
        );

        return null;
      },
      spinner: spinner,
      label: 'pingCommand',
      logger: logger,
    );

    if (result == null || result.exitCode != 0) {
      return false;
    }

    // If the user doesn't configure a ping success regex, any ping with exitCode zero
    // is good enough. Otherwise we check if either stdout or stderr have a match of
    // the pingSuccessRegex.
    final RegExp? pingSuccessRegex = hostPlatform.pingSuccessRegex;

    return pingSuccessRegex == null ||
        pingSuccessRegex.hasMatch(result.stdout) ||
        pingSuccessRegex.hasMatch(result.stderr);
  }

  /// Creates a directory in the user's home directory
  /// to store the snapp_cli related files like ssh keys
  Future<Directory> createSnappCliDirectory() async {
    final String homePath = hostPlatform.homePath;
    final String snappCliDirectoryPath = '$homePath/.snapp_cli';

    final snappCliDirectory = Directory(snappCliDirectoryPath);

    if (!(await snappCliDirectory.exists())) {
      await snappCliDirectory.create();
    }

    return snappCliDirectory;
  }

  /// Generates a ssh key file in the snapp_cli directory
  Future<({File privateKey, File publicKey})> generateSshKeyFile(
    ProcessUtils processRunner,
    Directory snappCliDir,
  ) async {
    // generate random 6 digit file name
    final randomNumber = Random().nextInt(900000) + 100000;

    final keyFile = File('${snappCliDir.path}/id_rsa_$randomNumber');

    final RunResult? result = await processRunner.runCommand(
      hostPlatform.generateSshKeyCommand(filePath: keyFile.path),
      parseResult: (result) => result,
      parseFail: (e, s) {
        throwToolExit(
            'Something went wrong while generating the ssh key. \nException: $e \nStack: $s');
      },
      label: 'generateSshKeyCommand',
      logger: logger,
    );

    if (result?.exitCode != 0) {
      throwToolExit('Something went wrong while generating the ssh key.');
    }

    return (privateKey: keyFile, publicKey: File('${keyFile.path}.pub'));
  }

  /// Adds the ssh key to the ssh-agent
  Future<void> addSshKeyToAgent(File sshKey) async {
    await processRunner.runCommand(
      hostPlatform.addSshKeyToAgent(filePath: sshKey.path),
      parseFail: (e, s) {
        throwToolExit(
            'Something went wrong while adding the key to ssh-agent. \nException: $e \nStack: $s');
      },
    );
  }

  Future<void> copySshKeyToRemote(
    File sshKeyFile,
    String username,
    InternetAddress ip,
  ) async {
    final client = SSHClient(
      await SSHSocket.connect(
        ip.address,
        22,
        timeout: Duration(seconds: 10),
      ),
      username: username,
      onPasswordRequest: () {
        stdout.write('Password: ');
        stdin.echoMode = false;
        return stdin.readLineSync() ?? exit(1);
      },
    );

    final session = await client.execute('cat >> .ssh/authorized_keys');
    await session.stdin.addStream(sshKeyFile.openRead().cast());

    // Close the sink to send EOF to the remote process.
    await session.stdin.close();

    // Wait for session to exit to ensure all data is flushed to the remote process.
    await session.done;

    client.close();

    // You can get the exit code after the session is done
    logger.detail('SSH Session ExitCode: ${session.exitCode}');
    logger.detail('SSH Session stdout: ${session.stdout}');
    logger.detail('SSH Session stderr: ${session.stderr}');
  }

  Future<bool> createPasswordLessSshConnection(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final isDeviceReachable = await tryPingDevice(
      ip.address,
      ip.type == InternetAddressType.IPv6,
    );

    if (!isDeviceReachable) {
      logger.info(
        'Could not reach the device with the given IP-address.',
      );

      final continueWithoutPing = interaction.confirm(
        'Do you want to continue anyway?',
        defaultValue: true, // this is optional
      );

      if (!continueWithoutPing) {
        logger.spaces();
        logger.info('Check your device IP-address and try again.');

        return false;
      }
    }

    logger.spaces();

    final spinner = interaction.runSpinner(
      inProgressMessage: 'Preparing SSH connection',
      doneMessage: 'Preparing SSH connection completed',
      failedMessage: 'Preparing SSH connection failed',
    );

    // create a directory in the user's home directory
    final snappCliDirectory = await createSnappCliDirectory();

    final sshKeys = await generateSshKeyFile(processRunner, snappCliDirectory);

    await addSshKeyToAgent(sshKeys.privateKey);

    spinner.done();

    await copySshKeyToRemote(
      sshKeys.publicKey,
      username,
      ip,
    );

    logger.spaces();

    return true;
  }

  /// Checks if the device is reachable via ssh
  Future<bool> testPasswordLessSshConnection(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final String sshTarget = ip.sshTarget(username);

    final spinner = interaction.spinner(
      inProgressMessage: 'Testing SSH connection',
      doneMessage: 'Testing SSH connection completed',
      failedMessage: 'Testing SSH connection failed',
    );

    final result = await processRunner.runCommand(
      hostPlatform.sshCommand(
        ipv6: ip.type == InternetAddressType.IPv6,
        sshTarget: sshTarget,
        command: 'echo "Test SSH Connection"',
        addHostToKnownHosts: addHostToKnownHosts,
        lastCommand: true,
      ),
      parseResult: (result) {
        return true;
      },
      parseFail: (e, s) {
        logger.info(
            'Something went wrong while trying to connect to the device via ssh.');
        logger.detail(
          'Exception: $e \nStack: $s',
        );
        return false;
      },
      spinner: spinner,
      label: 'testPasswordLessSshConnection',
      logger: logger,
    );

    return result ?? false;
  }
}
