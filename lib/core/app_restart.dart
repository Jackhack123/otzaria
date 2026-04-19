import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

bool canRestartApplication() =>
  Platform.isWindows || Platform.isLinux || Platform.isMacOS;

String restartTargetDisplayName() =>
  Platform.isAndroid || Platform.isIOS ? 'האפליקציה' : 'התוכנה';

/// מפעיל again את התוכנה אם הפלטפורמה תומכת בכך.
///
/// בדסקטופ נOpen מופע חדש של file הEnableה הcurrent ואז נclosed את המופע הcurrent.
/// במובייל אין דרך אמינה לopen again את התוכנה, ולyes תתבצע סגירה רגילה בלבד.
Future<void> restartApplication() async {
  if (canRestartApplication()) {
    final executablePath = Platform.resolvedExecutable;
    final workingDirectory = p.dirname(executablePath);

    await Process.start(
      executablePath,
      const [],
      mode: ProcessStartMode.detached,
      workingDirectory: workingDirectory,
    );

    await windowManager.close();
    return;
  }

  if (Platform.isAndroid || Platform.isIOS) {
    await SystemNavigator.pop();
    return;
  }

  exit(0);
}