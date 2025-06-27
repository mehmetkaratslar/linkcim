import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
        // Android için önce external storage'ı dene
        try {
          final externalDir = Directory('/storage/emulated/0/Download/Linkcim');
          if (!await externalDir.exists()) {
            await externalDir.create(recursive: true);
          }

          // Yazma izni test et
          final testFile = File('${externalDir.path}/.test_write');
          await testFile.writeAsString('test');
          await testFile.delete();

          _debugPrint(
              '✅ External Downloads klasörü kullanılıyor: ${externalDir.path}');
          return externalDir;
        } catch (e) {
          _debugPrint('⚠️ External storage erişimi yok: $e');
        }

        // External storage başarısızsa internal storage kullan
        final appDir = await getApplicationDocumentsDirectory();
        final internalDir = Directory('${appDir.path}/Downloads');
        if (!await internalDir.exists()) {
          await internalDir.create(recursive: true);
        }
        _debugPrint('📱 Internal storage kullanılıyor: ${internalDir.path}');
        return internalDir;
      }

      // iOS ve diğer platformlar için
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory('${appDir.path}/Downloads');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } catch (e) {
      _debugPrint('❌ Download directory hatası: $e');
      // Son çare olarak temp directory kullan
      final tempDir = await getTemporaryDirectory();
      final directory = Directory('${tempDir.path}/Linkcim');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      _debugPrint('🔄 Temp directory kullanılıyor: ${directory.path}');
      return directory;
    }
  }

  // 🎯 ANA VİDEO İNDİRME FONKSİYONU - PYTHON API İLE
  static Future<Map<String, dynamic>> downloadVideo({
    required String videoUrl,
    required String platform,
    String? customFileName,
    String format = 'mp4',
    String quality = 'medium',
    Function(double)? onProgress,
  }) async {
    _debugPrint('🚀 Python API ile video indirme başlatılıyor: $videoUrl');

    try {
      // İzin kontrolü
      await requestPermissions();

      // 1️⃣ Python API'ye indirme isteği gönder
      final startResult =
          await _startDownload(videoUrl, platform, format, quality);
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

      // 4️⃣ İndirme geçmişine kaydet - sadece burada kaydet
      // Not: Dialog'da da kayıt yapılıyor, burada kaldırıyoruz

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
  static Future<Map<String, dynamic>> checkApiHealth() async {
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
          'status': 'healthy',
          'data': data,
        };
      } else {
        throw Exception('API Health Check Failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
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

  // 🔧 PRİVATE YARDIMCI FONKSİYONLAR

  // 1️⃣ İndirme işini başlat
  static Future<Map<String, dynamic>> _startDownload(
      String videoUrl, String platform, String format, String quality) async {
    try {
      _debugPrint('📤 Python API\'ye indirme isteği gönderiliyor...');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/download'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'url': videoUrl,
              'format': format,
              'quality': quality,
              'platform': platform,
              'extract_audio': format == 'mp3',
            }),
          )
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'job_id': data['job_id'],
          'message': 'İndirme işi başlatıldı',
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'İndirme başlatılamadı');
      }
    } catch (e) {
      _debugPrint('❌ İndirme başlatma hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 2️⃣ İndirme durumunu takip et
  static Future<Map<String, dynamic>> _pollDownloadStatus(
      String jobId, Function(double)? onProgress) async {
    try {
      _debugPrint('🔄 İndirme durumu takip ediliyor: $jobId');

      int attempts = 0;
      const maxAttempts = 60; // 2 dakika maksimum bekleme

      while (attempts < maxAttempts) {
        final response = await http.get(
          Uri.parse('$_baseUrl/status/$jobId'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final status = data['status'];
          final progress = (data['progress'] ?? 0.0).toDouble();

          _debugPrint(
              '📊 Durum: $status, İlerleme: ${(progress * 100).toInt()}%');

          if (onProgress != null) {
            onProgress(progress);
          }

          if (status == 'completed') {
            return {
              'success': true,
              'job_data': data,
              'message': 'İndirme tamamlandı',
            };
          } else if (status == 'failed' || status == 'error') {
            throw Exception(data['error'] ?? 'İndirme başarısız');
          }

          // Bekle ve tekrar kontrol et
          await Future.delayed(Duration(milliseconds: _pollIntervalMs));
          attempts++;
        } else {
          throw Exception('Durum kontrolü başarısız: ${response.statusCode}');
        }
      }

      throw Exception('İndirme zaman aşımına uğradı');
    } catch (e) {
      _debugPrint('❌ Durum takip hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 3️⃣ Tamamlanan dosyayı indir
  static Future<Map<String, dynamic>> _downloadCompletedFile(
      String jobId, Map<String, dynamic> jobData) async {
    try {
      _debugPrint('⬇️ Tamamlanan dosya indiriliyor: $jobId');

      final downloadUrl = '$_baseUrl/download/$jobId';
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        // Dosya adını oluştur
        final title = jobData['title'] ?? 'video';
        final platform = jobData['platform'] ?? 'unknown';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName =
            '${_sanitizeFileName(title)}_${platform}_$timestamp.mp4';

        // İndirme dizinini al
        final downloadDir = await getDownloadDirectory();
        final filePath = '${downloadDir.path}/$fileName';

        // Dosyayı kaydet
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Dosya boyutunu kontrol et
        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('İndirilen dosya boş');
        }

        _debugPrint(
            '✅ Dosya kaydedildi: $filePath (${_formatFileSize(fileSize)})');

        // Galeriye otomatik kaydet
        try {
          await Gal.putVideo(filePath);
          _debugPrint('📱 Video galeriye kaydedildi');
        } catch (e) {
          _debugPrint('⚠️ Galeriye kaydetme hatası (normal): $e');
          // Bu hata kritik değil, dosya yine de kaydedildi
        }

        return {
          'success': true,
          'file_path': filePath,
          'file_size': fileSize,
          'file_name': fileName,
          'message': 'Dosya başarıyla kaydedildi ve galeriye eklendi',
        };
      } else {
        throw Exception('Dosya indirilemedi: ${response.statusCode}');
      }
    } catch (e) {
      _debugPrint('❌ Dosya indirme hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 4️⃣ İndirme geçmişine kaydet
  static Future<void> _saveDownloadHistory(String filePath, int fileSize,
      {String? title, String? platform}) async {
    try {
      final fileName = filePath.split('/').last;
      final downloadDate = DateTime.now();

      // Hive veritabanına kaydet
      final box = await Hive.openBox('downloadHistory');
      final currentHistory =
          box.get('downloads', defaultValue: <Map<String, dynamic>>[]);
      final historyList = List<Map<String, dynamic>>.from(currentHistory);

      // Yeni indirme kaydı
      final downloadRecord = {
        'file_name': fileName,
        'file_path': filePath,
        'file_size': fileSize,
        'download_date': downloadDate,
        'title': title ?? fileName.replaceAll('.mp4', ''),
        'platform': platform ?? 'unknown',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      // Listeye ekle (en yeniler başta)
      historyList.insert(0, downloadRecord);

      // Maksimum 100 kayıt tut
      if (historyList.length > 100) {
        historyList.removeRange(100, historyList.length);
      }

      // Veritabanına kaydet
      await box.put('downloads', historyList);

      _debugPrint(
          '📝 İndirme geçmişine kaydedildi: $fileName (${historyList.length} toplam kayıt)');
    } catch (e) {
      _debugPrint('❌ Geçmiş kaydetme hatası: $e');
    }
  }

  // 🔧 Dosya adını temizle
  static String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  // 📏 Dosya boyutunu formatla
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // 🔧 Varsayılan platform listesi
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

  // 🐛 Debug yazdırma
  static void _debugPrint(String message) {
    if (_isDebugMode) {
      print('🎬 VideoDownloadService: $message');
    }
  }
}
