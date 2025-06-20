// Dosya Konumu: lib/widgets/video_card.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/widgets/tag_chip.dart';
import 'package:linkcim/widgets/video_thumbnail.dart';
import 'package:linkcim/widgets/share_menu.dart';
import 'package:linkcim/screens/video_preview_screen.dart';
import 'package:linkcim/screens/video_player_screen.dart';
import 'package:linkcim/services/video_download_service.dart';
import 'package:linkcim/widgets/download_progress_dialog.dart';

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

  Future<void> _openVideo() async {
    try {
      final uri = Uri.parse(video.videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Video açılamadı';
      }
    } catch (e) {
      print('Video açma hatası: $e');
    }
  }

  void _openPreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewScreen(video: video),
      ),
    );
  }

  void _openPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(video: video),
      ),
    );
  }

  Future<void> _downloadVideo(BuildContext context) async {
    // İndirme onay dialogu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: Colors.green),
            SizedBox(width: 8),
            Text('Video İndir'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bu video indirilecek:'),
            SizedBox(height: 8),
            Text(
              video.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Platform: ${video.platform.toUpperCase()}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Uyarı',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Videoları sadece kişisel kullanım için indirin. Telif hakları saklıdır.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icon(Icons.download),
            label: Text('İndir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        video: video,
      ),
    );
  }

  Widget _buildHighlightedText(
      BuildContext context, String text, String? highlight) {
    if (highlight == null || highlight.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();

    if (!lowerText.contains(lowerHighlight)) {
      return Text(text);
    }

    final index = lowerText.indexOf(lowerHighlight);
    final beforeMatch = text.substring(0, index);
    final match = text.substring(index, index + highlight.length);
    final afterMatch = text.substring(index + highlight.length);

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: beforeMatch),
          TextSpan(
            text: match,
            style: TextStyle(
              backgroundColor: Colors.yellow[200],
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: afterMatch),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _openPreview(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail ve başlık
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video thumbnail
                  SmallVideoThumbnail(
                    videoUrl: video.videoUrl,
                    onTap: () => _openPreview(context),
                  ),

                  SizedBox(width: 12),

                  // Video bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHighlightedText(
                          context,
                          video.title,
                          highlightText,
                        ),
                        SizedBox(height: 4),

                        // Platform ve yazar bilgisi
                        Row(
                          children: [
                            Text(
                              video.platformIcon,
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(width: 4),
                            Text(
                              video.platform.toUpperCase(),
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                video.authorDisplay,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              video.category,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              video.formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Aksiyon butonları
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // İndirme butonu (yeşil, belirgin)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.download,
                              color: Colors.white, size: 20),
                          onPressed: () => _downloadVideo(context),
                          tooltip: 'Video İndir',
                          constraints:
                              BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                      SizedBox(height: 4),
                      // Menü butonu
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'preview':
                              _openPreview(context);
                              break;
                            case 'play':
                              _openPlayer(context);
                              break;
                            case 'edit':
                              if (onTap != null) onTap!();
                              break;
                            case 'share':
                              ShareMenu.show(context, video);
                              break;
                            case 'instagram':
                              _openVideo();
                              break;
                            case 'download':
                              _downloadVideo(context);
                              break;
                            case 'delete':
                              if (onDelete != null) onDelete!();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'preview',
                            child: Row(
                              children: [
                                Icon(Icons.preview, size: 18),
                                SizedBox(width: 8),
                                Text('Önizleme'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'play',
                            child: Row(
                              children: [
                                Icon(Icons.play_circle, size: 18),
                                SizedBox(width: 8),
                                Text('Uygulamada Oynat'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'instagram',
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new, size: 18),
                                SizedBox(width: 8),
                                Text('Instagram\'da Aç'),
                              ],
                            ),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, size: 18),
                                SizedBox(width: 8),
                                Text('Paylaş'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Düzenle'),
                              ],
                            ),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.download,
                                    size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text('İndir',
                                    style: TextStyle(color: Colors.green)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Sil',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Açıklama
              if (video.description.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _buildHighlightedText(
                    context,
                    video.description,
                    highlightText,
                  ),
                ),

              // Etiketler
              if (video.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: video.tags.map((tag) {
                    final isHighlighted = highlightText != null &&
                        highlightText!.isNotEmpty &&
                        tag
                            .toLowerCase()
                            .contains(highlightText!.toLowerCase());

                    return TagChip(
                      tag: tag,
                      size: TagChipSize.small,
                      highlighted: isHighlighted,
                    );
                  }).toList(),
                ),

              SizedBox(height: 12),

              // Alt butonlar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openPreview(context),
                      icon: Icon(Icons.preview, size: 18),
                      label: Text('Önizleme'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openPlayer(context),
                      icon: Icon(Icons.play_arrow, size: 18),
                      label: Text('Oynat'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => ShareMenu.show(context, video),
                    icon: Icon(Icons.share, size: 20),
                    tooltip: 'Paylaş',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
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
