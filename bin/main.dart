import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:snapp_debugger/snapp_debugger.dart';

Future<void> main(List<String> arguments) async {
  late int exitCode;

  final FlutterSdkManager sdkManager = FlutterSdkManager();

  try {
    /// Initialize the Flutter SDK
    await sdkManager.initialize();

    // TODO: check custom devices is enabled or not ? checkFeatureEnabled

    exitCode = await runInContext(() async {
      return await SnappDebuggerCommandRunner(
            flutterSdkManager: sdkManager,
          ).run(arguments) ??
          0;
    });
  } on UsageException catch (e) {
    print(e);
    exitCode = 1;
  } on ToolExit catch (e) {
    print('Error: ${e.message}');

    exitCode = e.exitCode ?? 1;
  } catch (e, _) {
    print('$e\n');
    exitCode = 1;
  }

  io.exit(exitCode);
}