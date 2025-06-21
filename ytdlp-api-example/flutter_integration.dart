// lib/services/ytdlp_api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class YtdlpApiService {
  static const String baseUrl =
      'https://your-api-domain.com'; // Sunucu URL'inizi buraya yazın
  static const String apiKey =
      'your-api-key-here'; // API anahtarınızı buraya yazın

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
}

// Enhanced Video Download Service Integration
class EnhancedVideoDownloadService {
  static Future<Map<String, dynamic>> downloadVideoWithApi({
    required String url,
    String format = 'mp4',
    Function(double)? onProgress,
  }) async {
    try {
      // 1. API sağlık kontrolü
      if (!await YtdlpApiService.checkHealth()) {
        return {
          'success': false,
          'error': 'API sunucusu erişilemez durumda',
        };
      }

      // 2. İndirme başlat
      final startResult = await YtdlpApiService.startDownload(
        url: url,
        format: format,
      );

      if (!startResult['success']) {
        return startResult;
      }

      final jobId = startResult['data']['job_id'];
      String fileName = 'video_$jobId.$format';

      // 3. İndirme durumunu takip et
      while (true) {
        await Future.delayed(Duration(seconds: 2));

        final statusResult = await YtdlpApiService.getDownloadStatus(jobId);

        if (!statusResult['success']) {
          return statusResult;
        }

        final status = statusResult['data'];
        final currentStatus = status['status'];
        final progress = status['progress']?.toDouble() ?? 0.0;

        // Progress callback
        if (onProgress != null) {
          onProgress(progress);
        }

        if (currentStatus == 'completed') {
          fileName = status['title'] ?? fileName;
          break;
        } else if (currentStatus == 'failed') {
          return {
            'success': false,
            'error': status['error'] ?? 'İndirme başarısız',
          };
        }
      }

      // 4. Dosyayı cihaza indir
      final downloadResult = await YtdlpApiService.downloadFile(
        jobId: jobId,
        fileName: fileName,
        onProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(95 + (received / total * 5)); // %95-100 arası
          }
        },
      );

      return downloadResult;
    } catch (e) {
      return {
        'success': false,
        'error': 'İndirme hatası: $e',
      };
    }
  }
}
