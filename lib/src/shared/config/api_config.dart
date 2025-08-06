import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration file for API keys and endpoints
///
/// Uses environment variables from .env file for secure configuration
class ApiConfig {
  // OpenAI Configuration from environment variables
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get openAiBaseUrl =>
      dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
  static String get openAiModel =>
      dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo';

  // Backend Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://srv797850.hstgr.cloud/api';
  
  // Keep backwards compatibility
  static String get backendBaseUrl => apiBaseUrl;

  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'Apex Money';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static bool get debugMode => 
      (dotenv.env['DEBUG_MODE'] ?? 'false').toLowerCase() == 'true';

  // Validation
  static bool get isOpenAiConfigured =>
      openAiApiKey != 'your_openai_api_key_here' && openAiApiKey.isNotEmpty;

  static bool get isApiConfigured =>
      apiBaseUrl != 'https://srv797850.hstgr.cloud/api' && apiBaseUrl.isNotEmpty;

  static void validateConfig({bool requireOpenAi = false}) {
    if (requireOpenAi && !isOpenAiConfigured) {
      throw Exception(
        'OpenAI API key not configured. Please add your API key to the .env file (OPENAI_API_KEY=your_key_here)',
      );
    }
  }

  // Development helpers
  static void logConfig() {
    if (debugMode) {
      print('=== API Configuration ===');
      print('App Name: $appName');
      print('App Version: $appVersion');
      print('API Base URL: $apiBaseUrl');
      print('OpenAI Configured: $isOpenAiConfigured');
      print('Debug Mode: $debugMode');
      print('========================');
    }
  }
}
