import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'NexAssist';

  // API Configuration (Reads from environment at build time or falls back to localhost)
  static String get defaultApiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'http://localhost:8000/api/v1';
  }

  static List<String> get candidateApiBaseUrls {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (kIsWeb) {
      if (envUrl.isNotEmpty) {
        return [envUrl];
      }
      return ['http://localhost:8000/api/v1'];
    }
    return [
      if (envUrl.isNotEmpty) envUrl,
      'http://localhost:8000/api/v1',
      'http://10.76.69.178:8000/api/v1',
      'http://10.0.2.2:8000/api/v1',
    ];
  }

  // Breakpoints for Responsive Design (Mobile vs Tablet vs Desktop/Web)
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  // Local Storage Keys
  static const String keyAccessToken = 'it_helpdesk_access_token';
  static const String keyRefreshToken = 'it_helpdesk_refresh_token';
  static const String keyUserData = 'it_helpdesk_user_data';
  static const String keyThemeMode = 'it_helpdesk_theme_mode';

  // App Download Links (.exe for Desktop, .apk for Android)
  static String get windowsDownloadUrl {
    if (kIsWeb) {
      return '/downloads/NexAssist-Setup.exe';
    }
    return '$defaultApiBaseUrl/downloads/windows';
  }

  static String get androidDownloadUrl {
    if (kIsWeb) {
      return '/downloads/NexAssist-Android.apk';
    }
    return '$defaultApiBaseUrl/downloads/android';
  }
}
