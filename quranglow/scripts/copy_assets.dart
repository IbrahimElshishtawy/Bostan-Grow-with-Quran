import 'dart:io';

import 'package:flutter/foundation.dart';

void main() {
  final rawDir = Directory('android/app/src/main/res/raw');
  if (!rawDir.existsSync()) {
    rawDir.createSync(recursive: true);
    if (kDebugMode) {
      print('Created directory: ${rawDir.path}');
    }
  }

  final filesToCopy = {
    'assets/voice/FDKfMw5922k.mp3': 'android/app/src/main/res/raw/salawat.mp3',
    'assets/voice/azan.mp3': 'android/app/src/main/res/raw/azan.mp3',
  };

  filesToCopy.forEach((source, target) {
    final sourceFile = File(source);
    if (sourceFile.existsSync()) {
      sourceFile.copySync(target);
      if (kDebugMode) {
        print('Copied $source to $target');
      }
    } else {
      if (kDebugMode) {
        print('Source file not found: $source');
      }
    }
  });
}
