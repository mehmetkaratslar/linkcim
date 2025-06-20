// Dosya Konumu: lib/services/instagram_service.dart

import 'package:dio/dio.dart';
import 'package:linkcim/utils/url_utils.dart';

class InstagramService {
  static final Dio _dio = Dio();

  // Instagram meta bilgilerini al (basit scraping)
  static Future<Map<String, dynamic>> getVideoMetadata(String url) async {
    try {
      // Instagram'ın embed endpoint'ini kullan
      final embedUrl = UrlUtils.convertToEmbedUrl(url);

      final response = await _dio.get(
        embedUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      if (response.statusCode == 200) {
        final html = response.data.toString();

        // HTML'den meta bilgileri çıkar
        final title = _extractMetaContent(html, 'og:title') ??
            _extractMetaContent(html, 'twitter:title') ??
            'Instagram Video';

        final description = _extractMetaContent(html, 'og:description') ??
            _extractMetaContent(html, 'twitter:description') ??
            '';

        final thumbnail = _extractMetaContent(html, 'og:image') ??
            _extractMetaContent(html, 'twitter:image') ??
            '';

        final author = _extractMetaContent(html, 'og:site_name') ?? 'Instagram';

        return {
          'success': true,
          'title': _cleanText(title),
          'description': _cleanText(description),
          'thumbnail': thumbnail,
          'author': author,
          'postType': UrlUtils.getPostType(url),
          'postId': UrlUtils.extractPostId(url),
        };
      }
    } catch (e) {
      print('Instagram metadata hatası: $e');
    }

    // Hata durumunda basit bilgi döndür
    return {
      'success': false,
      'title': 'Instagram ${UrlUtils.getPostType(url)}',
      'description': 'Video açıklaması alınamadı',
      'thumbnail': '',
      'author': 'Instagram',
      'postType': UrlUtils.getPostType(url),
      'postId': UrlUtils.extractPostId(url),
    };
  }

  // HTML'den meta content çıkar
  static String? _extractMetaContent(String html, String property) {
    try {
      // og:title, twitter:title vb. için
      RegExp regExp = RegExp(
        '<meta[^>]*(?:property|name)=["\']${RegExp.escape(property)}["\'][^>]*content=["\']([^"\']*)["\']',
        caseSensitive: false,
      );

      Match? match = regExp.firstMatch(html);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  // Metni temizle
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML taglarını kaldır
        .replaceAll(RegExp(r'\s+'), ' ') // Fazla boşlukları kaldır
        .trim();
  }

  // Instagram oEmbed API kullan (alternatif)
  static Future<Map<String, dynamic>> getOEmbedData(String url) async {
    try {
      final oembedUrl =
          'https://api.instagram.com/oembed/?url=${Uri.encodeComponent(url)}';

      final response = await _dio.get(oembedUrl);

      if (response.statusCode == 200) {
        final data = response.data;

        return {
          'success': true,
          'title': data['title'] ?? 'Instagram Video',
          'author': data['author_name'] ?? 'Instagram',
          'thumbnail': data['thumbnail_url'] ?? '',
          'width': data['thumbnail_width'] ?? 0,
          'height': data['thumbnail_height'] ?? 0,
          'html': data['html'] ?? '',
        };
      }
    } catch (e) {
      print('Instagram oEmbed hatası: $e');
    }

    return {'success': false};
  }

  // Video indirilebilir mi kontrol et
  static Future<bool> isVideoAccessible(String url) async {
    try {
      final response = await _dio.head(
        url,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Instagram post bilgilerini zenginleştir
  static Map<String, dynamic> enrichVideoData(String url, String title) {
    final postId = UrlUtils.extractPostId(url);
    final postType = UrlUtils.getPostType(url);
    final cleanUrl = UrlUtils.cleanUrl(url);

    return {
      'originalUrl': url,
      'cleanUrl': cleanUrl,
      'embedUrl': UrlUtils.convertToEmbedUrl(url),
      'postId': postId,
      'postType': postType,
      'shortUrl': UrlUtils.shortenUrl(url),
      'estimatedThumbnail': UrlUtils.getThumbnailUrl(url),
    };
  }
}
