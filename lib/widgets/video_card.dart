// Dosya Konumu: lib/widgets/video_card.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/widgets/tag_chip.dart';
import 'package:linkcim/widgets/video_thumbnail.dart';
import 'package:linkcim/widgets/share_menu.dart';
import 'package:linkcim/widgets/download_progress_dialog.dart';
import 'package:linkcim/screens/video_preview_screen.dart';
import 'package:linkcim/screens/video_player_screen.dart';
import 'package:linkcim/screens/add_video_screen.dart';
import 'package:linkcim/services/video_download_service.dart';
import 'package:linkcim/utils/constants.dart';

class VideoCard extends StatelessWidget {
  final SavedVideo video;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final String? highlightText;

  const VideoCard({
    Key? key,
    required this.video,
    this.onDelete,
    this.onTap,
    this.highlightText,
  }) : super(key: key);

  // Video indirme
  Future<void> _downloadVideo(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video İndir'),
        content: Text('${video.title} videosunu indirmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('İndir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DownloadProgressDialog(video: video),
      );
    }
  }

  // Video açma
  Future<void> _openVideo() async {
    try {
      final uri = Uri.parse(video.videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Hata gösterme
    }
  }

  // Önizleme açma
  void _openPreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewScreen(video: video),
      ),
    );
  }

  // Platform ikonu ve rengi
  Widget _buildPlatformChip() {
    Color platformColor;
    switch (video.platform.toLowerCase()) {
      case 'instagram':
        platformColor = Colors.purple;
        break;
      case 'youtube':
        platformColor = Colors.red;
        break;
      case 'tiktok':
        platformColor = Colors.black;
        break;
      case 'twitter':
        platformColor = Colors.blue;
        break;
      default:
        platformColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: platformColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: platformColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(video.platformIcon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            video.platform.toUpperCase(),
            style: TextStyle(
              color: platformColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openPreview(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım: Thumbnail + Bilgiler + İndir butonu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video thumbnail - Daha büyük ve gerçek kapak
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 120,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: VideoThumbnail(
                        videoUrl: video.videoUrl,
                        width: 120,
                        height: 90,
                        fit: BoxFit.cover,
                        onTap: () => _openPreview(context),
                        showPlayButton: true,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Video bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık
                        Text(
                          video.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // Platform chip
                        _buildPlatformChip(),

                        const SizedBox(height: 4),

                        // Yazar ve tarih
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                video.authorDisplay,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              video.formattedDate,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // İndir butonu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _downloadVideo(context),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Açıklama (varsa)
              if (video.description.isNotEmpty) ...[
                Text(
                  video.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Etiketler (varsa)
              if (video.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: video.tags
                      .take(3)
                      .map((tag) => TagChip(
                            tag: tag,
                            size: TagChipSize.small,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],

              // Alt butonlar
              Row(
                children: [
                  // Önizleme
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openPreview(context),
                      icon: const Icon(Icons.preview, size: 16),
                      label: const Text('Önizleme'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Platform'da aç
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openVideo,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Aç'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Menü
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddVideoScreen(video: video),
                            ),
                          ).then((result) {
                            if (result == true && onTap != null) onTap!();
                          });
                          break;
                        case 'share':
                          ShareMenu.show(context, video);
                          break;
                        case 'delete':
                          if (onDelete != null) onDelete!();
                          break;
                      }
                    },
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 16),
                            SizedBox(width: 8),
                            Text('Paylaş'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
