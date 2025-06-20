// Dosya Konumu: lib/utils/url_utils.dart

class UrlUtils {
  // Instagram URL'sini embed formatına çevir
  static String convertToEmbedUrl(String instagramUrl) {
    try {
      // Instagram URL formatları:
      // https://www.instagram.com/p/ABC123/
      // https://www.instagram.com/reel/XYZ789/
      // https://www.instagram.com/tv/DEF456/

      Uri uri = Uri.parse(instagramUrl);

      // Post ID'sini çıkar
      RegExp regExp = RegExp(r'/(p|reel|tv)/([A-Za-z0-9_-]+)');
      Match? match = regExp.firstMatch(uri.path);

      if (match != null) {
        String postId = match.group(2)!;
        // Embed URL formatı
        return 'https://www.instagram.com/p/$postId/embed/';
      }

      return instagramUrl;
    } catch (e) {
      return instagramUrl;
    }
  }

  // Thumbnail URL'si oluştur (Instagram özel)
  static String getThumbnailUrl(String instagramUrl) {
    try {
      Uri uri = Uri.parse(instagramUrl);
      RegExp regExp = RegExp(r'/(p|reel|tv)/([A-Za-z0-9_-]+)');
      Match? match = regExp.firstMatch(uri.path);

      if (match != null) {
        String postId = match.group(2)!;
        // Instagram thumbnail için basit bir yaklaşım
        return 'https://www.instagram.com/p/$postId/media/?size=m';
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  // URL'nin geçerli Instagram linki olup olmadığını kontrol et
  static bool isValidInstagramUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      return uri.host.contains('instagram.com') &&
          (uri.path.contains('/p/') ||
              uri.path.contains('/reel/') ||
              uri.path.contains('/tv/'));
    } catch (e) {
      return false;
    }
  }

  // Instagram post ID'sini çıkar
  static String? extractPostId(String instagramUrl) {
    try {
      Uri uri = Uri.parse(instagramUrl);
      RegExp regExp = RegExp(r'/(p|reel|tv)/([A-Za-z0-9_-]+)');
      Match? match = regExp.firstMatch(uri.path);
      return match?.group(2);
    } catch (e) {
      return null;
    }
  }

  // Instagram post tipini belirle
  static String getPostType(String instagramUrl) {
    try {
      Uri uri = Uri.parse(instagramUrl);
      if (uri.path.contains('/reel/')) return 'Reel';
      if (uri.path.contains('/tv/')) return 'IGTV';
      if (uri.path.contains('/p/')) return 'Post';
      return 'Video';
    } catch (e) {
      return 'Video';
    }
  }

  // URL'yi temizle (tracking parametrelerini kaldır)
  static String cleanUrl(String url) {
    try {
      Uri uri = Uri.parse(url);

      // Sadece temel parametreleri koru
      Map<String, String> cleanParams = {};

      // Instagram için önemli parametreler varsa koru
      if (uri.queryParameters.containsKey('igshid')) {
        cleanParams['igshid'] = uri.queryParameters['igshid']!;
      }

      return Uri(
        scheme: uri.scheme,
        host: uri.host,
        path: uri.path,
        queryParameters: cleanParams.isEmpty ? null : cleanParams,
      ).toString();
    } catch (e) {
      return url;
    }
  }

  // URL'yi kısalt (görüntüleme için)
  static String shortenUrl(String url, {int maxLength = 50}) {
    if (url.length <= maxLength) return url;

    try {
      Uri uri = Uri.parse(url);
      String postId = extractPostId(url) ?? '';

      if (postId.isNotEmpty) {
        return 'instagram.com/.../${postId.substring(0, 8)}...';
      }

      return url.substring(0, maxLength - 3) + '...';
    } catch (e) {
      return url.substring(0, maxLength - 3) + '...';
    }
  }
}