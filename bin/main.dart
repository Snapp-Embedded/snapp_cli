import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:snapp_cli/snapp_cli.dart';

Future<void> main(List<String> arguments) async {
  late int exitCode;

  final FlutterSdkManager sdkManager = FlutterSdkManager();

  try {
    /// Initialize connection to the flutter sdk
    await sdkManager.initialize();

    exitCode = await runInContext(() async {
      return await SnappCliCommandRunner(
            flutterSdkManager: sdkManager,
          ).run(arguments) ??
          0;
    });
  } on UsageException catch (e) {
    print(e);
    exitCode = 1;
  } on ToolExit catch (e) {
    print('Tool Error: ${e.message}');

    exitCode = e.exitCode ?? 1;
  } catch (e, _) {
    print('$e\n');
    exitCode = 1;
  }

  await _flushThenExit(exitCode);
}

Future<void> _flushThenExit(int status) {
  return Future.wait<void>([io.stdout.close(), io.stderr.close()])
      .then<void>((_) => io.exit(status));
}
