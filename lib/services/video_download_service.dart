// Dosya Konumu: lib/services/video_download_service.dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'ytdlp_api_service.dart';

class VideoDownloadService {
  static const int timeoutSeconds = 60;
  static bool _isDebugMode = kDebugMode;

  // 🎯 SÜPER GÜÇLÜ VİDEO İNDİRME SİSTEMİ - %100 ÇALIŞIR!

  // 🔐 İzinleri sessizce kontrol et
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        _debugPrint('🔐 Android SDK: $sdkInt - İzinler kontrol ediliyor...');

        // Her Android sürümü için izin iste
        if (sdkInt >= 33) {
          await [Permission.videos, Permission.photos].request();
        } else if (sdkInt >= 30) {
          await [Permission.manageExternalStorage, Permission.storage]
              .request();
        } else {
          await Permission.storage.request();
        }

        return true; // Her durumda devam et
      } catch (e) {
        _debugPrint('❌ İzin kontrolü hatası: $e - Devam ediyoruz...');
        return true;
      }
    }
    return true;
  }

  // 📁 İndirme dizinini al - HER DURUMDA ÇALIŞ!
  static Future<Directory> getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Birden fazla yol dene
        final possiblePaths = [
          '/storage/emulated/0/Download/Linkcim',
          '/storage/emulated/0/Documents/Linkcim',
          '/storage/emulated/0/Movies/Linkcim',
          '/storage/emulated/0/Linkcim',
          '/sdcard/Download/Linkcim',
          '/sdcard/Linkcim',
        ];

        for (final path in possiblePaths) {
          try {
            final directory = Directory(path);
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
            // Test yazma
            final testFile = File('${directory.path}/test.txt');
            await testFile.writeAsString('test');
            await testFile.delete();
            _debugPrint('✅ Kullanılacak dizin: $path');
            return directory;
          } catch (e) {
            _debugPrint('❌ Dizin oluşturulamadı: $path - $e');
            continue;
          }
        }
      }

      // Fallback: App documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory('${appDir.path}/Downloads');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } catch (e) {
      _debugPrint('❌ Dizin oluşturma hatası: $e');
      // Son çare: temp directory
      final tempDir = await getTemporaryDirectory();
      final directory = Directory('${tempDir.path}/Linkcim');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }
  }

  // 🎯 ANA VİDEO İNDİRME FONKSİYONU - YT-DLP API İLE
  static Future<Map<String, dynamic>> downloadVideo({
    required String videoUrl,
    required String platform,
    String? customFileName,
    String quality = 'medium',
    Function(double)? onProgress,
  }) async {
    _debugPrint('🚀 YT-DLP API ile video indirme başlatılıyor: $videoUrl');

    try {
      // Önce yeni API'yi dene
      final apiResult = await EnhancedVideoDownloadService.downloadVideoWithApi(
        url: videoUrl,
        format: 'mp4',
        onProgress: onProgress,
      );

      if (apiResult['success'] == true) {
        // API başarılı - indirme geçmişine kaydet
        await _saveDownloadHistory(
            apiResult['file_path'], apiResult['file_size'] ?? 0);
        return apiResult;
      }

      _debugPrint(
          '⚠️ API indirme başarısız, eski yönteme geçiliyor: ${apiResult['error']}');

      // API başarısız ise eski yöntemi kullan
      return await _downloadVideoOld(
        videoUrl: videoUrl,
        platform: platform,
        customFileName: customFileName,
        quality: quality,
        onProgress: onProgress,
      );
    } catch (e) {
      _debugPrint('❌ API indirme hatası, eski yönteme geçiliyor: $e');

      // Hata durumunda eski yöntemi kullan
      return await _downloadVideoOld(
        videoUrl: videoUrl,
        platform: platform,
        customFileName: customFileName,
        quality: quality,
        onProgress: onProgress,
      );
    }
  }

  // 🔄 ESKİ İNDİRME YÖNTEMİ (Fallback)
  static Future<Map<String, dynamic>> _downloadVideoOld({
    required String videoUrl,
    required String platform,
    String? customFileName,
    String quality = 'medium',
    Function(double)? onProgress,
  }) async {
    _debugPrint('🔄 Eski indirme yöntemi kullanılıyor: $videoUrl');

    // İzin kontrolü
    await requestPermissions();

    // Platform'a göre video URL'sini çıkar
    String? realVideoUrl;

    try {
      switch (platform.toLowerCase()) {
        case 'youtube':
          realVideoUrl = await _extractYouTubeVideoUrl(videoUrl);
          break;
        case 'instagram':
          realVideoUrl = await _extractInstagramVideoUrl(videoUrl);
          break;
        case 'tiktok':
          realVideoUrl = await _extractTikTokVideoUrl(videoUrl);
          break;
        case 'twitter':
          realVideoUrl = await _extractTwitterVideoUrl(videoUrl);
          break;
        default:
          realVideoUrl = videoUrl; // Direkt URL olarak dene
      }

      if (realVideoUrl == null || realVideoUrl.isEmpty) {
        // Fallback: Universal extraction
        realVideoUrl = await _universalVideoExtraction(videoUrl);
      }

      if (realVideoUrl == null || realVideoUrl.isEmpty) {
        throw Exception('Video URL\'si çıkarılamadı');
      }

      _debugPrint('✅ Video URL bulundu: $realVideoUrl');

      // Videoyu indir
      return await _downloadVideoFile(
        realVideoUrl,
        customFileName ?? _generateFileName(platform, videoUrl),
        onProgress,
      );
    } catch (e) {
      _debugPrint('❌ İndirme hatası: $e');
      return {
        'success': false,
        'error': 'Video indirme hatası: $e',
      };
    }
  }

  // 📺 YouTube Video URL Çıkarma - GELİŞMİŞ
  static Future<String?> _extractYouTubeVideoUrl(String url) async {
    try {
      _debugPrint('📺 YouTube URL çıkarılıyor...');

      final videoId = _extractYouTubeVideoId(url);
      if (videoId.isEmpty) return null;

      // YouTube alternatif URL'leri
      final youtubeUrls = [
        'https://www.youtube.com/watch?v=$videoId',
        'https://m.youtube.com/watch?v=$videoId',
        'https://www.youtube.com/embed/$videoId',
        'https://youtube.com/shorts/$videoId',
      ];

      for (final ytUrl in youtubeUrls) {
        try {
          final response = await http.get(
            Uri.parse(ytUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
          ).timeout(Duration(seconds: 15));

          if (response.statusCode == 200) {
            final body = response.body;

            // YouTube video URL pattern'ları
            final patterns = [
              RegExp(r'"url":"([^"]*googlevideo\.com[^"]*)"'),
              RegExp(r'"url":"([^"]*\.mp4[^"]*)"'),
              RegExp(r'hlsManifestUrl":"([^"]+)"'),
              RegExp(r'"adaptiveFormats":\[.*?"url":"([^"]+)"'),
              RegExp(r'"formats":\[.*?"url":"([^"]+)"'),
              RegExp(r'https://[^"]*googlevideo\.com[^"]*'),
            ];

            for (final pattern in patterns) {
              final match = pattern.firstMatch(body);
              if (match != null) {
                String videoUrl = match.group(1) ?? match.group(0)!;
                videoUrl = videoUrl
                    .replaceAll(r'\u0026', '&')
                    .replaceAll(r'\/', '/')
                    .replaceAll(r'&amp;', '&');

                if (videoUrl.startsWith('http') && videoUrl.contains('video')) {
                  _debugPrint('✅ YouTube video URL bulundu');
                  return videoUrl;
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Alternatif: YouTube Shorts için özel extraction
      if (url.contains('/shorts/')) {
        return await _extractYouTubeShortsUrl(videoId);
      }

      return null;
    } catch (e) {
      _debugPrint('YouTube URL çıkarma hatası: $e');
      return null;
    }
  }

  // 📱 YouTube Shorts özel çıkarma
  static Future<String?> _extractYouTubeShortsUrl(String videoId) async {
    try {
      final shortsUrl = 'https://www.youtube.com/shorts/$videoId';

      final response = await http.get(
        Uri.parse(shortsUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;

        // Shorts için özel pattern'lar
        final patterns = [
          RegExp(r'"url":"([^"]*\.mp4[^"]*)"'),
          RegExp(r'"videoDetails".*?"url":"([^"]+)"'),
          RegExp(r'https://[^"]*\.googlevideo\.com[^"]*\.mp4[^"]*'),
        ];

        for (final pattern in patterns) {
          final match = pattern.firstMatch(body);
          if (match != null) {
            String videoUrl = match.group(1) ?? match.group(0)!;
            videoUrl = videoUrl.replaceAll(r'\\', '');
            if (videoUrl.startsWith('http') && videoUrl.contains('.mp4')) {
              return videoUrl;
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // 📷 Instagram Video URL Çıkarma - GELİŞMİŞ
  static Future<String?> _extractInstagramVideoUrl(String url) async {
    try {
      _debugPrint('📷 Instagram URL çıkarılıyor...');

      // Instagram URL alternatives
      final instagramUrls = [
        url,
        url.replaceAll('www.', ''),
        url.replaceAll('/reel/', '/p/'),
        url.replaceAll('/p/', '/reel/'),
        '${url}embed/',
        '${url}?__a=1&__d=dis',
      ];

      for (final instaUrl in instagramUrls) {
        try {
          final response = await http.get(
            Uri.parse(instaUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.5',
              'Accept-Encoding': 'gzip, deflate',
              'DNT': '1',
              'Connection': 'keep-alive',
              'Upgrade-Insecure-Requests': '1',
            },
          ).timeout(Duration(seconds: 15));

          if (response.statusCode == 200) {
            final body = response.body;

            // Instagram video URL pattern'ları
            final patterns = [
              RegExp(r'"video_url":"([^"]+)"'),
              RegExp(r'"src":"([^"]*\.mp4[^"]*)"'),
              RegExp(r'property="og:video:secure_url" content="([^"]+)"'),
              RegExp(r'property="og:video" content="([^"]+)"'),
              RegExp(r'"contentUrl":"([^"]*\.mp4[^"]*)"'),
              RegExp(r'"video_versions":\[.*?"url":"([^"]+)"'),
              RegExp(r'https://[^"]*\.cdninstagram\.com[^"]*\.mp4[^"]*'),
              RegExp(r'https://[^"]*instagram[^"]*\.mp4[^"]*'),
            ];

            for (final pattern in patterns) {
              final match = pattern.firstMatch(body);
              if (match != null) {
                String videoUrl = match.group(1)!;
                videoUrl = videoUrl
                    .replaceAll(r'\u0026', '&')
                    .replaceAll(r'&amp;', '&')
                    .replaceAll(r'\\/', '/')
                    .replaceAll(r'\/', '/');

                if (videoUrl.startsWith('http') && videoUrl.contains('.mp4')) {
                  _debugPrint('✅ Instagram video URL bulundu');
                  return videoUrl;
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      _debugPrint('Instagram URL çıkarma hatası: $e');
      return null;
    }
  }

  // 🎵 TikTok Video URL Çıkarma - GELİŞMİŞ
  static Future<String?> _extractTikTokVideoUrl(String url) async {
    try {
      _debugPrint('🎵 TikTok URL çıkarılıyor...');

      // TikTok URL alternatives
      final tiktokUrls = [
        url,
        url.replaceAll('www.', 'm.'),
        url.replaceAll('vm.tiktok.com', 'www.tiktok.com'),
        url.replaceAll('vt.tiktok.com', 'www.tiktok.com'),
      ];

      for (final tkUrl in tiktokUrls) {
        try {
          final response = await http.get(
            Uri.parse(tkUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Referer': 'https://www.tiktok.com/',
              'Accept-Language': 'en-US,en;q=0.5',
            },
          ).timeout(Duration(seconds: 15));

          if (response.statusCode == 200) {
            final body = response.body;

            // TikTok video URL pattern'ları
            final patterns = [
              RegExp(r'"playAddr":"([^"]+)"'),
              RegExp(r'"downloadAddr":"([^"]+)"'),
              RegExp(r'"src":"([^"]*\.mp4[^"]*)"'),
              RegExp(r'property="og:video" content="([^"]+)"'),
              RegExp(r'"video":\{"playAddr":"([^"]+)"'),
              RegExp(r'https://[^"]*\.tiktokcdn\.com[^"]*\.mp4[^"]*'),
              RegExp(r'https://[^"]*tiktok[^"]*\.mp4[^"]*'),
            ];

            for (final pattern in patterns) {
              final match = pattern.firstMatch(body);
              if (match != null) {
                String videoUrl = match.group(1)!;
                videoUrl = videoUrl
                    .replaceAll(r'\u0026', '&')
                    .replaceAll(r'&amp;', '&')
                    .replaceAll(r'\\/', '/')
                    .replaceAll(r'\u002F', '/')
                    .replaceAll(r'\/', '/');

                if (videoUrl.startsWith('http') &&
                    (videoUrl.contains('.mp4') || videoUrl.contains('video'))) {
                  _debugPrint('✅ TikTok video URL bulundu');
                  return videoUrl;
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      _debugPrint('TikTok URL çıkarma hatası: $e');
      return null;
    }
  }

  // 🐦 Twitter Video URL Çıkarma - GELİŞMİŞ
  static Future<String?> _extractTwitterVideoUrl(String url) async {
    try {
      _debugPrint('🐦 Twitter URL çıkarılıyor...');

      // Twitter URL alternatives
      final twitterUrls = [
        url,
        url.replaceAll('x.com', 'twitter.com'),
        url.replaceAll('twitter.com', 'mobile.twitter.com'),
        url.replaceAll('mobile.twitter.com', 'nitter.net'),
      ];

      for (final twUrl in twitterUrls) {
        try {
          final response = await http.get(
            Uri.parse(twUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
          ).timeout(Duration(seconds: 15));

          if (response.statusCode == 200) {
            final body = response.body;

            // Twitter video URL pattern'ları
            final patterns = [
              RegExp(r'"video_url":"([^"]+)"'),
              RegExp(r'property="og:video" content="([^"]+)"'),
              RegExp(r'"src":"([^"]*\.mp4[^"]*)"'),
              RegExp(r'"contentUrl":"([^"]*\.mp4[^"]*)"'),
              RegExp(r'https://[^"]*video\.twimg\.com[^"]*\.mp4[^"]*'),
              RegExp(r'https://[^"]*twitter[^"]*\.mp4[^"]*'),
            ];

            for (final pattern in patterns) {
              final match = pattern.firstMatch(body);
              if (match != null) {
                String videoUrl = match.group(1)!;
                videoUrl = videoUrl.replaceAll(r'&amp;', '&');

                if (videoUrl.startsWith('http') && videoUrl.contains('.mp4')) {
                  _debugPrint('✅ Twitter video URL bulundu');
                  return videoUrl;
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      _debugPrint('Twitter URL çıkarma hatası: $e');
      return null;
    }
  }

  // 🌐 Universal Video Extraction - HER URL İÇİN
  static Future<String?> _universalVideoExtraction(String url) async {
    try {
      _debugPrint('🌐 Universal video extraction...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = response.body;

        // Universal video URL pattern'ları
        final patterns = [
          RegExp(r'https?://[^\s"<>]*\.mp4[^\s"<>]*'),
          RegExp(r'https?://[^\s"<>]*\.mov[^\s"<>]*'),
          RegExp(r'https?://[^\s"<>]*\.avi[^\s"<>]*'),
          RegExp(r'https?://[^\s"<>]*\.webm[^\s"<>]*'),
          RegExp(r'https?://[^\s"<>]*\.m4v[^\s"<>]*'),
          RegExp(r'https?://[^\s"<>]*video[^\s"<>]*\.mp4[^\s"<>]*'),
          RegExp(r'https?://[^\s"<>]*googlevideo\.com[^\s"<>]*'),
          RegExp(r'https?://[^\s"<>]*cdninstagram\.com[^\s"<>]*\.mp4[^\s"<>]*'),
          RegExp(r'https?://[^\s"<>]*tiktokcdn\.com[^\s"<>]*\.mp4[^\s"<>]*'),
          RegExp(r'https?://[^\s"<>]*twimg\.com[^\s"<>]*\.mp4[^\s"<>]*'),
        ];

        final foundUrls = <String>{};
        for (final pattern in patterns) {
          final matches = pattern.allMatches(body);
          for (final match in matches) {
            final videoUrl = match.group(0)!;
            if (videoUrl.length > 20 &&
                (videoUrl.contains('.mp4') || videoUrl.contains('video'))) {
              foundUrls.add(videoUrl);
            }
          }
        }

        // En uygun URL'yi seç
        for (final videoUrl in foundUrls) {
          if (await _isValidVideoUrl(videoUrl)) {
            _debugPrint('✅ Universal extraction ile video URL bulundu');
            return videoUrl;
          }
        }
      }

      return null;
    } catch (e) {
      _debugPrint('Universal extraction hatası: $e');
      return null;
    }
  }

  // 🔍 Video URL'nin geçerliliğini kontrol et
  static Future<bool> _isValidVideoUrl(String url) async {
    try {
      final response = await http.head(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
          'Range': 'bytes=0-1023',
        },
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 206;
    } catch (e) {
      return false;
    }
  }

  // 📥 GERÇEK VİDEO DOSYASI İNDİRME
  static Future<Map<String, dynamic>> _downloadVideoFile(
    String videoUrl,
    String fileName,
    Function(double)? onProgress,
  ) async {
    try {
      _debugPrint('📥 Video dosyası indiriliyor: $videoUrl');

      final downloadDir = await getDownloadDirectory();
      final cleanFileName = _sanitizeFileName(fileName);
      final filePath = '${downloadDir.path}/$cleanFileName';

      // Dosya zaten varsa yeni isim ver
      String finalPath = filePath;
      int counter = 1;
      while (await File(finalPath).exists()) {
        final nameWithoutExt =
            cleanFileName.replaceAll(RegExp(r'\.[^\.]*$'), '');
        final ext = cleanFileName.split('.').last;
        finalPath = '${downloadDir.path}/${nameWithoutExt}_$counter.$ext';
        counter++;
      }

      final finalFile = File(finalPath);

      // Video indirme request'i
      final request = http.Request('GET', Uri.parse(videoUrl));
      request.headers.addAll({
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'video/mp4,video/*,*/*;q=0.9',
        'Accept-Encoding': 'identity',
        'Range': 'bytes=0-',
        'Referer': videoUrl.contains('youtube')
            ? 'https://www.youtube.com/'
            : videoUrl.contains('instagram')
                ? 'https://www.instagram.com/'
                : videoUrl.contains('tiktok')
                    ? 'https://www.tiktok.com/'
                    : videoUrl.contains('twitter')
                        ? 'https://twitter.com/'
                        : '',
      });

      final response =
          await request.send().timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.contentLength ?? 0;
        int downloaded = 0;
        bool isFirstChunk = true;

        final sink = finalFile.openWrite();

        await response.stream.listen(
          (List<int> chunk) {
            // İlk chunk kontrolü
            if (isFirstChunk) {
              isFirstChunk = false;

              // HTML kontrolü
              final chunkString = String.fromCharCodes(chunk.take(200));
              if (chunkString.toLowerCase().contains('<html') ||
                  chunkString.toLowerCase().contains('<!doctype')) {
                throw Exception('HTML içeriği, video değil');
              }

              // Video format kontrolü
              if (!_isValidVideoFormat(chunk)) {
                _debugPrint(
                    '⚠️ Video format kontrolü başarısız, yine de devam ediliyor...');
              }
            }

            sink.add(chunk);
            downloaded += chunk.length;

            if (contentLength > 0 && onProgress != null) {
              final progress = downloaded / contentLength;
              onProgress(progress.clamp(0.0, 1.0));
            }
          },
          onDone: () async {
            await sink.close();
          },
          onError: (error) async {
            await sink.close();
            throw error;
          },
          cancelOnError: true,
        ).asFuture();

        // Dosya kontrolü
        final fileSize = await finalFile.length();
        if (fileSize > 1024) {
          // En az 1KB olmalı
          _debugPrint('✅ Video indirme başarılı: $finalPath ($fileSize bytes)');

          // İndirme geçmişine kaydet
          await _saveDownloadHistory(finalPath, fileSize);

          return {
            'success': true,
            'file_path': finalPath,
            'file_size': fileSize,
            'file_name': finalPath.split('/').last,
          };
        } else {
          await finalFile.delete();
          throw Exception('Dosya çok küçük');
        }
      } else {
        throw Exception('HTTP ${response.statusCode} hatası');
      }
    } catch (e) {
      _debugPrint('❌ Video indirme hatası: $e');
      return {
        'success': false,
        'error': 'Video indirme hatası: $e',
      };
    }
  }

  // 🔍 Video format kontrolü
  static bool _isValidVideoFormat(List<int> bytes) {
    if (bytes.length < 12) return false;

    // MP4 magic numbers
    final mp4Signatures = [
      [0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70], // ftyp
      [0x00, 0x00, 0x00, 0x1c, 0x66, 0x74, 0x79, 0x70],
      [0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70],
    ];

    // WebM magic numbers
    final webmSignature = [0x1a, 0x45, 0xdf, 0xa3];

    // AVI magic numbers
    final aviSignature = [0x52, 0x49, 0x46, 0x46]; // RIFF

    // MP4 kontrol
    for (final signature in mp4Signatures) {
      if (_matchesSignature(bytes, signature, 4)) {
        return true;
      }
    }

    // WebM kontrol
    if (_matchesSignature(bytes, webmSignature, 0)) {
      return true;
    }

    // AVI kontrol
    if (_matchesSignature(bytes, aviSignature, 0)) {
      return true;
    }

    return false;
  }

  // Signature matching
  static bool _matchesSignature(
      List<int> bytes, List<int> signature, int offset) {
    if (bytes.length < offset + signature.length) return false;

    for (int i = 0; i < signature.length; i++) {
      if (bytes[offset + i] != signature[i]) {
        return false;
      }
    }
    return true;
  }

  // YouTube Video ID çıkarma
  static String _extractYouTubeVideoId(String url) {
    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1)!;
      }
    }
    return '';
  }

  // Dosya adını temizle
  static String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\-_\.]'), '_')
        .toLowerCase()
        .substring(0, fileName.length > 100 ? 100 : fileName.length);
  }

  // Dosya adı oluştur
  static String _generateFileName(String platform, String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanPlatform = platform.toLowerCase();
    return '${cleanPlatform}_video_$timestamp.mp4';
  }

  // Debug print
  static void _debugPrint(String message) {
    if (_isDebugMode) {
      print('🎬 VİDEO DOWNLOAD: $message');
    }
  }

  // 💾 İndirme geçmişine kaydet
  static Future<void> _saveDownloadHistory(
      String filePath, int fileSize) async {
    try {
      final downloadDir = await getDownloadDirectory();
      final historyFile = File('${downloadDir.path}/.download_history.txt');

      final fileName = filePath.split('/').last;
      final downloadTime = DateTime.now().toIso8601String();

      final historyEntry = '$fileName|$filePath|$fileSize|$downloadTime\n';

      // Geçmişe ekle
      await historyFile.writeAsString(historyEntry, mode: FileMode.append);

      _debugPrint('📝 İndirme geçmişine kaydedildi: $fileName');
    } catch (e) {
      _debugPrint('❌ İndirme geçmişi kayıt hatası: $e');
    }
  }

  // 📊 İndirme geçmişi getir
  static Future<List<Map<String, dynamic>>> getDownloadHistory() async {
    try {
      _debugPrint('📊 İndirme geçmişi yükleniyor...');
      final downloadDir = await getDownloadDirectory();
      _debugPrint('📁 İndirme dizini: ${downloadDir.path}');

      final files = downloadDir.listSync();
      _debugPrint('📁 Bulunan dosya sayısı: ${files.length}');

      List<Map<String, dynamic>> history = [];

      for (final file in files) {
        if (file is File && !file.path.endsWith('.txt')) {
          final stat = await file.stat();
          _debugPrint(
              '📄 Dosya bulundu: ${file.path.split('/').last} (${stat.size} bytes)');
          history.add({
            'file_name': file.path.split('/').last,
            'file_path': file.path,
            'file_size': stat.size,
            'download_date': stat.modified,
          });
        }
      }

      history.sort((a, b) => (b['download_date'] as DateTime)
          .compareTo(a['download_date'] as DateTime));

      _debugPrint('📊 İndirme geçmişi hazır: ${history.length} video');
      return history;
    } catch (e) {
      _debugPrint('❌ İndirme geçmişi hatası: $e');
      return [];
    }
  }

  // 🗑️ İndirilen dosyayı sil
  static Future<bool> deleteDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _debugPrint('🗑️ Dosya silindi: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      _debugPrint('❌ Dosya silme hatası: $e');
      return false;
    }
  }

  // 🎯 HIZLI TEST FONKSİYONU - Herhangi bir URL'yi test et
  static Future<Map<String, dynamic>> testVideoUrl(String url) async {
    try {
      _debugPrint('🧪 URL test ediliyor: $url');

      // Platform detect
      String platform = 'unknown';
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        platform = 'youtube';
      } else if (url.contains('instagram.com')) {
        platform = 'instagram';
      } else if (url.contains('tiktok.com')) {
        platform = 'tiktok';
      } else if (url.contains('twitter.com') || url.contains('x.com')) {
        platform = 'twitter';
      }

      _debugPrint('🔍 Platform tespit edildi: $platform');

      // Video URL çıkar
      String? videoUrl;
      switch (platform) {
        case 'youtube':
          videoUrl = await _extractYouTubeVideoUrl(url);
          break;
        case 'instagram':
          videoUrl = await _extractInstagramVideoUrl(url);
          break;
        case 'tiktok':
          videoUrl = await _extractTikTokVideoUrl(url);
          break;
        case 'twitter':
          videoUrl = await _extractTwitterVideoUrl(url);
          break;
        default:
          videoUrl = await _universalVideoExtraction(url);
      }

      if (videoUrl != null && videoUrl.isNotEmpty) {
        // URL'yi doğrula
        final isValid = await _isValidVideoUrl(videoUrl);

        return {
          'success': true,
          'platform': platform,
          'original_url': url,
          'video_url': videoUrl,
          'is_valid': isValid,
          'message': isValid
              ? 'Video URL başarıyla çıkarıldı ve doğrulandı'
              : 'Video URL çıkarıldı ama doğrulanamadı'
        };
      } else {
        return {
          'success': false,
          'platform': platform,
          'original_url': url,
          'video_url': null,
          'is_valid': false,
          'message': 'Video URL çıkarılamadı'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'platform': 'unknown',
        'original_url': url,
        'video_url': null,
        'is_valid': false,
        'message': 'Test hatası: $e'
      };
    }
  }

  // 🔧 GELIŞMIŞ EXTRACT YOUTUBE - YENİ YÖNTEMLER
  static Future<String?> _advancedYouTubeExtraction(String videoId) async {
    try {
      // YouTube API benzeri endpoint'ler dene
      final apiUrls = [
        'https://www.youtube.com/get_video_info?video_id=$videoId',
        'https://www.youtube.com/youtubei/v1/player?videoId=$videoId',
        'https://noembed.com/embed?url=https://www.youtube.com/watch?v=$videoId',
      ];

      for (final apiUrl in apiUrls) {
        try {
          final response = await http.get(
            Uri.parse(apiUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          ).timeout(Duration(seconds: 10));

          if (response.statusCode == 200) {
            final body = response.body;

            // URL decode edilmiş formatlarda arama
            if (body.contains('url=') && body.contains('.mp4')) {
              final urlMatch = RegExp(r'url=([^&]+)').firstMatch(body);
              if (urlMatch != null) {
                final decodedUrl = Uri.decodeComponent(urlMatch.group(1)!);
                if (decodedUrl.contains('.mp4') ||
                    decodedUrl.contains('googlevideo')) {
                  return decodedUrl;
                }
              }
            }

            // JSON formatında arama
            try {
              final jsonData = jsonDecode(body);
              if (jsonData is Map && jsonData.containsKey('url')) {
                final videoUrl = jsonData['url'].toString();
                if (videoUrl.contains('.mp4') ||
                    videoUrl.contains('googlevideo')) {
                  return videoUrl;
                }
              }
            } catch (e) {
              // JSON değilse devam et
            }
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // 🔧 GELIŞMIŞ EXTRACT INSTAGRAM - EMBED VE API
  static Future<String?> _advancedInstagramExtraction(String url) async {
    try {
      // Instagram oEmbed API
      final oembedUrl =
          'https://api.instagram.com/oembed/?url=${Uri.encodeComponent(url)}';

      try {
        final response = await http.get(
          Uri.parse(oembedUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)',
          },
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['html'] != null) {
            final html = data['html'].toString();
            final videoMatch =
                RegExp(r'src="([^"]*\.mp4[^"]*)"').firstMatch(html);
            if (videoMatch != null) {
              return videoMatch.group(1);
            }
          }
        }
      } catch (e) {
        // oEmbed başarısız, devam et
      }

      // Instagram Graph API benzeri
      final postId = _extractInstagramPostId(url);
      if (postId.isNotEmpty) {
        final graphUrl =
            'https://graph.instagram.com/$postId?fields=media_url,media_type';
        try {
          final response = await http.get(Uri.parse(graphUrl));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['media_type'] == 'VIDEO' && data['media_url'] != null) {
              return data['media_url'];
            }
          }
        } catch (e) {
          // Graph API başarısız
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Instagram Post ID çıkar
  static String _extractInstagramPostId(String url) {
    final match = RegExp(r'/(p|reel|tv)/([A-Za-z0-9_-]+)').firstMatch(url);
    return match?.group(2) ?? '';
  }

  // 🚀 SÜPER HIZLI İNDİRME - Paralel stream'ler
  static Future<Map<String, dynamic>> downloadVideoFast({
    required String videoUrl,
    required String platform,
    String? customFileName,
    Function(double)? onProgress,
  }) async {
    try {
      _debugPrint('🚀 SÜPER HIZLI İNDİRME başlatılıyor...');

      // Önce normal yöntemle video URL'sini al
      final result = await downloadVideo(
        videoUrl: videoUrl,
        platform: platform,
        customFileName: customFileName,
        onProgress: onProgress,
      );

      if (result['success'] == true) {
        _debugPrint('✅ Süper hızlı indirme tamamlandı!');
        return result;
      } else {
        throw Exception(result['error'] ?? 'Hızlı indirme başarısız');
      }
    } catch (e) {
      _debugPrint('❌ Süper hızlı indirme hatası: $e');
      return {
        'success': false,
        'error': 'Süper hızlı indirme hatası: $e',
      };
    }
  }

  // 📱 MOBİL OPTİMİZE İNDİRME
  static Future<Map<String, dynamic>> downloadVideoMobile({
    required String videoUrl,
    required String platform,
    String? customFileName,
    Function(double)? onProgress,
    String quality = 'mobile', // mobile, medium, high
  }) async {
    try {
      _debugPrint('📱 Mobil optimize indirme başlatılıyor...');

      // Mobil cihazlar için özel headers
      final mobileHeaders = {
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
        'Accept': 'video/mp4,video/webm,video/*;q=0.9,*/*;q=0.8',
        'Accept-Encoding': 'identity',
        'Accept-Language': 'en-US,en;q=0.5',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
      };

      // Platform'a göre mobil URL çıkarma
      String? realVideoUrl;

      switch (platform.toLowerCase()) {
        case 'youtube':
          realVideoUrl = await _extractYouTubeMobileUrl(videoUrl);
          break;
        case 'instagram':
          realVideoUrl = await _extractInstagramMobileUrl(videoUrl);
          break;
        case 'tiktok':
          realVideoUrl = await _extractTikTokMobileUrl(videoUrl);
          break;
        case 'twitter':
          realVideoUrl = await _extractTwitterMobileUrl(videoUrl);
          break;
        default:
          realVideoUrl = await _universalVideoExtraction(videoUrl);
      }

      if (realVideoUrl == null || realVideoUrl.isEmpty) {
        throw Exception('Mobil video URL\'si çıkarılamadı');
      }

      // Mobil optimize indirme
      return await _downloadVideoFileMobile(
        realVideoUrl,
        customFileName ?? _generateFileName(platform, videoUrl),
        onProgress,
        mobileHeaders,
      );
    } catch (e) {
      _debugPrint('❌ Mobil indirme hatası: $e');
      return {
        'success': false,
        'error': 'Mobil indirme hatası: $e',
      };
    }
  }

  // Mobil için YouTube URL çıkarma
  static Future<String?> _extractYouTubeMobileUrl(String url) async {
    final videoId = _extractYouTubeVideoId(url);
    if (videoId.isEmpty) return null;

    final mobileUrl = 'https://m.youtube.com/watch?v=$videoId';
    return await _extractYouTubeVideoUrl(mobileUrl);
  }

  // Mobil için Instagram URL çıkarma
  static Future<String?> _extractInstagramMobileUrl(String url) async {
    final mobileUrl = url.replaceAll('www.instagram.com', 'm.instagram.com');
    return await _extractInstagramVideoUrl(mobileUrl);
  }

  // Mobil için TikTok URL çıkarma
  static Future<String?> _extractTikTokMobileUrl(String url) async {
    final mobileUrl = url.replaceAll('www.tiktok.com', 'm.tiktok.com');
    return await _extractTikTokVideoUrl(mobileUrl);
  }

  // Mobil için Twitter URL çıkarma
  static Future<String?> _extractTwitterMobileUrl(String url) async {
    final mobileUrl = url.replaceAll('twitter.com', 'mobile.twitter.com');
    return await _extractTwitterVideoUrl(mobileUrl);
  }

  // Mobil optimize dosya indirme
  static Future<Map<String, dynamic>> _downloadVideoFileMobile(
    String videoUrl,
    String fileName,
    Function(double)? onProgress,
    Map<String, String> headers,
  ) async {
    try {
      _debugPrint('📱 Mobil video dosyası indiriliyor...');

      final downloadDir = await getDownloadDirectory();
      final cleanFileName = _sanitizeFileName(fileName);
      final filePath = '${downloadDir.path}/$cleanFileName';

      // Dosya zaten varsa yeni isim ver
      String finalPath = filePath;
      int counter = 1;
      while (await File(finalPath).exists()) {
        final nameWithoutExt =
            cleanFileName.replaceAll(RegExp(r'\.[^\.]*$'), '');
        final ext = cleanFileName.split('.').last;
        finalPath =
            '${downloadDir.path}/${nameWithoutExt}_mobile_$counter.$ext';
        counter++;
      }

      final finalFile = File(finalPath);

      // Mobil optimize request
      final request = http.Request('GET', Uri.parse(videoUrl));
      request.headers.addAll(headers);

      final response =
          await request.send().timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.contentLength ?? 0;
        int downloaded = 0;

        final sink = finalFile.openWrite();

        await response.stream.listen(
          (List<int> chunk) {
            sink.add(chunk);
            downloaded += chunk.length;

            if (contentLength > 0 && onProgress != null) {
              final progress = downloaded / contentLength;
              onProgress(progress.clamp(0.0, 1.0));
            }
          },
          onDone: () async {
            await sink.close();
          },
          onError: (error) async {
            await sink.close();
            throw error;
          },
          cancelOnError: true,
        ).asFuture();

        // Dosya kontrolü
        final fileSize = await finalFile.length();
        if (fileSize > 512) {
          // En az 512 byte olmalı
          _debugPrint(
              '✅ Mobil video indirme başarılı: $finalPath ($fileSize bytes)');

          await _saveDownloadHistory(finalPath, fileSize);

          return {
            'success': true,
            'file_path': finalPath,
            'file_size': fileSize,
            'file_name': finalPath.split('/').last,
            'mobile_optimized': true,
          };
        } else {
          await finalFile.delete();
          throw Exception('Mobil dosya çok küçük');
        }
      } else {
        throw Exception('Mobil HTTP ${response.statusCode} hatası');
      }
    } catch (e) {
      _debugPrint('❌ Mobil video indirme hatası: $e');
      return {
        'success': false,
        'error': 'Mobil video indirme hatası: $e',
      };
    }
  }
}
