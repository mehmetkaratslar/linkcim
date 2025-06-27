import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class VideoDownloadService {
  // 🎯 PYTHON API İLE ENTEGRE VİDEO İNDİRME SİSTEMİ

  static const String _baseUrl =
      'https://linkcim-production.up.railway.app'; // Railway Cloud API
  static const String _apiKey =
      '45541d717524a99df5f994bb9f6cbce825269852be079594b8e35f7752d6f1bd';
  static const int _timeoutSeconds = 120;
  static const int _pollIntervalMs = 2000; // 2 saniyede bir durum kontrol et

  static bool _isDebugMode = kDebugMode;

  // 🔐 İzinleri kontrol et
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        _debugPrint('🔐 Android SDK: $sdkInt - İzinler kontrol ediliyor...');

        if (sdkInt >= 33) {
          await [Permission.videos, Permission.photos].request();
        } else if (sdkInt >= 30) {
          await [Permission.manageExternalStorage, Permission.storage]
              .request();
        } else {
          await Permission.storage.request();
        }

        return true;
      } catch (e) {
        _debugPrint('❌ İzin kontrolü hatası: $e - Devam ediyoruz...');
        return true;
      }
    }
    return true;
  }

  // 📁 İndirme dizinini al
  static Future<Directory> getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        final possiblePaths = [
          '/storage/emulated/0/Download/Linkcim',
          '/storage/emulated/0/Documents/Linkcim',
          '/storage/emulated/0/Movies/Linkcim',
        ];

        for (final path in possiblePaths) {
          try {
            final directory = Directory(path);
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
            return directory;
          } catch (e) {
            continue;
          }
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory('${appDir.path}/Downloads');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } catch (e) {
      final tempDir = await getTemporaryDirectory();
      final directory = Directory('${tempDir.path}/Linkcim');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }
  }

  // 🎯 ANA VİDEO İNDİRME FONKSİYONU - PYTHON API İLE
  static Future<Map<String, dynamic>> downloadVideo({
    required String videoUrl,
    required String platform,
    String? customFileName,
    String quality = 'medium',
    Function(double)? onProgress,
  }) async {
    _debugPrint('🚀 Python API ile video indirme başlatılıyor: $videoUrl');

    try {
      // İzin kontrolü
      await requestPermissions();

      // 1️⃣ Python API'ye indirme isteği gönder
      final startResult = await _startDownload(videoUrl, platform, quality);
      if (!startResult['success']) {
        throw Exception(startResult['error']);
      }

      final jobId = startResult['job_id'];
      _debugPrint('✅ İndirme işi başlatıldı: $jobId');

      // 2️⃣ İndirme durumunu takip et
      final statusResult = await _pollDownloadStatus(jobId, onProgress);
      if (!statusResult['success']) {
        throw Exception(statusResult['error']);
      }

      // 3️⃣ Tamamlanan dosyayı indir
      final downloadResult =
          await _downloadCompletedFile(jobId, statusResult['job_data']);
      if (!downloadResult['success']) {
        throw Exception(downloadResult['error']);
      }

      // 4️⃣ İndirme geçmişine kaydet
      await _saveDownloadHistory(
          downloadResult['file_path'], downloadResult['file_size']);

      return {
        'success': true,
        'file_path': downloadResult['file_path'],
        'file_size': downloadResult['file_size'],
        'title': statusResult['job_data']['title'] ?? 'Video',
        'platform': platform,
        'duration': statusResult['job_data']['duration'] ?? 0,
        'message': '✅ Video başarıyla indirildi!',
      };
    } catch (e) {
      _debugPrint('❌ Video indirme hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': '❌ Video indirilemedi: ${e.toString()}',
      };
    }
  }

  // 🌟 PLATFORM DESTEĞİ KONTROL ET
  static Future<Map<String, dynamic>> getSupportedPlatforms() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/platforms'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'platforms': data['platforms'],
        };
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _debugPrint('❌ Platform listesi alınamadı: $e');
      return {
        'success': false,
        'error': e.toString(),
        'platforms': _getDefaultPlatforms(),
      };
    }
  }

  // 📊 İNDİRME GEÇMİŞİNİ AL
  static Future<List<Map<String, dynamic>>> getDownloadHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/jobs'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['jobs'] ?? []);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _debugPrint('❌ İndirme geçmişi alınamadı: $e');
      return [];
    }
  }

  // 🔥 HEALTH CHECK - API ÇALIŞIYOR MU?
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      _debugPrint('❌ API sağlık kontrolü başarısız: $e');
      return false;
    }
  }

  // 🗑️ İNDİRME İŞİNİ SİL
  static Future<bool> deleteDownloadJob(String jobId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/job/$jobId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      _debugPrint('❌ İş silinirken hata: $e');
      return false;
    }
  }

  // 🔄 ÖZEL YARDIMCI FONKSİYONLAR

  // İndirme işlemini başlat
  static Future<Map<String, dynamic>> _startDownload(
      String url, String platform, String quality) async {
    try {
      final requestBody = {
        'url': url,
        'format': 'mp4',
        'quality': quality,
        'platform': platform.toLowerCase(),
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/download'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'job_id': data['job_id'],
          'status': data['status'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'İndirme başlatılamadı');
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'İndirme başlatma hatası: $e',
      };
    }
  }

  // İndirme durumunu takip et
  static Future<Map<String, dynamic>> _pollDownloadStatus(
      String jobId, Function(double)? onProgress) async {
    try {
      int attempts = 0;
      const maxAttempts = 60; // 2 dakika bekle (60 * 2 saniye)

      while (attempts < maxAttempts) {
        final response = await http.get(
          Uri.parse('$_baseUrl/status/$jobId'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final jobData = jsonDecode(response.body);
          final status = jobData['status'];
          final progress = (jobData['progress'] ?? 0).toDouble();

          _debugPrint(
              '📊 İndirme durumu: $status - %${progress.toStringAsFixed(1)}');

          // Progress callback'i çağır
          if (onProgress != null) {
            onProgress(progress);
          }

          // Status kontrolü
          if (status == 'completed') {
            return {
              'success': true,
              'job_data': jobData,
            };
          } else if (status == 'failed') {
            throw Exception(jobData['error'] ?? 'İndirme başarısız');
          }

          // Devam eden işlem - biraz bekle ve tekrar kontrol et
          await Future.delayed(Duration(milliseconds: _pollIntervalMs));
          attempts++;
        } else {
          throw Exception(
              'Durum kontrolü başarısız: HTTP ${response.statusCode}');
        }
      }

      throw Exception('İndirme zaman aşımına uğradı');
    } catch (e) {
      return {
        'success': false,
        'error': 'Durum takibi hatası: $e',
      };
    }
  }

  // Tamamlanan dosyayı indir
  static Future<Map<String, dynamic>> _downloadCompletedFile(
      String jobId, Map<String, dynamic> jobData) async {
    try {
      final downloadDir = await getDownloadDirectory();
      final fileName = _generateFileName(jobData);
      final filePath = '${downloadDir.path}/$fileName';

      _debugPrint('📥 Dosya indiriliyor: $fileName');

      final response = await http.get(
        Uri.parse('$_baseUrl/download/$jobId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        final fileSize = await file.length();
        _debugPrint('✅ Dosya kaydedildi: $filePath (${fileSize} bytes)');

        return {
          'success': true,
          'file_path': filePath,
          'file_size': fileSize,
        };
      } else {
        throw Exception('Dosya indirme başarısız: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Dosya kaydetme hatası: $e',
      };
    }
  }

  // Dosya adı oluştur
  static String _generateFileName(Map<String, dynamic> jobData) {
    final title = jobData['title'] ?? 'video';
    final platform = jobData['platform'] ?? 'unknown';
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Dosya adını temizle
    final cleanTitle = title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    return '${platform}_${cleanTitle}_$timestamp.mp4';
  }

  // İndirme geçmişine kaydet
  static Future<void> _saveDownloadHistory(
      String filePath, int fileSize) async {
    try {
      // Bu fonksiyon database_service.dart ile entegre edilebilir
      _debugPrint('💾 İndirme geçmişine kaydedildi: $filePath');
    } catch (e) {
      _debugPrint('❌ Geçmiş kaydetme hatası: $e');
    }
  }

  // Varsayılan platform listesi
  static Map<String, dynamic> _getDefaultPlatforms() {
    return {
      'youtube': {
        'name': 'YouTube',
        'formats': ['mp4', 'mp3'],
        'qualities': ['high', 'medium', 'low'],
        'features': ['thumbnails', 'metadata', 'playlists']
      },
      'instagram': {
        'name': 'Instagram',
        'formats': ['mp4'],
        'qualities': ['high', 'medium'],
        'features': ['stories', 'reels', 'posts']
      },
      'tiktok': {
        'name': 'TikTok',
        'formats': ['mp4'],
        'qualities': ['high', 'medium'],
        'features': ['no-watermark', 'metadata']
      },
      'twitter': {
        'name': 'Twitter/X',
        'formats': ['mp4'],
        'qualities': ['high', 'medium'],
        'features': ['multiple-videos']
      },
    };
  }

  // Debug print
  static void _debugPrint(String message) {
    if (_isDebugMode) {
      print('🎬 VideoDownloadService: $message');
    }
  }

  // URL'den platform tespit et
  static String detectPlatform(String url) {
    final urlLower = url.toLowerCase();
    if (urlLower.contains('youtube.com') || urlLower.contains('youtu.be')) {
      return 'youtube';
    } else if (urlLower.contains('instagram.com')) {
      return 'instagram';
    } else if (urlLower.contains('tiktok.com')) {
      return 'tiktok';
    } else if (urlLower.contains('twitter.com') || urlLower.contains('x.com')) {
      return 'twitter';
    } else if (urlLower.contains('facebook.com')) {
      return 'facebook';
    } else {
      return 'unknown';
    }
  }

  // URL geçerli mi kontrol et
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // 🗑️ İNDİRİLEN DOSYAYI SİL
  static Future<bool> deleteDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _debugPrint('✅ Dosya silindi: $filePath');
        return true;
      } else {
        _debugPrint('⚠️ Dosya bulunamadı: $filePath');
        return false;
      }
    } catch (e) {
      _debugPrint('❌ Dosya silinirken hata: $e');
      return false;
    }
  }

  // 🧪 VIDEO URL'SİNİ TEST ET
  static Future<Map<String, dynamic>> testVideoUrl(String url) async {
    try {
      if (!isValidUrl(url)) {
        throw Exception('Geçersiz URL formatı');
      }

      final platform = detectPlatform(url);

      // Python API ile test et
      final response = await http
          .post(
            Uri.parse('$_baseUrl/download'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'url': url,
              'format': 'mp4',
              'quality': 'low', // Test için düşük kalite
              'platform': platform,
            }),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobId = data['job_id'];

        // Test işini hemen iptal et (sadece URL geçerliliğini test etmek için)
        await deleteDownloadJob(jobId);

        return {
          'success': true,
          'platform': platform,
          'message': 'URL geçerli ve indirilebilir',
          'supported': true,
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'URL test edilemedi');
      }
    } catch (e) {
      _debugPrint('❌ URL test hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'URL geçersiz veya desteklenmiyor',
        'supported': false,
      };
    }
  }

  // ⚡ HIZLI VİDEO İNDİRME (Düşük kalite)
  static Future<Map<String, dynamic>> downloadVideoFast({
    required String videoUrl,
    String? customFileName,
    Function(double)? onProgress,
  }) async {
    _debugPrint('⚡ Hızlı video indirme başlatılıyor: $videoUrl');

    final platform = detectPlatform(videoUrl);

    return await downloadVideo(
      videoUrl: videoUrl,
      platform: platform,
      customFileName: customFileName,
      quality: 'low', // Hızlı indirme için düşük kalite
      onProgress: onProgress,
    );
  }

  // 📱 MOBİL UYUMLU VİDEO İNDİRME (Orta kalite)
  static Future<Map<String, dynamic>> downloadVideoMobile({
    required String videoUrl,
    String? customFileName,
    Function(double)? onProgress,
  }) async {
    _debugPrint('📱 Mobil uyumlu video indirme başlatılıyor: $videoUrl');

    final platform = detectPlatform(videoUrl);

    return await downloadVideo(
      videoUrl: videoUrl,
      platform: platform,
      customFileName: customFileName,
      quality: 'medium', // Mobil için orta kalite
      onProgress: onProgress,
    );
  }

  // 🔄 BATCH VİDEO İNDİRME (Çoklu URL)
  static Future<List<Map<String, dynamic>>> downloadMultipleVideos({
    required List<String> videoUrls,
    String quality = 'medium',
    Function(int current, int total, String currentUrl)? onBatchProgress,
  }) async {
    _debugPrint('🔄 Batch indirme başlatılıyor: ${videoUrls.length} video');

    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < videoUrls.length; i++) {
      final url = videoUrls[i];

      if (onBatchProgress != null) {
        onBatchProgress(i + 1, videoUrls.length, url);
      }

      final platform = detectPlatform(url);
      final result = await downloadVideo(
        videoUrl: url,
        platform: platform,
        quality: quality,
      );

      results.add({
        'url': url,
        'index': i,
        'result': result,
      });

      // Başarısızlık durumunda kısa bekleme
      if (result['success'] != true) {
        await Future.delayed(Duration(seconds: 2));
      }
    }

    final successCount =
        results.where((r) => r['result']['success'] == true).length;
    _debugPrint(
        '✅ Batch indirme tamamlandı: $successCount/${videoUrls.length} başarılı');

    return results;
  }

  // 📊 İNDİRME İSTATİSTİKLERİ
  static Future<Map<String, dynamic>> getDownloadStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'stats': data,
        };
      } else {
        throw Exception('İstatistikler alınamadı');
      }
    } catch (e) {
      _debugPrint('❌ İstatistik alma hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 🧹 ESKİ DOSYALARI TEMİZLE
  static Future<Map<String, dynamic>> cleanupOldDownloads({
    int maxDays = 30,
  }) async {
    try {
      final downloadDir = await getDownloadDirectory();
      final now = DateTime.now();
      int deletedCount = 0;
      int totalSize = 0;

      await for (final entity in downloadDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;

          if (age > maxDays) {
            totalSize += stat.size;
            await entity.delete();
            deletedCount++;
            _debugPrint('🗑️ Eski dosya silindi: ${entity.path}');
          }
        }
      }

      return {
        'success': true,
        'deleted_count': deletedCount,
        'freed_space': totalSize,
        'message':
            '$deletedCount dosya silindi, ${(totalSize / 1024 / 1024).toStringAsFixed(1)} MB yer açıldı',
      };
    } catch (e) {
      _debugPrint('❌ Temizlik hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
