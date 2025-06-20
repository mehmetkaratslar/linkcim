// Dosya Konumu: lib/screens/download_history_screen.dart

import 'package:flutter/material.dart';
import 'package:linkcim/services/video_download_service.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class DownloadHistoryScreen extends StatefulWidget {
  @override
  _DownloadHistoryScreenState createState() => _DownloadHistoryScreenState();
}

class _DownloadHistoryScreenState extends State<DownloadHistoryScreen> {
  List<Map<String, dynamic>> downloadHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadHistory();
  }

  Future<void> _loadDownloadHistory() async {
    setState(() => isLoading = true);

    try {
      print('🎬 İndirme geçmişi yükleniyor...');
      final history = await VideoDownloadService.getDownloadHistory();
      print('🎬 İndirme geçmişi yüklendi: ${history.length} dosya');
      setState(() {
        downloadHistory = history;
        isLoading = false;
      });
    } catch (e) {
      print('🎬 İndirme geçmişi yükleme hatası: $e');
      setState(() => isLoading = false);
      _showError('İndirme geçmişi yüklenemedi: $e');
    }
  }

  Future<void> _deleteFile(String filePath, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dosyayı Sil'),
        content: Text('Bu dosyayı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await VideoDownloadService.deleteDownloadedFile(filePath);
      if (success) {
        setState(() {
          downloadHistory.removeAt(index);
        });
        _showSuccess('Dosya silindi');
      } else {
        _showError('Dosya silinemedi');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  String _extractPlatformFromFileName(String fileName) {
    if (fileName.startsWith('instagram_')) return '📷 Instagram';
    if (fileName.startsWith('youtube_')) return '📺 YouTube';
    if (fileName.startsWith('tiktok_')) return '🎵 TikTok';
    if (fileName.startsWith('twitter_')) return '🐦 Twitter';
    return '🔗 Genel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İndirilenler'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDownloadHistory,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : downloadHistory.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // İstatistikler
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${downloadHistory.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Text(
                                'Toplam Video',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                _formatFileSize(_getTotalSize()),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Text(
                                'Toplam Boyut',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Dosya listesi
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: downloadHistory.length,
                        itemBuilder: (context, index) {
                          final item = downloadHistory[index];
                          return _buildDownloadItem(item, index);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Henüz İndirilen Video Yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Video kartlarındaki "İndir" butonunu kullanarak\nvideoları cihazınıza indirebilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(Map<String, dynamic> item, int index) {
    final fileName = item['file_name'] as String;
    final filePath = item['file_path'] as String;
    final fileSize = item['file_size'] as int;
    final downloadDate = item['download_date'] as DateTime;
    final platform = _extractPlatformFromFileName(fileName);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım - Platform ve tarih
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(platform),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    platform,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(downloadDate),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Video bilgileri
            Row(
              children: [
                // Video thumbnail placeholder
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Icon(
                    Icons.video_file,
                    size: 30,
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(width: 12),

                // Video detayları
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName.replaceAll('.mp4', '').replaceAll('_', ' '),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.storage,
                              size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            _formatFileSize(fileSize),
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
              ],
            ),

            SizedBox(height: 16),

            // Alt kısım - Butonlar
            Row(
              children: [
                // Oynatma butonu
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _playVideo(filePath, fileName),
                    icon: Icon(Icons.play_arrow, size: 18),
                    label: Text('Oynat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Paylaşma butonu
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareFile(filePath),
                    icon: Icon(Icons.share, size: 18),
                    label: Text('Paylaş'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
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
                        case 'info':
                          _showFileInfo(item);
                          break;
                        case 'delete':
                          _deleteFile(filePath, index);
                          break;
                      }
                    },
                    icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'info',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Detaylar'),
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
          ],
        ),
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    if (platform.contains('Instagram')) return Colors.purple;
    if (platform.contains('YouTube')) return Colors.red;
    if (platform.contains('TikTok')) return Colors.black;
    if (platform.contains('Twitter')) return Colors.blue;
    return Colors.grey;
  }

  int _getTotalSize() {
    return downloadHistory.fold(
      0,
      (total, item) => total + (item['file_size'] as int),
    );
  }

  Future<void> _playVideo(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _showError('Video dosyası bulunamadı');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            filePath: filePath,
            fileName: fileName,
          ),
        ),
      );
    } catch (e) {
      _showError('Video oynatılamadı: $e');
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _showError('Video dosyası bulunamadı');
        return;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Linkcim uygulamasından indirilen video',
      );
    } catch (e) {
      _showError('Video paylaşılamadı: $e');
    }
  }

  void _showFileInfo(Map<String, dynamic> item) {
    final fileName = item['file_name'] as String;
    final filePath = item['file_path'] as String;
    final fileSize = item['file_size'] as int;
    final downloadDate = item['download_date'] as DateTime;
    final platform = _extractPlatformFromFileName(fileName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Video Detayları'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Dosya Adı:', fileName),
            _buildInfoRow('Platform:', platform),
            _buildInfoRow('Boyut:', _formatFileSize(fileSize)),
            _buildInfoRow('İndirilme Tarihi:', _formatDate(downloadDate)),
            _buildInfoRow('Dosya Yolu:', filePath),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[900]),
            ),
          ),
        ],
      ),
    );
  }
}

// Video oynatıcı ekranı
class VideoPlayerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const VideoPlayerScreen({
    Key? key,
    required this.filePath,
    required this.fileName,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController =
          VideoPlayerController.file(File(widget.filePath));
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightBlue,
        ),
        placeholder: Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 60),
                SizedBox(height: 16),
                Text(
                  'Video oynatılamadı',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              try {
                await Share.shareXFiles(
                  [XFile(widget.filePath)],
                  text: 'Linkcim uygulamasından paylaşılan video',
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Paylaşılamadı: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Video yükleniyor...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 60),
                      SizedBox(height: 16),
                      Text(
                        'Video oynatılamadı',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          error!,
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : Container(),
      ),
    );
  }
}
