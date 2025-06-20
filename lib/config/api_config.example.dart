// Dosya Konumu: lib/config/api_config.example.dart
//
// Bu dosyayı kopyalayıp api_config.dart olarak kaydedin
// ve kendi API anahtarlarınızı girin
//
// Komut: cp lib/config/api_config.example.dart lib/config/api_config.dart

class ApiConfig {
  // 🔐 ÖNEMLI: Bu dosyayı .gitignore'a ekleyin!
  // GitHub'a yüklemeden önce mutlaka .gitignore'a ekleyin

  // OpenAI API Anahtarı - BURAYA KENDİ API ANAHTARINIZI GİRİN
  // https://platform.openai.com/api-keys adresinden API anahtarınızı alabilirsiniz
  static const String openaiApiKey = 'YOUR_OPENAI_API_KEY_HERE';

  // Instagram API ayarları (gelecekte kullanım için)
  static const String instagramClientId = 'YOUR_INSTAGRAM_CLIENT_ID';
  static const String instagramClientSecret = 'YOUR_INSTAGRAM_CLIENT_SECRET';

  // Firebase ayarları (gelecekte kullanım için)
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';

  // API endpoints
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String instagramBaseUrl = 'https://api.instagram.com/v1';

  // Uygulama ayarları
  static const String appVersion = '1.0.0';
  static const String appName = 'Linkci';
  static const String supportEmail = 'support@linkci.app';

  // Debug ayarları
  static const bool isDebugMode = true;
  static const bool enableAnalytics = false; // Production'da true yapın
  static const bool enableCrashReporting = false; // Production'da true yapın

  // Cache ayarları
  static const int cacheExpiryHours = 24;
  static const int maxCacheSize = 100; // Maksimum cache girişi

  // API limits
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;

  // OpenAI özel ayarları
  static const String openaiModel = 'gpt-3.5-turbo';
  static const int maxTokens = 300;
  static const double temperature = 0.7;

  // Validasyon fonksiyonları
  static bool get hasValidOpenAIKey {
    return openaiApiKey.isNotEmpty &&
        openaiApiKey != 'YOUR_OPENAI_API_KEY_HERE' &&
        openaiApiKey.startsWith('sk-');
  }

  static bool get hasValidInstagramConfig {
    return instagramClientId.isNotEmpty &&
        instagramClientId != 'YOUR_INSTAGRAM_CLIENT_ID';
  }

  // Environment check
  static bool get isProduction {
    return !isDebugMode;
  }

  // API configuration map
  static Map<String, dynamic> get apiConfig {
    return {
      'openai': {
        'apiKey': openaiApiKey,
        'baseUrl': openaiBaseUrl,
        'model': openaiModel,
        'maxTokens': maxTokens,
        'temperature': temperature,
        'timeout': apiTimeoutSeconds,
      },
      'instagram': {
        'clientId': instagramClientId,
        'clientSecret': instagramClientSecret,
        'baseUrl': instagramBaseUrl,
      },
      'app': {
        'version': appVersion,
        'name': appName,
        'debug': isDebugMode,
        'analytics': enableAnalytics,
        'crashReporting': enableCrashReporting,
      },
    };
  }
}
