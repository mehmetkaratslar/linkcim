// Dosya Konumu: lib/widgets/video_thumbnail.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linkcim/utils/url_utils.dart';

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
    final thumbnailUrl =
        customThumbnailUrl ?? UrlUtils.getThumbnailUrl(videoUrl);
    final postType = UrlUtils.getPostType(videoUrl);

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
              // Thumbnail image
              _buildThumbnailImage(thumbnailUrl),

              // Play button overlay
              if (showPlayButton) _buildPlayButtonOverlay(),

              // Post type badge
              _buildPostTypeBadge(postType),

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

  Widget _buildThumbnailImage(String thumbnailUrl) {
    if (thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
        fadeInDuration: Duration(milliseconds: 300),
        fadeOutDuration: Duration(milliseconds: 300),
      );
    } else {
      return _buildPlaceholder();
    }
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
