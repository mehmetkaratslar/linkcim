import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class YtdlpApiService {
  static const String baseUrl =
      'http://192.168.181.141:8000'; // Gerçek telefon için PC IP
  static const String apiKey =
      '45541d717524a99df5f994bb9f6cbce825269852be079594b8e35f7752d6f1bd'; // docker-compose.yml'deki API key

  static final Dio _dio = Dio();

  // Video indirme başlat
  static Future<Map<String, dynamic>> startDownload({
    required String url,
    String format = 'mp4',
    String quality = 'best',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/download'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'url': url,
          'format': format,
          'quality': quality,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // İndirme durumunu kontrol et
  static Future<Map<String, dynamic>> getDownloadStatus(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status/$jobId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Tamamlanan dosyayı indir
  static Future<Map<String, dynamic>> downloadFile({
    required String jobId,
    required String fileName,
    Function(int, int)? onProgress,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/downloads/$fileName';

      // Downloads dizini oluştur
      final downloadDir = Directory('${directory.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final response = await _dio.download(
        '$baseUrl/download/$jobId',
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
        onReceiveProgress: onProgress,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'file_path': filePath,
          'file_size': await File(filePath).length(),
        };
      } else {
        return {
          'success': false,
          'error': 'Download failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Download error: $e',
      };
    }
  }

  // Tüm işleri listele
  static Future<Map<String, dynamic>> listJobs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobs'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // API sağlık kontrolü
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // İş silme
  static Future<Map<String, dynamic>> deleteJob(String jobId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/download/$jobId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Job deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}

// Enhanced Video Download Service Integration
class EnhancedVideoDownloadService {
  static Future<Map<String, dynamic>> downloadVideoWithApi({
    required String url,
    String format = 'mp4',
    Function(double)? onProgress,
  }) async {
    try {
      print('🚀 API ile video indirme başlatılıyor: $url');

      // 1. API sağlık kontrolü
      if (!await YtdlpApiService.checkHealth()) {
        print('❌ API sunucusu erişilemez durumda');
        return {
          'success': false,
          'error': 'API sunucusu erişilemez durumda',
        };
      }

      print('✅ API sunucusu aktif');

      // 2. İndirme başlat
      final startResult = await YtdlpApiService.startDownload(
        url: url,
        format: format,
      );

      if (!startResult['success']) {
        print('❌ İndirme başlatılamadı: ${startResult['error']}');
        return startResult;
      }

      final jobId = startResult['data']['job_id'];
      print('✅ İndirme işi oluşturuldu: $jobId');

      String fileName = 'video_$jobId.$format';
      String? videoTitle;

      // 3. İndirme durumunu takip et
      int attempts = 0;
      const maxAttempts = 150; // 5 dakika (2 saniye * 150)

      while (attempts < maxAttempts) {
        await Future.delayed(Duration(seconds: 2));
        attempts++;

        final statusResult = await YtdlpApiService.getDownloadStatus(jobId);

        if (!statusResult['success']) {
          print('❌ Durum kontrolü başarısız: ${statusResult['error']}');
          return statusResult;
        }

        final status = statusResult['data'];
        final currentStatus = status['status'];
        final progress = status['progress']?.toDouble() ?? 0.0;

        print('📊 Durum: $currentStatus, İlerleme: %${progress.toInt()}');

        // Progress callback
        if (onProgress != null) {
          onProgress(progress);
        }

        if (currentStatus == 'completed') {
          videoTitle = status['title'];
          fileName = _sanitizeFileName(videoTitle ?? fileName);
          print('✅ İndirme tamamlandı: $fileName');
          break;
        } else if (currentStatus == 'failed') {
          print('❌ İndirme başarısız: ${status['error']}');
          return {
            'success': false,
            'error': status['error'] ?? 'İndirme başarısız',
          };
        }
      }

      if (attempts >= maxAttempts) {
        print('❌ İndirme zaman aşımına uğradı');
        return {
          'success': false,
          'error': 'İndirme zaman aşımına uğradı',
        };
      }

      // 4. Dosyayı cihaza indir
      print('📥 Dosya cihaza indiriliyor...');
      final downloadResult = await YtdlpApiService.downloadFile(
        jobId: jobId,
        fileName: fileName,
        onProgress: (received, total) {
          if (onProgress != null && total > 0) {
            final fileProgress = 95 + (received / total * 5); // %95-100 arası
            onProgress(fileProgress);
          }
        },
      );

      if (downloadResult['success']) {
        print('✅ Video başarıyla indirildi: ${downloadResult['file_path']}');

        // Sunucudaki işi temizle (opsiyonel)
        await YtdlpApiService.deleteJob(jobId);
      }

      return downloadResult;
    } catch (e) {
      print('❌ İndirme hatası: $e');
      return {
        'success': false,
        'error': 'İndirme hatası: $e',
      };
    }
  }

  // Dosya adını temizle (geçersiz karakterleri kaldır)
  static String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(
            RegExp(r'[<>:"/\\|?*]'), '_') // Windows geçersiz karakterleri
        .replaceAll(RegExp(r'\s+'), '_') // Boşlukları alt çizgi ile değiştir
        .substring(
            0, fileName.length > 100 ? 100 : fileName.length); // Uzunluk sınırı
  }

  // Mevcut video download service ile uyumluluk için
  static Future<Map<String, dynamic>> downloadVideo({
    required String url,
    Function(double)? onProgress,
  }) async {
    return await downloadVideoWithApi(
      url: url,
      format: 'mp4',
      onProgress: onProgress,
    );
  }
}
