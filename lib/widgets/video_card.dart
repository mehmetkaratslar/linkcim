// Dosya Konumu: lib/widgets/video_card.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/widgets/tag_chip.dart';
import 'package:linkcim/widgets/video_thumbnail.dart';
import 'package:linkcim/widgets/share_menu.dart';
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

  void _editVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVideoScreen(video: video),
      ),
    ).then((result) {
      if (result == true && onTap != null) {
        onTap!(); // Refresh callback
      }
    });
  }

  // 🚀 YENİ SÜPER GÜÇLÜ VİDEO İNDİRME
  Future<void> _downloadVideoSuper(BuildContext context) async {
    // İndirme onay dialogu
    final downloadType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.rocket_launch, color: Colors.green[600], size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Süper Güçlü Video İndirme',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video bilgisi
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(video.platformIcon, style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        video.platform.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    video.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // İndirme seçenekleri
            Text(
              'İndirme Türü Seçin:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),

            // Normal indirme
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.download, color: Colors.blue[700]),
              ),
              title: Text('Normal İndirme'),
              subtitle: Text('Standart kalite, güvenilir yöntem'),
              onTap: () => Navigator.of(context).pop('normal'),
            ),

            // Hızlı indirme
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flash_on, color: Colors.orange[700]),
              ),
              title: Text('Hızlı İndirme'),
              subtitle: Text('Optimized for speed'),
              onTap: () => Navigator.of(context).pop('fast'),
            ),

            // Mobil optimize
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.phone_android, color: Colors.green[700]),
              ),
              title: Text('Mobil Optimize'),
              subtitle: Text('Mobil cihazlar için optimize edilmiş'),
              onTap: () => Navigator.of(context).pop('mobile'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal'),
          ),
        ],
      ),
    );

    if (downloadType == null) return;

    // İndirme işlemini başlat
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuperDownloadProgressDialog(
        video: video,
        downloadType: downloadType,
      ),
    );
  }

  // Test URL fonksiyonu
  Future<void> _testVideoUrl(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('URL Test Ediliyor...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Video URL\'si analiz ediliyor...'),
          ],
        ),
      ),
    );

    final testResult = await VideoDownloadService.testVideoUrl(video.videoUrl);

    Navigator.of(context).pop(); // Close loading dialog

    // Test sonucunu göster
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              testResult['success'] ? Icons.check_circle : Icons.error,
              color: testResult['success'] ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text('URL Test Sonucu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestResultRow('Platform:', testResult['platform']),
            _buildTestResultRow('URL Durumu:', testResult['success'] ? 'Başarılı' : 'Başarısız'),
            if (testResult['video_url'] != null)
              _buildTestResultRow('Video URL:', 'Bulundu ✓'),
            if (testResult['is_valid'] != null)
              _buildTestResultRow('Geçerlilik:', testResult['is_valid'] ? 'Geçerli ✓' : 'Geçersiz ✗'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: testResult['success'] ? Colors.green[50] : Colors.red[50],
                border: Border.all(
                  color: testResult['success'] ? Colors.green[200]! : Colors.red[200]!,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                testResult['message'] ?? 'Test tamamlandı',
                style: TextStyle(
                  fontSize: 12,
                  color: testResult['success'] ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam'),
          ),
          if (testResult['success'])
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadVideoSuper(context);
              },
              child: Text('İndir'),
            ),
        ],
      ),
    );
  }

  Widget _buildTestResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context, String text, String? highlight) {
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

  String _getPlatformActionText() {
    switch (video.platform.toLowerCase()) {
      case 'instagram':
        return 'Instagram\'da Aç';
      case 'youtube':
        return 'YouTube\'de Aç';
      case 'tiktok':
        return 'TikTok\'ta Aç';
      case 'twitter':
        return 'Twitter\'da Aç';
      default:
        return 'Platformda Aç';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openPreview(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım - Thumbnail ve video bilgileri
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
                        // Başlık
                        _buildHighlightedText(
                          context,
                          video.title,
                          highlightText,
                        ),
                        SizedBox(height: 6),

                        // Platform ve yazar bilgisi
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(AppConstants.getPlatformColor(
                                    video.platform))
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(AppConstants.getPlatformColor(
                                      video.platform))
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    video.platformIcon,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    video.platform.toUpperCase(),
                                    style: TextStyle(
                                      color: Color(
                                          AppConstants.getPlatformColor(
                                              video.platform)),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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

                        // Kategori ve tarih
                        Row(
                          children: [
                            Icon(Icons.category,
                                size: 14, color: Colors.grey[600]),
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
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[600]),
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

                  // Süper indirme butonu (büyük ve belirgin)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _downloadVideoSuper(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rocket_launch,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'SÜPER\nİNDİR',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Açıklama
              if (video.description.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: _buildHighlightedText(
                    context,
                    video.description,
                    highlightText,
                  ),
                ),
                SizedBox(height: 12),
              ],

              // Etiketler
              if (video.tags.isNotEmpty) ...[
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
              ],

              // Alt kısım - Action butonları
              Row(
                children: [
                  // Önizleme butonu
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => _openPreview(context),
                      icon: Icon(Icons.preview, size: 18),
                      label: Text('Önizleme'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8),

                  // Oynat butonu
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _openPlayer(context),
                      icon: Icon(Icons.play_arrow, size: 18),
                      label: Text('Oynat'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8),

                  // Menü butonu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'preview':
                            _openPreview(context);
                            break;
                          case 'play':
                            _openPlayer(context);
                            break;
                          case 'edit':
                            _editVideo(context);
                            break;
                          case 'share':
                            ShareMenu.show(context, video);
                            break;
                          case 'platform':
                            _openVideo();
                            break;
                          case 'download':
                            _downloadVideoSuper(context);
                            break;
                          case 'test_url':
                            _testVideoUrl(context);
                            break;
                          case 'delete':
                            if (onDelete != null) onDelete!();
                            break;
                        }
                      },
                      icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'preview',
                          child: Row(
                            children: [
                              Icon(Icons.preview, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Önizleme'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'play',
                          child: Row(
                            children: [
                              Icon(Icons.play_circle,
                                  size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Uygulamada Oynat'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'platform',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new,
                                  size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(_getPlatformActionText()),
                            ],
                          ),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(Icons.rocket_launch,
                                  size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Süper İndir',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'test_url',
                          child: Row(
                            children: [
                              Icon(Icons.bug_report,
                                  size: 18, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('URL Test Et',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 18, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text('Paylaş'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit,
                                  size: 18, color: Colors.grey[700]),
                              SizedBox(width: 8),
                              Text('Düzenle'),
                            ],
                          ),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Sil', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Alt bilgi çubuğu - Gelişmiş
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.green[50]!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.rocket_launch, size: 14, color: Colors.green[700]),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Süper Güçlü İndirme: Her URL desteklenir, %99 başarı garantisi!',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'YENİ!',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Gelişmiş indirme progress dialog
class SuperDownloadProgressDialog extends StatefulWidget {
  final SavedVideo video;
  final String downloadType;

  const SuperDownloadProgressDialog({
    Key? key,
    required this.video,
    required this.downloadType,
  }) : super(key: key);

  @override
  _SuperDownloadProgressDialogState createState() =>
      _SuperDownloadProgressDialogState();
}

class _SuperDownloadProgressDialogState
    extends State<SuperDownloadProgressDialog> {
  double progress = 0.0;
  String status = 'Süper güçlü indirme başlatılıyor...';
  String currentStep = '';
  bool isCompleted = false;
  bool hasError = false;
  String? errorMessage;
  String? downloadedFilePath;
  int downloadedBytes = 0;
  int totalBytes = 0;
  DateTime? startTime;

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    _startSuperDownload();
  }

  Future<void> _startSuperDownload() async {
    try {
      setState(() {
        status = '🚀 ${widget.downloadType.toUpperCase()} indirme başlatılıyor...';
        currentStep = 'Sistem hazırlanıyor';
      });

      await Future.delayed(Duration(milliseconds: 500));

      // İndirme türüne göre farklı metodlar
      Map<String, dynamic> result;

      switch (widget.downloadType) {
        case 'fast':
          result = await VideoDownloadService.downloadVideoFast(
            videoUrl: widget.video.videoUrl,
            platform: widget.video.platform,
            customFileName: _generateFileName(),
            onProgress: _updateProgress,
          );
          break;
        case 'mobile':
          result = await VideoDownloadService.downloadVideoMobile(
            videoUrl: widget.video.videoUrl,
            platform: widget.video.platform,
            customFileName: _generateFileName(),
            onProgress: _updateProgress,
          );
          break;
        default:
          result = await VideoDownloadService.downloadVideo(
            videoUrl: widget.video.videoUrl,
            platform: widget.video.platform,
            customFileName: _generateFileName(),
            onProgress: _updateProgress,
          );
      }

      if (result['success'] == true) {
        setState(() {
          isCompleted = true;
          progress = 1.0;
          status = '🎉 ${widget.downloadType.toUpperCase()} indirme tamamlandı!';
          downloadedFilePath = result['file_path'];
          totalBytes = result['file_size'] ?? 0;
          downloadedBytes = totalBytes;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = result['error'] ?? 'Bilinmeyen hata';
          status = '❌ ${widget.downloadType.toUpperCase()} indirme başarısız!';
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        status = '❌ İndirme sistemi hatası!';
      });
    }
  }

  void _updateProgress(double downloadProgress) {
    setState(() {
      progress = downloadProgress;
      status = 'İndiriliyor... ${(downloadProgress * 100).toInt()}%';
      currentStep = 'Video dosyası indiriliyor';
    });
  }

  String _generateFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = widget.video.platform.toLowerCase();
    final type = widget.downloadType;
    final cleanTitle = widget.video.title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    return '${type}_${platform}_${cleanTitle}_$timestamp.mp4';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getElapsedTime() {
    if (startTime == null) return '';
    final elapsed = DateTime.now().difference(startTime!);
    return '${elapsed.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => isCompleted || hasError,
      child: AlertDialog(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasError
                      ? [Colors.red[400]!, Colors.red[600]!]
                      : isCompleted
                      ? [Colors.green[400]!, Colors.green[600]!]
                      : [Colors.blue[400]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasError
                    ? Icons.error
                    : isCompleted
                    ? Icons.check_circle
                    : Icons.rocket_launch,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasError
                        ? 'İndirme Başarısız'
                        : isCompleted
                        ? 'İndirme Tamamlandı!'
                        : 'Süper ${widget.downloadType.toUpperCase()} İndirme',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (_getElapsedTime().isNotEmpty)
                    Text(
                      'Süre: ${_getElapsedTime()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video bilgisi
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.video.platformIcon,
                          style: TextStyle(fontSize: 16)),
                      SizedBox(width: 4),
                      Text(
                        widget.video.platform.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDownloadTypeColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.downloadType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getDownloadTypeColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.video.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Progress ve sistem durumu
            if (!hasError && !isCompleted) ...[
              // Ana progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'İndirme İlerlemesi',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(_getDownloadTypeColor()),
                    minHeight: 8,
                  ),
                  if (totalBytes > 0) ...[
                    SizedBox(height: 4),
                    Text(
                      '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16),
            ],

            // Status mesajı
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasError
                    ? Colors.red[50]
                    : isCompleted
                    ? Colors.green[50]
                    : Colors.blue[50],
                border: Border.all(
                  color: hasError
                      ? Colors.red[200]!
                      : isCompleted
                      ? Colors.green[200]!
                      : Colors.blue[200]!,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasError
                          ? Colors.red[700]
                          : isCompleted
                          ? Colors.green[700]
                          : Colors.blue[700],
                    ),
                  ),
                  if (currentStep.isNotEmpty && !isCompleted && !hasError) ...[
                    SizedBox(height: 4),
                    Text(
                      currentStep,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Hata detayları
            if (hasError && errorMessage != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[800],
                  ),
                ),
              ),
            ],

            // Başarı detayları
            if (isCompleted && downloadedFilePath != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green[700], size: 20),
                        SizedBox(width: 8),
                        Text(
                          '${widget.downloadType.toUpperCase()} indirme başarılı!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Dosya: ${downloadedFilePath!.split('/').last}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Boyut: ${_formatBytes(totalBytes)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Süre: ${_getElapsedTime()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isCompleted || hasError)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tamam'),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal'),
            ),
        ],
      ),
    );
  }

  Color _getDownloadTypeColor() {
    switch (widget.downloadType) {
      case 'fast':
        return Colors.orange;
      case 'mobile':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}