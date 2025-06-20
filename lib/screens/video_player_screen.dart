// Dosya Konumu: lib/screens/video_player_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/utils/url_utils.dart';
import 'package:linkcim/widgets/share_menu.dart';

class VideoPlayerScreen extends StatefulWidget {
  final SavedVideo video;

  const VideoPlayerScreen({Key? key, required this.video}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late WebViewController controller;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final embedUrl = UrlUtils.convertToEmbedUrl(widget.video.videoUrl);

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              isLoading = false;
              hasError = true;
              errorMessage = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Instagram'ın kendi sayfalarına yönlendirmeleri engelle
            if (request.url.contains('instagram.com') &&
                !request.url.contains('/embed/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
  }

  void _refresh() {
    setState(() {
      hasError = false;
      errorMessage = null;
    });
    _initializeWebView();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.video.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => ShareMenu.show(context, widget.video),
            tooltip: 'Paylaş',
          ),
        ],
      ),
      body: Column(
        children: [
          // Video bilgileri
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.video.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.category, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      widget.video.category,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      widget.video.formattedDate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // WebView veya hata durumu
          Expanded(
            child: hasError ? _buildErrorWidget() : _buildWebView(),
          ),

          // Alt bilgi çubuğu
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu video Instagram\'dan yükleniyor. Yavaş bağlantılarda yükleme uzun sürebilir.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: controller),

        // Loading indicator
        if (isLoading)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Video yükleniyor...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Instagram\'dan içerik alınıyor...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          SizedBox(height: 24),
          Text(
            'Video Yüklenemedi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 16),
          Text(
            errorMessage ?? 'Bilinmeyen bir hata oluştu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: Icon(Icons.refresh),
                  label: Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.arrow_back),
                  label: Text('Geri Dön'),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                    SizedBox(width: 8),
                    Text(
                      'İpucu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Video yüklenmiyorsa:\n• İnternet bağlantınızı kontrol edin\n• Video private olabilir\n• Instagram\'da direkt açmayı deneyin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Basit video oynatıcı widget'ı (başka yerlerde kullanım için)
class SimpleVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final double? height;

  const SimpleVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.height = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final embedUrl = UrlUtils.convertToEmbedUrl(videoUrl);

    return Container(
      height: height,
      child: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(embedUrl)),
      ),
    );
  }
}