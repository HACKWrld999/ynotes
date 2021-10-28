import 'dart:convert';
import 'dart:io';

import 'package:shake_flutter/models/shake_file.dart';
import 'package:shake_flutter/shake_flutter.dart';
import 'package:ynotes/core/utils/file_utils.dart';
import 'package:ynotes/core/utils/logging_utils.dart';
import 'package:ynotes/globals.dart';

/// The class that handles the bug reporting process
class BugReportUtils {
  const BugReportUtils._();

  /// Initializes the bug report client
  static init() {
    initShakeToReport();
    Shake.setShowFloatingReportButton(false);
    Shake.setInvokeShakeOnScreenshot(false);
    Shake.start('iGBaTEc4t0namXSCrwRJLihJPkMPnfco2z4Xoyi3', 'nfzb5JnoGoGVxEi75jejFhyTQL4MyyOC7yCMCYiOmKaykWdoh0kfbY8');
  }

  static initShakeToReport() {
    Shake.setInvokeShakeOnShakeDeviceEvent(appSys.settings.user.global.shakeToReport);
  }

  /// Saves and anonymizes the bug data to send it to the report platform
  static packData() async {
    try {
      String json = jsonEncode(await CustomLogger.getAllLogs());
      final directory = await FolderAppUtil.getDirectory();

      final File file = File('${directory.path}/logs/temp.json');

      if (await file.exists()) {
        file.delete();
      }
      file.create(recursive: true);
      await file.writeAsString(json);
      List<ShakeFile> shakeFiles = [];
      shakeFiles.add(ShakeFile.create(file.path, 'userLogs'));
      Shake.setShakeReportData(shakeFiles);
    } catch (e) {
      CustomLogger.error(e);
    }
  }

  /// Opens the report widget
  static report() async {
    await packData();
    Shake.show();
  }
}
