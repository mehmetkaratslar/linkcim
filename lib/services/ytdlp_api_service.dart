import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class YtdlpApiService {
  static const String baseUrl = 'http://localhost:8000'; // Local Python API
  static const String apiKey =
      '45541d717524a99df5f994bb9f6cbce825269852be079594b8e35f7752d6f1bd';

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
        Uri.parse('$baseUrl/job/$jobId'),
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
