import 'package:flutter/material.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/services/video_download_service.dart';

class DownloadProgressDialog extends StatefulWidget {
  final SavedVideo video;

  const DownloadProgressDialog({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  _DownloadProgressDialogState createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double progress = 0.0;
  String status = 'İndirme başlatılıyor...';
  bool isCompleted = false;
  bool hasError = false;
  String? errorMessage;
  String? downloadedFilePath;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      setState(() {
        status =
            '${widget.video.platform.toUpperCase()} video URL\'si alınıyor...';
      });

      final result = await VideoDownloadService.downloadVideo(
        videoUrl: widget.video.videoUrl,
        platform: widget.video.platform,
        customFileName: _generateFileName(),
        onProgress: (downloadProgress) {
          setState(() {
            progress = downloadProgress;
            status = 'İndiriliyor... ${(downloadProgress * 100).toInt()}%';
          });
        },
      );

      if (result['success'] == true) {
        setState(() {
          isCompleted = true;
          progress = 1.0;
          status = 'İndirme tamamlandı!';
          downloadedFilePath = result['file_path'];
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = result['error'] ?? 'Bilinmeyen hata';
          status = 'İndirme başarısız!';
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        status = 'İndirme hatası!';
      });
    }
  }

  String _generateFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = widget.video.platform.toLowerCase();
    final cleanTitle = widget.video.title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    return '${platform}_${cleanTitle}_$timestamp.mp4';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => isCompleted || hasError,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              hasError
                  ? Icons.error
                  : isCompleted
                      ? Icons.check_circle
                      : Icons.download,
              color: hasError
                  ? Colors.red
                  : isCompleted
                      ? Colors.green
                      : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasError
                    ? 'İndirme Hatası'
                    : isCompleted
                        ? 'İndirme Tamamlandı'
                        : 'Video İndiriliyor',
                style: TextStyle(fontSize: 16),
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
                      const SizedBox(width: 4),
                      Text(
                        widget.video.platform.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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

            const SizedBox(height: 16),

            // Progress bar (sadece indirme sırasında)
            if (!hasError && !isCompleted) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
            ],

            // Status mesajı
            Text(
              status,
              style: TextStyle(
                fontSize: 14,
                color: hasError
                    ? Colors.red[700]
                    : isCompleted
                        ? Colors.green[700]
                        : Colors.grey[700],
              ),
            ),

            // Hata mesajı
            if (hasError && errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
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

            // Başarı mesajı
            if (isCompleted && downloadedFilePath != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video başarıyla indirildi!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dosya: ${downloadedFilePath!.split('/').last}',
                      style: TextStyle(
                        fontSize: 11,
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
              child: const Text('Tamam'),
            )
          else
            TextButton(
              onPressed: () {
                // TODO: İndirmeyi iptal etme özelliği eklenebilir
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
        ],
      ),
    );
  }
}
