// Dosya Konumu: lib/widgets/video_thumbnail.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linkcim/utils/url_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoThumbnail extends StatelessWidget {
  final String videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;
  final bool showPlayButton;
  final String? customThumbnailUrl;

  const VideoThumbnail({
    Key? key,
    required this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.onTap,
    this.showPlayButton = true,
    this.customThumbnailUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail image - backend'den al
              _buildSmartThumbnailImage(),

              // Play button overlay
              if (showPlayButton) _buildPlayButtonOverlay(),

              // Post type badge
              _buildPostTypeBadge(UrlUtils.getPostType(videoUrl)),

              // Gradient overlay for better text visibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartThumbnailImage() {
    final platform = _getPlatformFromUrl(videoUrl);

    // Önce custom thumbnail varsa onu kullan
    if (customThumbnailUrl != null && customThumbnailUrl!.isNotEmpty) {
      return _buildCachedImage(customThumbnailUrl!, platform);
    }

    // YouTube için direkt URL kullan
    if (platform == 'youtube') {
      final directUrl = UrlUtils.getThumbnailUrl(videoUrl);
      if (directUrl.isNotEmpty) {
        return _buildCachedImage(directUrl, platform);
      }
    }

    // Diğer platformlar için backend'den al
    return FutureBuilder<String?>(
      future: _getBackendThumbnail(videoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPlaceholder(platform);
        }

        if (snapshot.hasData && snapshot.data != null) {
          return _buildCachedImage(snapshot.data!, platform);
        }

        // Hata durumunda platform placeholder
        return _buildPlatformPlaceholder(platform);
      },
    );
  }

  Widget _buildCachedImage(String imageUrl, String platform) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, url) => _buildLoadingPlaceholder(platform),
      errorWidget: (context, url, error) {
        print('❌ Thumbnail yüklenemedi: $imageUrl');
        return _buildPlatformPlaceholder(platform);
      },
      fadeInDuration: Duration(milliseconds: 300),
      fadeOutDuration: Duration(milliseconds: 300),
      httpHeaders: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
    );
  }

  Future<String?> _getBackendThumbnail(String videoUrl) async {
    try {
      final encodedUrl = Uri.encodeComponent(videoUrl);
      final response = await http.get(
        Uri.parse(
            'https://linkcim-production.up.railway.app/api/thumbnail?url=$encodedUrl'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['thumbnail_url'] != null) {
          print('✅ Backend thumbnail alındı: ${data['thumbnail_url']}');
          return data['thumbnail_url'];
        }
      }

      print('❌ Backend thumbnail alınamadı: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Backend thumbnail hatası: $e');
      return null;
    }
  }

  Widget _buildThumbnailImage(String thumbnailUrl) {
    final platform = _getPlatformFromUrl(videoUrl);

    if (thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: fit,
        placeholder: (context, url) => _buildLoadingPlaceholder(platform),
        errorWidget: (context, url, error) {
          print('❌ Thumbnail yüklenemedi: $thumbnailUrl');
          return _buildPlatformPlaceholder(platform);
        },
        fadeInDuration: Duration(milliseconds: 300),
        fadeOutDuration: Duration(milliseconds: 300),
        httpHeaders: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
      );
    } else {
      return _buildPlatformPlaceholder(platform);
    }
  }

  Widget _buildLoadingPlaceholder(String platform) {
    final platformColor = _getPlatformColor(platform);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            platformColor.withOpacity(0.1),
            platformColor.withOpacity(0.05)
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: platformColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Yükleniyor...',
            style: TextStyle(
              color: platformColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'instagram':
        return Colors.purple;
      case 'youtube':
        return Colors.red;
      case 'tiktok':
        return Colors.black;
      case 'twitter':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPlatformFromUrl(String url) {
    if (url.contains('instagram.com')) return 'instagram';
    if (url.contains('youtube.com') || url.contains('youtu.be'))
      return 'youtube';
    if (url.contains('tiktok.com')) return 'tiktok';
    if (url.contains('twitter.com') || url.contains('x.com')) return 'twitter';
    return 'unknown';
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library,
            size: 32,
            color: Colors.grey[600],
          ),
          SizedBox(height: 6),
          Flexible(
            child: Text(
              'Önizleme\nYükleniyor...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformPlaceholder(String platform) {
    Color platformColor;
    IconData platformIcon;
    String platformName;

    switch (platform) {
      case 'instagram':
        platformColor = Colors.purple;
        platformIcon = Icons.camera_alt;
        platformName = 'Instagram';
        break;
      case 'youtube':
        platformColor = Colors.red;
        platformIcon = Icons.play_circle_filled;
        platformName = 'YouTube';
        break;
      case 'tiktok':
        platformColor = Colors.black;
        platformIcon = Icons.music_video;
        platformName = 'TikTok';
        break;
      case 'twitter':
        platformColor = Colors.blue;
        platformIcon = Icons.video_camera_back;
        platformName = 'Twitter';
        break;
      default:
        platformColor = Colors.grey;
        platformIcon = Icons.video_library;
        platformName = 'Video';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            platformColor.withOpacity(0.1),
            platformColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: platformColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              platformIcon,
              size: 24,
              color: platformColor,
            ),
          ),
          SizedBox(height: 8),
          Flexible(
            child: Text(
              platformName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: platformColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[400],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image,
            size: 32,
            color: Colors.grey[700],
          ),
          SizedBox(height: 6),
          Flexible(
            child: Text(
              'Önizleme\nUlaşılamıyor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButtonOverlay() {
    return Center(
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildPostTypeBadge(String postType) {
    Color badgeColor;
    IconData badgeIcon;

    switch (postType.toLowerCase()) {
      case 'reel':
        badgeColor = Colors.purple;
        badgeIcon = Icons.videocam;
        break;
      case 'igtv':
        badgeColor = Colors.orange;
        badgeIcon = Icons.tv;
        break;
      case 'post':
        badgeColor = Colors.blue;
        badgeIcon = Icons.photo;
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.video_library;
    }

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badgeIcon,
              color: Colors.white,
              size: 12,
            ),
            SizedBox(width: 2),
            Text(
              postType,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Küçük thumbnail widget'ı (liste görünümü için)
class SmallVideoThumbnail extends StatelessWidget {
  final String videoUrl;
  final VoidCallback? onTap;

  const SmallVideoThumbnail({
    Key? key,
    required this.videoUrl,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VideoThumbnail(
      videoUrl: videoUrl,
      width: 60,
      height: 60,
      onTap: onTap,
      showPlayButton: false,
    );
  }
}

// Büyük thumbnail widget'ı (önizleme için)
class LargeVideoThumbnail extends StatelessWidget {
  final String videoUrl;
  final VoidCallback? onTap;
  final String? customThumbnailUrl;

  const LargeVideoThumbnail({
    Key? key,
    required this.videoUrl,
    this.onTap,
    this.customThumbnailUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VideoThumbnail(
      videoUrl: videoUrl,
      height: 200,
      onTap: onTap,
      showPlayButton: true,
      customThumbnailUrl: customThumbnailUrl,
    );
  }
}
