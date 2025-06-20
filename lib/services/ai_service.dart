// Dosya Konumu: lib/services/ai_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linkcim/config/api_config.dart'; // Güvenli config dosyası

class AIService {
  static const String _chatCompletionUrl =
      'https://api.openai.com/v1/chat/completions';
  static const String _whisperUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  static const String _visionUrl = 'https://api.openai.com/v1/chat/completions';

  static const bool debugMode = true;
  static const int timeoutSeconds = 30;

  // Cache sistemi (maliyet optimizasyonu için)
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const int cacheExpiryHours = 24;

  // Rate limit kontrolü için
  static DateTime? _lastApiCall;
  static const int minSecondsBetweenCalls = 1;

  // 🔐 API Key'i SharedPreferences'tan veya config'den al
  static Future<String> get _apiKey async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userApiKey = prefs.getString('openai_api_key') ?? '';

      if (userApiKey.isNotEmpty && userApiKey.startsWith('sk-')) {
        return userApiKey;
      }

      return ApiConfig.openaiApiKey;
    } catch (e) {
      _debugPrint('API anahtarı alınırken hata: $e');
      return ApiConfig.openaiApiKey;
    }
  }

  // AI analizi aktif mi kontrol et
  static Future<bool> get isAIAnalysisEnabled async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('ai_analysis_enabled') ?? true;
    } catch (e) {
      _debugPrint('AI analiz ayarı kontrol hatası: $e');
      return true;
    }
  }

  static void _debugPrint(String message) {
    if (debugMode) {
      print('[AI Service] $message');
    }
  }

  // İnternet bağlantısını kontrol et
  static Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      _debugPrint('Bağlantı kontrolü hatası: $e');
      return false;
    }
  }

  // Cache temizleme
  static void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp).inHours > cacheExpiryHours) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _debugPrint('${expiredKeys.length} expired cache entry removed');
    }
  }

  // 🎵 WHISPER API - Video sesini metne dönüştür
  static Future<Map<String, dynamic>> transcribeAudio(File audioFile) async {
    final apiKey = await _apiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      return {
        'success': false,
        'error': 'API anahtarı ayarlanmamış',
        'transcript': '',
      };
    }

    if (!await _checkConnectivity()) {
      return {
        'success': false,
        'error': 'İnternet bağlantısı yok',
        'transcript': '',
      };
    }

    try {
      _debugPrint('🎵 Whisper API ile ses analiz ediliyor...');

      var request = http.MultipartRequest('POST', Uri.parse(_whisperUrl));
      request.headers['Authorization'] = 'Bearer $apiKey';

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
      ));

      request.fields['model'] = 'whisper-1';
      request.fields['language'] = 'tr'; // Türkçe dil kodu
      request.fields['response_format'] = 'json';

      final streamedResponse = await request.send().timeout(Duration(
          seconds: timeoutSeconds * 2)); // Whisper için daha uzun timeout

      final response = await http.Response.fromStream(streamedResponse);

      _debugPrint('Whisper API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transcript = data['text']?.toString() ?? '';

        _debugPrint(
            '✅ Ses başarıyla metne dönüştürüldü: ${transcript.length} karakter');

        return {
          'success': true,
          'transcript': transcript.trim(),
          'language': data['language'] ?? 'tr',
        };
      } else {
        final error = 'Whisper API hatası: ${response.statusCode}';
        _debugPrint('❌ $error');
        return {
          'success': false,
          'error': error,
          'transcript': '',
        };
      }
    } catch (e) {
      _debugPrint('❌ Whisper API hatası: $e');
      return {
        'success': false,
        'error': 'Ses analizi hatası: $e',
        'transcript': '',
      };
    }
  }

  // 👁️ VISION API - Görseli analiz et
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final apiKey = await _apiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      return {
        'success': false,
        'error': 'API anahtarı ayarlanmamış',
        'description': '',
      };
    }

    if (!await _checkConnectivity()) {
      return {
        'success': false,
        'error': 'İnternet bağlantısı yok',
        'description': '',
      };
    }

    try {
      _debugPrint('👁️ Vision API ile görsel analiz ediliyor...');

      // Görseli base64'e dönüştür
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse(_visionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4o',
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text':
                          '''Bu video önizleme görselini analiz et. Sadece objektif bilgi ver, yorum yapma.

JSON formatında yanıt ver:
{
  "visual_description": "Görselde ne olduğunu kısaca ve net şekilde açıkla",
  "predicted_topic": "Video konusunu tahmin et (kısa ve öz)"
}'''
                    },
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:image/jpeg;base64,$base64Image'
                      }
                    }
                  ]
                }
              ],
              'max_tokens': 300,
            }),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      _debugPrint('Vision API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'];

          try {
            final result = jsonDecode(content);
            _debugPrint('✅ Görsel analizi başarılı');

            return {
              'success': true,
              'visual_description':
                  result['visual_description']?.toString() ?? '',
              'predicted_topic': result['predicted_topic']?.toString() ?? '',
              'visual_quality': result['visual_quality']?.toString() ?? '',
            };
          } catch (e) {
            _debugPrint('Vision JSON parsing hatası: $e');
            return {
              'success': false,
              'error': 'Vision analiz sonucu işlenemedi',
              'visual_description': content,
            };
          }
        }
      }

      return {
        'success': false,
        'error': 'Vision API yanıt alamadı',
        'visual_description': '',
      };
    } catch (e) {
      _debugPrint('❌ Vision API hatası: $e');
      return {
        'success': false,
        'error': 'Görsel analizi hatası: $e',
        'visual_description': '',
      };
    }
  }

  // 🧠 GELIŞMIŞ ANALİZ - Whisper + GPT-4o Kombinasyonu
  static Future<Map<String, dynamic>> advancedVideoAnalysis({
    String? title,
    String? transcript,
    String? visualDescription,
  }) async {
    // Cache kontrolü
    _cleanExpiredCache();
    final cacheKey =
        '${title}_${transcript?.hashCode}_${visualDescription?.hashCode}';

    if (_cache.containsKey(cacheKey)) {
      _debugPrint('Cache\'den gelişmiş analiz sonucu döndürülüyor');
      return _cache[cacheKey]!;
    }

    final apiKey = await _apiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      _debugPrint('⚠️ API anahtarı yok, basit analiz kullanılıyor');
      return simpleAnalyze(title ?? '');
    }

    if (!await _checkConnectivity()) {
      _debugPrint('⚠️ İnternet yok, basit analiz kullanılıyor');
      return simpleAnalyze(title ?? '');
    }

    try {
      _debugPrint('🧠 GPT-4o ile gelişmiş video analizi başlatılıyor...');

      // Analiz için içeriği birleştir
      String content = '';
      if (title?.isNotEmpty == true) content += 'Video Başlığı: "$title"\n\n';
      if (transcript?.isNotEmpty == true)
        content += 'Video Metni: "$transcript"\n\n';
      if (visualDescription?.isNotEmpty == true)
        content += 'Görsel Açıklama: "$visualDescription"\n\n';

      if (content.isEmpty) {
        return simpleAnalyze(title ?? '');
      }

      final prompt = '''$content

Bu video hakkında objektif bilgi ver. Yorum yapma, övme veya eleştiri yapma.

1. Video ne hakkında (kısa ve net)
2. Kategori: Yazılım, Eğitim, Eğlence, Spor, Yemek, Müzik, Sanat, Bilim, Teknoloji, Genel
3. 3-5 alakalı etiket

JSON formatında yanıt ver:
{
  "description": "Video ne hakkında (sadece konu, yorum yok)",
  "category": "kategori", 
  "tags": ["etiket1", "etiket2", "etiket3"]
}''';

      final response = await http
          .post(
            Uri.parse(_chatCompletionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4o',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Sen video içeriği analiz eden AI asistansın. Sadece objektif bilgi ver, yorum yapma.',
                },
                {
                  'role': 'user',
                  'content': prompt,
                }
              ],
              'max_tokens': 500,
              'temperature': 0.7,
            }),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      _debugPrint('GPT-4o API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'];

          String? jsonStr = _extractJsonFromText(content);
          if (jsonStr != null) {
            try {
              final result = jsonDecode(jsonStr);

              final analysisResult = {
                'success': true,
                'description': _cleanText(result['description']?.toString() ??
                    'Gelişmiş AI analizi ile açıklama üretildi'),
                'category': _validateCategory(
                    result['category']?.toString() ?? 'Genel'),
                'tags': _processTags(result['tags']),
                'content_quality': result['content_quality']?.toString() ?? '',
                'analysis_confidence':
                    result['analysis_confidence']?.toString() ?? 'orta',
                'source': 'gpt-4o-advanced',
                'timestamp': DateTime.now().toIso8601String(),
                'has_transcript': transcript?.isNotEmpty == true,
                'has_visual': visualDescription?.isNotEmpty == true,
              };

              // Sonucu cache'le
              _cache[cacheKey] = analysisResult;
              _cacheTimestamps[cacheKey] = DateTime.now();
              _debugPrint('✅ Gelişmiş AI analizi başarılı ve cache\'lendi');

              return analysisResult;
            } catch (e) {
              _debugPrint('JSON parsing hatası: $e');
            }
          }
        }
      } else if (response.statusCode == 429) {
        _debugPrint('🔄 Rate limit, basit analize geçiliyor');
        return simpleAnalyze(title ?? '');
      }
    } catch (e) {
      _debugPrint('Gelişmiş analiz hatası: $e');
    }

    _debugPrint('🔄 Gelişmiş analiz başarısız, basit analize geçiliyor');
    return simpleAnalyze(title ?? '');
  }

  // 🎯 ANA ANALİZ FONKSİYONU - Tüm özellikleri birleştiren
  static Future<Map<String, dynamic>> analyzeVideo({
    String? title,
    File? audioFile,
    File? imageFile,
  }) async {
    _debugPrint('🎯 Tam video analizi başlatılıyor...');

    String? transcript;
    String? visualDescription;

    // 1. Ses analizi (Whisper)
    if (audioFile != null && await audioFile.exists()) {
      final transcriptionResult = await transcribeAudio(audioFile);
      if (transcriptionResult['success'] == true) {
        transcript = transcriptionResult['transcript'];
        _debugPrint('✅ Ses metne dönüştürüldü: ${transcript?.length} karakter');
      }
    }

    // 2. Görsel analizi (Vision)
    if (imageFile != null && await imageFile.exists()) {
      final visionResult = await analyzeImage(imageFile);
      if (visionResult['success'] == true) {
        visualDescription = visionResult['visual_description'];
        _debugPrint('✅ Görsel analiz tamamlandı');
      }
    }

    // 3. Gelişmiş analiz (GPT-4o)
    final finalResult = await advancedVideoAnalysis(
      title: title,
      transcript: transcript,
      visualDescription: visualDescription,
    );

    // Ek bilgileri sonuca ekle
    if (transcript?.isNotEmpty == true) {
      finalResult['transcript'] = transcript;
    }
    if (visualDescription?.isNotEmpty == true) {
      finalResult['visual_analysis'] = visualDescription;
    }

    _debugPrint('🎯 Tam video analizi tamamlandı');
    return finalResult;
  }

  // JSON metni çıkarma
  static String? _extractJsonFromText(String text) {
    // Önce tam JSON bulmaya çalış
    final fullJsonMatch = RegExp(r'\{[^{}]*\}', dotAll: true).firstMatch(text);
    if (fullJsonMatch != null) {
      return fullJsonMatch.group(0);
    }

    // Manuel JSON oluşturma
    final lines = text.split('\n');
    final descriptionMatch =
        RegExp(r'"description":\s*"([^"]*)"').firstMatch(text);
    final categoryMatch = RegExp(r'"category":\s*"([^"]*)"').firstMatch(text);
    final tagsMatch = RegExp(r'"tags":\s*\[([^\]]*)\]').firstMatch(text);

    if (descriptionMatch != null || categoryMatch != null) {
      final description = descriptionMatch?.group(1) ?? 'Video açıklaması';
      final category = categoryMatch?.group(1) ?? 'Genel';
      final tagsStr = tagsMatch?.group(1) ?? '';

      return '''
{
  "description": "$description",
  "category": "$category",
  "tags": [$tagsStr]
}
''';
    }

    return null;
  }

  // Metni temizleme
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML taglarını kaldır
        .replaceAll(RegExp(r'\s+'), ' ') // Fazla boşlukları kaldır
        .replaceAll('"', '') // Tırnak işaretlerini kaldır
        .trim();
  }

  // Kategori doğrulama
  static String _validateCategory(String category) {
    const validCategories = [
      'Yazılım',
      'Eğitim',
      'Eğlence',
      'Spor',
      'Yemek',
      'Müzik',
      'Sanat',
      'Bilim',
      'Teknoloji',
      'Genel'
    ];

    final cleanCategory = _cleanText(category);
    if (validCategories.contains(cleanCategory)) {
      return cleanCategory;
    }

    // Benzer kategori arama
    for (final validCat in validCategories) {
      if (cleanCategory.toLowerCase().contains(validCat.toLowerCase()) ||
          validCat.toLowerCase().contains(cleanCategory.toLowerCase())) {
        return validCat;
      }
    }

    return 'Genel';
  }

  // Etiketleri işleme
  static List<String> _processTags(dynamic tagsData) {
    List<String> tags = [];

    if (tagsData is List) {
      tags = tagsData.map((tag) => _cleanText(tag.toString())).toList();
    } else if (tagsData is String) {
      // String olarak gelirse virgül, tırnak vs. ile ayır
      tags = tagsData
          .replaceAll(RegExp(r'["\[\]]'), '')
          .split(RegExp(r'[,\n]'))
          .map((tag) => _cleanText(tag))
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    // Etiketleri filtrele ve temizle
    return tags
        .where((tag) => tag.length > 1 && tag.length < 20)
        .take(5)
        .toList();
  }

  static Map<String, dynamic> _handleApiError(int statusCode, String body) {
    String errorMessage;

    switch (statusCode) {
      case 401:
        errorMessage = 'API anahtarı geçersiz veya süresi dolmuş';
        break;
      case 429:
        errorMessage = 'Çok fazla istek gönderildi, lütfen bekleyin';
        _debugPrint(
            '❌ API Rate Limit: $errorMessage - Basit analiz kullanılacak');
        // 429 hatası için basit analiz yeterli
        return {
          'success': false,
          'error': errorMessage,
          'fallback': true, // Basit analiz kullanılacağını belirtir
        };
      case 500:
      case 502:
      case 503:
        errorMessage = 'OpenAI servisi geçici olarak kullanılamıyor';
        break;
      default:
        errorMessage = 'API hatası (${statusCode})';
    }

    _debugPrint('❌ API Hatası: $errorMessage');

    return {
      'success': false,
      'error': errorMessage,
      'description': 'Manuel açıklama giriniz',
      'category': 'Genel',
      'tags': <String>[],
    };
  }

  // API bağlantı testi
  static Future<bool> testApiConnection() async {
    final apiKey = await _apiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      return false;
    }

    if (!await _checkConnectivity()) {
      return false;
    }

    try {
      _debugPrint('API bağlantısı test ediliyor...');

      final response = await http
          .post(
            Uri.parse(_chatCompletionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-3.5-turbo',
              'messages': [
                {'role': 'user', 'content': 'Test'}
              ],
              'max_tokens': 5,
            }),
          )
          .timeout(Duration(seconds: 10));

      final success = response.statusCode == 200;
      _debugPrint(success
          ? '✅ API test başarılı'
          : '❌ API test başarısız: ${response.statusCode}');

      return success;
    } catch (e) {
      _debugPrint('❌ API test hatası: $e');
      return false;
    }
  }

  // Cache yönetimi
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _debugPrint('Cache temizlendi');
  }

  static int getCacheSize() => _cache.length;

  // Basit analiz sistemi (yedek)
  static Map<String, dynamic> simpleAnalyze(String title) {
    String lowerTitle = title.toLowerCase();

    String category = 'Genel';
    List<String> tags = [];
    String description = title.isNotEmpty ? title : 'Video içeriği';

    // Kategori tahmini
    if (lowerTitle.contains('flutter') ||
        lowerTitle.contains('dart') ||
        lowerTitle.contains('kod') ||
        lowerTitle.contains('programlama') ||
        lowerTitle.contains('react') ||
        lowerTitle.contains('javascript')) {
      category = 'Yazılım';
      tags.addAll(['programlama', 'teknoloji', 'yazılım']);
    } else if (lowerTitle.contains('yemek') ||
        lowerTitle.contains('tarif') ||
        lowerTitle.contains('mutfak') ||
        lowerTitle.contains('pişir')) {
      category = 'Yemek';
      tags.addAll(['yemek', 'tarif', 'mutfak']);
    } else if (lowerTitle.contains('spor') ||
        lowerTitle.contains('egzersiz') ||
        lowerTitle.contains('fitness') ||
        lowerTitle.contains('antrenman')) {
      category = 'Spor';
      tags.addAll(['spor', 'sağlık', 'fitness']);
    } else if (lowerTitle.contains('müzik') ||
        lowerTitle.contains('şarkı') ||
        lowerTitle.contains('müzisyen')) {
      category = 'Müzik';
      tags.addAll(['müzik', 'eğlence', 'sanat']);
    } else if (lowerTitle.contains('eğitim') ||
        lowerTitle.contains('ders') ||
        lowerTitle.contains('öğren') ||
        lowerTitle.contains('tutorial')) {
      category = 'Eğitim';
      tags.addAll(['eğitim', 'öğrenme', 'ders']);
    } else if (lowerTitle.contains('komedi') ||
        lowerTitle.contains('eğlence') ||
        lowerTitle.contains('mizah')) {
      category = 'Eğlence';
      tags.addAll(['eğlence', 'komedi', 'mizah']);
    }

    // Teknik etiketler
    if (lowerTitle.contains('flutter')) tags.add('flutter');
    if (lowerTitle.contains('dart')) tags.add('dart');
    if (lowerTitle.contains('api')) tags.add('api');
    if (lowerTitle.contains('widget')) tags.add('widget');
    if (lowerTitle.contains('react')) tags.add('react');
    if (lowerTitle.contains('javascript')) tags.add('javascript');
    if (lowerTitle.contains('python')) tags.add('python');

    // Duplicate'ları temizle
    tags = tags.toSet().toList();

    return {
      'success': true,
      'description': description,
      'category': category,
      'tags': tags,
      'source': 'simple'
    };
  }

  // DEBUG: Sistemi test etmek için
  static Future<void> debugAnalysis(String title) async {
    _debugPrint('🔍 DEBUG: AI Analiz sistemi test ediliyor...');

    // 1. AI analizi aktif mi?
    final isEnabled = await isAIAnalysisEnabled;
    _debugPrint('🔍 AI Analiz Aktif: $isEnabled');

    // 2. API Key kontrolü
    final apiKey = await _apiKey;
    _debugPrint('🔍 API Key Uzunluğu: ${apiKey.length}');
    _debugPrint('🔍 API Key Başlangıcı: ${apiKey.startsWith('sk-')}');

    // 3. İnternet bağlantısı
    final hasInternet = await _checkConnectivity();
    _debugPrint('🔍 İnternet Bağlantısı: $hasInternet');

    // 4. Rate limit kontrolü
    if (_lastApiCall != null) {
      final timeSinceLastCall =
          DateTime.now().difference(_lastApiCall!).inSeconds;
      _debugPrint('🔍 Son API Çağrısından Geçen Süre: ${timeSinceLastCall}s');
    } else {
      _debugPrint('🔍 Daha önce API çağrısı yapılmamış');
    }

    // 5. Basit analiz testi
    final simpleResult = simpleAnalyze(title);
    _debugPrint('🔍 Basit Analiz Sonucu: $simpleResult');
  }
}
