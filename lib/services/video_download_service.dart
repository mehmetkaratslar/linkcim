import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class VideoDownloadService {
  static const int timeoutSeconds = 30;
  static bool _isDebugMode = kDebugMode;

  // 🎯 SÜPER GÜÇLÜ VİDEO İNDİRME SİSTEMİ - OFFLINE + ONLINE

  // 🔐 İzinleri sessizce kontrol et
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        _debugPrint(
            '🔐 Android SDK: $sdkInt - İzinler sessizce kontrol ediliyor...');

        List<Permission> permissions = [];

        if (sdkInt >= 33) {
          permissions.addAll([
            Permission.videos,
            Permission.photos,
            Permission.storage,
          ]);
        } else if (sdkInt >= 30) {
          permissions.addAll([
            Permission.manageExternalStorage,
            Permission.storage,
          ]);
        } else {
          permissions.add(Permission.storage);
        }

        // Sadece durumu kontrol et, zorla isteme
        bool hasAnyPermission = false;
        for (final permission in permissions) {
          var status = await permission.status;
          if (status.isGranted) {
            hasAnyPermission = true;
            break;
          }
        }

        // Eğer hiç izin yoksa sadece bir kez iste
        if (!hasAnyPermission) {
          _debugPrint('📝 İzin yok, tek seferlik istek gönderiliyor...');
          await Permission.storage.request();
        }

        return true; // Her durumda true döndür ve indirmeyi dene
      } catch (e) {
        _debugPrint('❌ İzin kontrolü hatası: $e - Devam ediyoruz...');
        return true; // Hata olsa bile devam et
      }
    }
    return true;
  }

  // 📁 İndirme dizinini al - HER DURUMDA ÇALIŞ!
  static Future<Directory> getDownloadDirectory() async {
    Directory? directory;

    try {
      if (Platform.isAndroid) {
        // Birden fazla yol dene
        final possiblePaths = [
          '/storage/emulated/0/Download/Linkcim',
          '/storage/emulated/0/Documents/Linkcim',
          '/storage/emulated/0/Linkcim',
          '/sdcard/Download/Linkcim',
          '/sdcard/Linkcim',
        ];

        for (final path in possiblePaths) {
          try {
            directory = Directory(path);
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

        // Hiçbiri çalışmazsa app internal'ı kullan
        final appDir = await getApplicationDocumentsDirectory();
        directory = Directory('${appDir.path}/Downloads');
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        directory = Directory('${appDir.path}/Downloads');
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      return directory;
    } catch (e) {
      _debugPrint('❌ Dizin oluşturma hatası: $e');
      // Son çare olarak temp dizini kullan
      final tempDir = await getTemporaryDirectory();
      directory = Directory('${tempDir.path}/Linkcim');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }
  }

  // 🎯 SÜPER GÜÇLÜ VİDEO İNDİRME FONKSİYONU
  static Future<Map<String, dynamic>> downloadVideo({
    required String videoUrl,
    required String platform,
    String? customFileName,
    String quality = 'medium',
    Function(double)? onProgress,
  }) async {
    _debugPrint('🚀 SÜPER GÜÇLÜ VİDEO İNDİRME BAŞLATILIYOR: $videoUrl');

    // İzin kontrolü (başarısız olsa bile devam et)
    await requestPermissions();

    // ÇOKLU STRATEJİ SİSTEMİ - OFFLINE + ONLINE
    final strategies = [
      () => _strategyDirectVideoUrl(videoUrl, customFileName, onProgress),
      () => _strategyPlatformSpecific(
          videoUrl, platform, customFileName, onProgress),
      () => _strategyDeepScraping(videoUrl, customFileName, onProgress),
      () => _strategyAlternativeAPIs(videoUrl, customFileName, onProgress),
      () => _strategyForcedDownload(videoUrl, customFileName, onProgress),
    ];

    for (int i = 0; i < strategies.length; i++) {
      try {
        _debugPrint('🔄 Deneniyor: Strateji ${i + 1}/${strategies.length}');
        final result = await strategies[i]();
        if (result['success'] == true) {
          _debugPrint('✅ BAŞARILI! Strateji ${i + 1} ile indirildi!');
          return result;
        }
      } catch (e) {
        _debugPrint('❌ Strateji ${i + 1} hatası: $e');
        continue;
      }
    }

    return {
      'success': false,
      'error': 'Tüm indirme yöntemleri denendi. Video indirilemedi.',
    };
  }

  // 🎯 STRATEJİ 1: Direkt Video URL Arama
  static Future<Map<String, dynamic>> _strategyDirectVideoUrl(
      String url, String? fileName, Function(double)? onProgress) async {
    _debugPrint('🎯 Strateji 1: Direkt video URL arama');

    // URL'de direkt video uzantısı var mı?
    if (url.contains('.mp4') ||
        url.contains('.mov') ||
        url.contains('.avi') ||
        url.contains('.webm')) {
      return await _downloadRealVideoFile(
        url,
        fileName ?? 'direct_${DateTime.now().millisecondsSinceEpoch}.mp4',
        onProgress,
      );
    }

    // URL'ye video format parametresi ekle
    final directUrls = [
      '$url&format=mp4',
      '$url.mp4',
      '$url/video.mp4',
      url.replaceAll('watch?v=', 'embed/'),
      url.replaceAll('/reel/', '/embed/'),
      url.replaceAll('/video/', '/embed/'),
    ];

    for (final directUrl in directUrls) {
      try {
        final result = await _downloadRealVideoFile(
          directUrl,
          fileName ?? 'direct_${DateTime.now().millisecondsSinceEpoch}.mp4',
          onProgress,
        );
        if (result['success'] == true) {
          return result;
        }
      } catch (e) {
        continue;
      }
    }

    throw Exception('Direkt video URL bulunamadı');
  }

  // 🎯 STRATEJİ 2: Platform Spesifik İyileştirilmiş
  static Future<Map<String, dynamic>> _strategyPlatformSpecific(String url,
      String platform, String? fileName, Function(double)? onProgress) async {
    _debugPrint('🎯 Strateji 2: Platform spesifik gelişmiş arama');

    switch (platform.toLowerCase()) {
      case 'youtube':
        return await _extractYouTubeAdvanced(url, fileName, onProgress);
      case 'instagram':
        return await _extractInstagramAdvanced(url, fileName, onProgress);
      case 'tiktok':
        return await _extractTikTokAdvanced(url, fileName, onProgress);
      case 'twitter':
        return await _extractTwitterAdvanced(url, fileName, onProgress);
      default:
        throw Exception('Platform desteklenmiyor');
    }
  }

  // 📺 YouTube Gelişmiş Çıkarma
  static Future<Map<String, dynamic>> _extractYouTubeAdvanced(
      String url, String? fileName, Function(double)? onProgress) async {
    try {
      _debugPrint('📺 YouTube gelişmiş URL çıkarma...');

      final videoId = _extractYouTubeVideoId(url);
      if (videoId.isEmpty) {
        throw Exception('YouTube video ID bulunamadı');
      }

      // Çoklu YouTube URL'leri dene
      final youtubeUrls = [
        'https://www.youtube.com/embed/$videoId',
        'https://www.youtube.com/watch?v=$videoId',
        'https://m.youtube.com/watch?v=$videoId',
        'https://youtube.com/shorts/$videoId',
        'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json',
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
          ).timeout(Duration(seconds: 10));

          if (response.statusCode == 200) {
            final body = response.body;

            // Gelişmiş pattern'lar
            final patterns = [
              RegExp(r'"url":"([^"]*googlevideo\.com[^"]*)"'),
              RegExp(r'"url":"([^"]*\.mp4[^"]*)"'),
              RegExp(r'hlsManifestUrl":"([^"]+)"'),
              RegExp(r'"adaptiveFormats":\[.*?"url":"([^"]+)"'),
              RegExp(r'"formats":\[.*?"url":"([^"]+)"'),
              RegExp(r'videoplayback\?[^"]*'),
              RegExp(r'https://[^"]*googlevideo\.com[^"]*'),
            ];

            for (final pattern in patterns) {
              final match = pattern.firstMatch(body);
              if (match != null) {
                String videoUrl = match.group(1)!;
                videoUrl = videoUrl
                    .replaceAll(r'\u0026', '&')
                    .replaceAll(r'\/', '/')
                    .replaceAll(r'&amp;', '&');

                if (videoUrl.startsWith('http')) {
                  return await _downloadRealVideoFile(
                    videoUrl,
                    fileName ?? 'youtube_$videoId.mp4',
                    onProgress,
                  );
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      throw Exception('YouTube video URL bulunamadı');
    } catch (e) {
      _debugPrint('YouTube gelişmiş çıkarma hatası: $e');
      throw e;
    }
  }

  // 📷 Instagram Gelişmiş Çıkarma
  static Future<Map<String, dynamic>> _extractInstagramAdvanced(
      String url, String? fileName, Function(double)? onProgress) async {
    try {
      _debugPrint('📷 Instagram gelişmiş URL çıkarma...');

      // Instagram alternatif URL'leri
      final instagramUrls = [
        url,
        url.replaceAll('www.', ''),
        url.replaceAll('/reel/', '/p/'),
        url.replaceAll('/p/', '/reel/'),
        '${url}embed/',
        '${url}?__a=1',
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
            },
          ).timeout(Duration(seconds: 10));

          if (response.statusCode == 200) {
            final body = response.body;

            // Gelişmiş Instagram pattern'ları
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
                    .replaceAll(r'\\/', '/');

                if (videoUrl.startsWith('http') && videoUrl.contains('.mp4')) {
                  return await _downloadRealVideoFile(
                    videoUrl,
                    fileName ??
                        'instagram_${DateTime.now().millisecondsSinceEpoch}.mp4',
                    onProgress,
                  );
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      throw Exception('Instagram video URL bulunamadı');
    } catch (e) {
      _debugPrint('Instagram gelişmiş çıkarma hatası: $e');
      throw e;
    }
  }

  // 🎵 TikTok Gelişmiş Çıkarma
  static Future<Map<String, dynamic>> _extractTikTokAdvanced(
      String url, String? fileName, Function(double)? onProgress) async {
    try {
      _debugPrint('🎵 TikTok gelişmiş URL çıkarma...');

      // TikTok alternatif URL'leri
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
            },
          ).timeout(Duration(seconds: 10));

          if (response.statusCode == 200) {
            final body = response.body;

            // Gelişmiş TikTok pattern'ları
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
                    .replaceAll(r'\u002F', '/');

                if (videoUrl.startsWith('http') &&
                    (videoUrl.contains('.mp4') || videoUrl.contains('video'))) {
                  return await _downloadRealVideoFile(
                    videoUrl,
                    fileName ??
                        'tiktok_${DateTime.now().millisecondsSinceEpoch}.mp4',
                    onProgress,
                  );
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      throw Exception('TikTok video URL bulunamadı');
    } catch (e) {
      _debugPrint('TikTok gelişmiş çıkarma hatası: $e');
      throw e;
    }
  }

  // 🐦 Twitter Gelişmiş Çıkarma
  static Future<Map<String, dynamic>> _extractTwitterAdvanced(
      String url, String? fileName, Function(double)? onProgress) async {
    try {
      _debugPrint('🐦 Twitter gelişmiş URL çıkarma...');

      // Twitter alternatif URL'leri
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
          ).timeout(Duration(seconds: 10));

          if (response.statusCode == 200) {
            final body = response.body;

            // Gelişmiş Twitter pattern'ları
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
                  return await _downloadRealVideoFile(
                    videoUrl,
                    fileName ??
                        'twitter_${DateTime.now().millisecondsSinceEpoch}.mp4',
                    onProgress,
                  );
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      throw Exception('Twitter video URL bulunamadı');
    } catch (e) {
      _debugPrint('Twitter gelişmiş çıkarma hatası: $e');
      throw e;
    }
  }

  // 🕷️ STRATEJİ 3: Derin Web Scraping
  static Future<Map<String, dynamic>> _strategyDeepScraping(
      String url, String? fileName, Function(double)? onProgress) async {
    _debugPrint('🕷️ Strateji 3: Derin web scraping');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body;

        // Tüm olası video URL pattern'ları
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
            if (videoUrl.length > 20 && videoUrl.contains('.mp4')) {
              foundUrls.add(videoUrl);
            }
          }
        }

        // Bulunan URL'leri dene
        for (final videoUrl in foundUrls) {
          try {
            final result = await _downloadRealVideoFile(
              videoUrl,
              fileName ??
                  'scraped_${DateTime.now().millisecondsSinceEpoch}.mp4',
              onProgress,
            );
            if (result['success'] == true) {
              return result;
            }
          } catch (e) {
            continue;
          }
        }
      }

      throw Exception('Derin scraping ile video bulunamadı');
    } catch (e) {
      _debugPrint('Derin scraping hatası: $e');
      throw e;
    }
  }

  // 🌐 STRATEJİ 4: Alternatif API'ler
  static Future<Map<String, dynamic>> _strategyAlternativeAPIs(
      String url, String? fileName, Function(double)? onProgress) async {
    _debugPrint('🌐 Strateji 4: Alternatif API\'ler');

    // Çoklu API dene
    final apis = [
      'https://api.savethe.video/api/ajaxSearch',
      'https://api.downloadgram.com/media',
      'https://api.snapinsta.app/video',
    ];

    for (final apiUrl in apis) {
      try {
        final response = await http
            .post(
              Uri.parse(apiUrl),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
              body: 'url=${Uri.encodeComponent(url)}',
            )
            .timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = response.body;

          // API response'dan video URL çıkar
          final videoMatch =
              RegExp(r'http[s]?://[^\s"<>]+\.mp4[^\s"<>]*').firstMatch(body);
          if (videoMatch != null) {
            final videoUrl = videoMatch.group(0)!;
            return await _downloadRealVideoFile(
              videoUrl,
              fileName ?? 'api_${DateTime.now().millisecondsSinceEpoch}.mp4',
              onProgress,
            );
          }
        }
      } catch (e) {
        continue;
      }
    }

    throw Exception('Alternatif API\'ler başarısız');
  }

  // 💪 STRATEJİ 5: Zorla İndirme
  static Future<Map<String, dynamic>> _strategyForcedDownload(
      String url, String? fileName, Function(double)? onProgress) async {
    _debugPrint('💪 Strateji 5: Zorla indirme - Son çare!');

    // URL'yi olduğu gibi indirmeyi dene
    try {
      return await _downloadRealVideoFile(
        url,
        fileName ?? 'forced_${DateTime.now().millisecondsSinceEpoch}.mp4',
        onProgress,
      );
    } catch (e) {
      _debugPrint('Zorla indirme hatası: $e');
    }

    throw Exception('Zorla indirme bile başarısız');
  }

  // 📥 GERÇEK VİDEO DOSYASI İNDİRME
  static Future<Map<String, dynamic>> _downloadRealVideoFile(
    String videoUrl,
    String fileName,
    Function(double)? onProgress,
  ) async {
    try {
      _debugPrint('📥 Gerçek video dosyası indiriliyor: $videoUrl');

      final downloadDir = await getDownloadDirectory();
      final cleanFileName = _sanitizeFileName(fileName);
      final filePath = '${downloadDir.path}/$cleanFileName';

      // Eğer dosya zaten varsa yeni isim ver
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

      // Video indirme için özel header'lar
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'video/mp4,video/*,*/*;q=0.9',
        'Accept-Encoding': 'identity',
        'Referer': videoUrl.contains('youtube')
            ? 'https://www.youtube.com/'
            : videoUrl.contains('instagram')
                ? 'https://www.instagram.com/'
                : videoUrl.contains('tiktok')
                    ? 'https://www.tiktok.com/'
                    : videoUrl.contains('twitter')
                        ? 'https://twitter.com/'
                        : '',
        'Range': 'bytes=0-',
      };

      final request = http.Request('GET', Uri.parse(videoUrl));
      request.headers.addAll(headers);

      final response = await request.send().timeout(Duration(seconds: 60));

      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.contentLength ?? 0;
        int downloaded = 0;

        // İlk chunk'ı kontrol et - HTML mı video mu?
        bool isFirstChunk = true;
        List<int> firstChunkData = [];

        final sink = finalFile.openWrite();

        await response.stream.listen(
          (List<int> chunk) {
            // İlk chunk'ı analiz et
            if (isFirstChunk) {
              firstChunkData = chunk;
              isFirstChunk = false;

              // HTML kontrolü
              final chunkString = String.fromCharCodes(chunk.take(200));
              if (chunkString.toLowerCase().contains('<html') ||
                  chunkString.toLowerCase().contains('<!doctype') ||
                  chunkString.toLowerCase().contains('<head>') ||
                  chunkString.toLowerCase().contains('<body>')) {
                _debugPrint('❌ HTML içeriği tespit edildi, video değil!');
                throw Exception('İndirilen içerik HTML sayfası, video değil');
              }

              // Video format kontrolü
              if (!_isValidVideoFormat(chunk)) {
                _debugPrint('❌ Geçersiz video formatı tespit edildi!');
                throw Exception(
                    'İndirilen içerik geçerli video formatında değil');
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

        // Dosya boyutunu kontrol et
        final fileSize = await finalFile.length();
        if (fileSize > 10240) {
          // En az 10KB olmalı

          // Son kontrol: Dosya içeriğini tekrar kontrol et
          final fileBytes = await finalFile.readAsBytes();
          if (!_isValidVideoFile(fileBytes)) {
            await finalFile.delete();
            throw Exception('İndirilen dosya geçerli video formatında değil');
          }

          _debugPrint(
              '✅ Gerçek video indirme başarılı: $finalPath (${fileSize} bytes)');

          return {
            'success': true,
            'file_path': finalPath,
            'file_size': fileSize,
            'file_name': finalPath.split('/').last,
          };
        } else {
          await finalFile.delete();
          throw Exception('Dosya çok küçük, gerçek video değil');
        }
      } else {
        throw Exception('HTTP ${response.statusCode} hatası');
      }
    } catch (e) {
      _debugPrint('❌ Gerçek video indirme hatası: $e');
      return {
        'success': false,
        'error': 'Video indirme hatası: $e',
      };
    }
  }

  // 🔍 Video format kontrolü - İlk bytes'ları kontrol et
  static bool _isValidVideoFormat(List<int> bytes) {
    if (bytes.length < 12) return false;

    // MP4 magic numbers
    final mp4Signatures = [
      [0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70], // ftyp
      [0x00, 0x00, 0x00, 0x1c, 0x66, 0x74, 0x79, 0x70], // ftyp
      [0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70], // ftyp
    ];

    // WebM magic numbers
    final webmSignature = [0x1a, 0x45, 0xdf, 0xa3];

    // AVI magic numbers
    final aviSignature = [0x52, 0x49, 0x46, 0x46]; // RIFF

    // MOV magic numbers (QuickTime)
    final movSignatures = [
      [0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70, 0x71, 0x74], // qt
    ];

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

    // MOV kontrol
    for (final signature in movSignatures) {
      if (_matchesSignature(bytes, signature, 0)) {
        return true;
      }
    }

    return false;
  }

  // 📄 Tam dosya kontrolü
  static bool _isValidVideoFile(List<int> bytes) {
    if (bytes.length < 100) return false;

    // HTML kontrolü
    final beginning = String.fromCharCodes(bytes.take(500));
    if (beginning.toLowerCase().contains('<html') ||
        beginning.toLowerCase().contains('<!doctype') ||
        beginning.toLowerCase().contains('<head>') ||
        beginning.toLowerCase().contains('<body>') ||
        beginning.toLowerCase().contains('text/html')) {
      return false;
    }

    // Video format kontrolü
    return _isValidVideoFormat(bytes);
  }

  // 🔍 Signature eşleştirme
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

  // Yardımcı fonksiyonlar
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

  static String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\-_\.]'), '_')
        .toLowerCase()
        .substring(0, fileName.length > 100 ? 100 : fileName.length);
  }

  static void _debugPrint(String message) {
    if (_isDebugMode) {
      print('🎬 SÜPER GÜÇLÜ VİDEO DOWNLOAD: $message');
    }
  }

  // 📊 İndirme geçmişi
  static Future<List<Map<String, dynamic>>> getDownloadHistory() async {
    try {
      final downloadDir = await getDownloadDirectory();
      final files = downloadDir.listSync();

      List<Map<String, dynamic>> history = [];

      for (final file in files) {
        if (file is File && !file.path.endsWith('.txt')) {
          final stat = await file.stat();
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

      return history;
    } catch (e) {
      _debugPrint('İndirme geçmişi hatası: $e');
      return [];
    }
  }

  // 🗑️ İndirilen dosyayı sil
  static Future<bool> deleteDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      _debugPrint('Dosya silme hatası: $e');
      return false;
    }
  }
}
