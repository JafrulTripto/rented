import 'dart:io';
import 'package:flutter/foundation.dart';

class Config {
  static String get apiBaseUrl {
    // 1. Check for build-time override via --dart-define=BASE_URL=...
    const String envUrl = String.fromEnvironment('BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // 2. Web always uses localhost (or relative path in production if served together)
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    // 3. Android Emulator needs special IP
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }

    // 4. iOS Simulator and Desktop use localhost
    return 'http://localhost:8080';
  }
}
