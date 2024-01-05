// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:io';
import 'package:flutter_tools/src/base/io.dart';

import 'package:flutter_tools/src/base/process.dart';
import 'package:interact/interact.dart';
import 'package:process/process.dart';
import 'package:snapp_cli/commands/base_command.dart';

extension ProcessUtilsExt on ProcessUtils {
  Future<T?> runCommand<T>(
    List<String> cmd, {
    T? Function(RunResult result)? parseResult,
    T? Function(dynamic error, StackTrace stack)? parseFail,
    Spinner? spinner,
    bool throwOnError = true,
    LoggerService? logger,
    Duration? timeout = const Duration(seconds: 10),
    String label = 'commandRunner',
  }) async {
    final spinnerState = spinner?.interact();

    try {
      final result = await run(
        cmd,
        timeout: timeout,
      );

      logger?.detail('$label ExitCode: ${result.exitCode}');
      logger?.detail('$label Stdout: ${result.stdout.trim()}');
      logger?.detail('$label Stderr: ${result.stderr}');

      if (throwOnError && result.exitCode != 0) {
        throwToolExit('''
$label failed with exit code ${result.exitCode}:
${result.stdout.trim()}
${result.stderr.trim()}
            ''');
      }

      spinnerState?.done();

      return parseResult?.call(result);
    } catch (e, s) {
      spinnerState?.failed();

      logger?.detail('$label Error: $e\n$s');

      return parseFail?.call(e, s);
    }
  }

  Future<RunResult> runWithOutput(
    List<String> cmd, {
    required ProcessManager processManager,
    required LoggerService logger,
    Duration? timeout,
    bool showStderr = false,
  }) async {
    while (true) {
      final Process process = await start(cmd);

      final StringBuffer stdoutBuffer = StringBuffer();
      final StringBuffer stderrBuffer = StringBuffer();
      final Future<void> stdoutFuture =
          process.stdout.transform<String>(const Utf8Decoder()).listen(
        (event) {
          stdoutBuffer.write(event);
          logger.info(event);
        },
      ).asFuture<void>();

      final Future<void> stderrFuture =
          process.stderr.transform<String>(const Utf8Decoder()).listen((event) {
        stderrBuffer.write(event);

        if (showStderr) logger.info(event);
      }).asFuture<void>();

      int? exitCode;
      exitCode = timeout == null
          ? await process.exitCode.then<int?>((int x) => x)
          : await process.exitCode.then<int?>((int x) => x).timeout(timeout,
              onTimeout: () {
              // The process timed out. Kill it.
              processManager.killPid(process.pid);
              return null;
            });

      String stdoutString;
      String stderrString;
      try {
        Future<void> stdioFuture =
            Future.wait<void>(<Future<void>>[stdoutFuture, stderrFuture]);
        if (exitCode == null) {
          // If we had to kill the process for a timeout, only wait a short time
          // for the stdio streams to drain in case killing the process didn't
          // work.
          stdioFuture = stdioFuture.timeout(const Duration(seconds: 1));
        }
        await stdioFuture;
      } on Exception catch (e, s) {
        logger.info(
            'Exception while running process with output | waiting for stdio streams: $e, $s: $e\n$s');

        // Ignore errors on the process' stdout and stderr streams. Just capture
        // whatever we got, and use the exit code
      }
      stdoutString = stdoutBuffer.toString();
      stderrString = stderrBuffer.toString();

      final ProcessResult result = ProcessResult(
          process.pid, exitCode ?? -1, stdoutString, stderrString);
      final RunResult runResult = RunResult(result, cmd);

      // If the process did not timeout. We are done.
      if (exitCode != null) {
        logger.detail(runResult.toString());

        return runResult;
      }
    }
  }
}
