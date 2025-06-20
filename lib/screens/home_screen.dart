// Dosya Konumu: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/services/database_service.dart';
import 'package:linkcim/services/ai_service.dart';
import 'package:linkcim/services/video_download_service.dart';
import 'package:linkcim/screens/add_video_screen.dart';
import 'package:linkcim/screens/search_screen.dart';
import 'package:linkcim/screens/settings_screen.dart';
import 'package:linkcim/screens/download_history_screen.dart';
import 'package:linkcim/widgets/video_card.dart';
import 'package:linkcim/widgets/search_bar.dart';
import 'package:linkcim/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<SavedVideo> videos = [];
  List<SavedVideo> filteredVideos = [];
  List<String> categories = [];
  String selectedCategory = 'Tümü';
  bool isLoading = true;

  // Sistem durumu
  Map<String, dynamic> systemStatus = {};
  bool showSystemStatus = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _checkSystemStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final allVideos = await _dbService.getAllVideos();
      final allCategories = await _dbService.getAllCategories();

      setState(() {
        videos = allVideos;
        filteredVideos = allVideos;
        categories = ['Tümü', ...allCategories];
        isLoading = false;
      });

      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Veriler yüklenirken hata oluştu: $e');
    }
  }

  Future<void> _checkSystemStatus() async {
    try {
      // AI sistem durumunu kontrol et
      final aiEnabled = await AIService.isAIAnalysisEnabled;

      // İndirme sistemi durumunu kontrol et
      final downloadPermissions =
          await VideoDownloadService.requestPermissions();

      setState(() {
        systemStatus = {
          'ai_enabled': aiEnabled,
          'download_permissions': downloadPermissions,
          'total_videos': videos.length,
        };
      });
    } catch (e) {
      print('Sistem durumu kontrol hatası: $e');
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      if (category == 'Tümü') {
        filteredVideos = videos;
      } else {
        filteredVideos = videos.where((v) => v.category == category).toList();
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filterByCategory(selectedCategory);
      } else {
        filteredVideos = videos.where((v) => v.matchesSearch(query)).toList();
      }
    });
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

  Future<void> _deleteVideo(SavedVideo video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Video Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bu videoyu silmek istediğinizden emin misiniz?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                video.title,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbService.deleteVideo(video);
        _showSuccess('Video silindi');
        _loadData();
      } catch (e) {
        _showError('Video silinemedi: $e');
      }
    }
  }

  Widget _buildSystemStatusBanner() {
    if (systemStatus.isEmpty || !showSystemStatus) return SizedBox.shrink();

    final aiEnabled = systemStatus['ai_enabled'] ?? false;
    final downloadPermissions = systemStatus['download_permissions'] ?? false;
    final totalVideos = systemStatus['total_videos'] ?? 0;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[400]!, Colors.indigo[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Süper Güçlü Sistem Durumu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () => setState(() => showSystemStatus = false),
                icon: Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  '🧠 AI Analizi',
                  aiEnabled ? 'Aktif' : 'Pasif',
                  aiEnabled ? Colors.green[300]! : Colors.orange[300]!,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatusItem(
                  '📥 İndirme',
                  downloadPermissions ? 'Hazır' : 'İzin Gerekli',
                  downloadPermissions ? Colors.green[300]! : Colors.red[300]!,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  '📊 Toplam Video',
                  '$totalVideos video',
                  Colors.blue[300]!,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatusItem(
                  '🎯 Kategoriler',
                  '${categories.length - 1} kategori',
                  Colors.purple[300]!,
                ),
              ),
            ],
          ),

          // Video istatistikleri bölümü
          if (videos.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Video İstatistikleri',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Platform dağılımı
                  Text(
                    'Platform Dağılımı:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  _buildPlatformStats(),

                  SizedBox(height: 12),

                  // Kategori dağılımı
                  Text(
                    'Popüler Kategoriler:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  _buildCategoryStats(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformStats() {
    if (videos.isEmpty) return SizedBox.shrink();

    final platforms = <String, int>{};
    for (final video in videos) {
      final platformName = video.platform.isNotEmpty ? video.platform : 'Genel';
      platforms[platformName] = (platforms[platformName] ?? 0) + 1;
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: platforms.entries.map((entry) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryStats() {
    if (videos.isEmpty) return SizedBox.shrink();

    final categories = <String, int>{};
    for (final video in videos) {
      categories[video.category] = (categories[video.category] ?? 0) + 1;
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: categories.entries.take(5).map((entry) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.rocket_launch, size: 24),
            SizedBox(width: 8),
            Text('Linkcim'),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Sistem durumu butonu
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.dashboard),
                if (systemStatus.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Sistem Durumu',
            onPressed: () =>
                setState(() => showSystemStatus = !showSystemStatus),
          ),

          // İndirilen videolar
          IconButton(
            icon: Icon(Icons.video_library),
            tooltip: 'İndirilen Videolar',
            onPressed: () {
              print('🎬 İndirilen videolar sayfasına gidiliyor...');
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DownloadHistoryScreen()),
              ).then((_) => _loadData());
            },
          ),

          // Arama
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              ).then((_) => _loadData());
            },
          ),

          // Ayarlar
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              ).then((_) => _checkSystemStatus());
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Sistem durumu banner'ı
            _buildSystemStatusBanner(),

            // Arama çubuğu
            CustomSearchBar(
              onSearch: _onSearch,
              hintText: 'Videolarınızı arayın...',
            ),

            // Kategori filtreleri
            if (categories.isNotEmpty)
              Container(
                height: 50,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == selectedCategory;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 16 : 8,
                        right: 8,
                      ),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => _filterByCategory(category),
                        selectedColor: Colors.blue[100],
                        checkmarkColor: Colors.blue[800],
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Video listesi
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Videolar yükleniyor...'),
                        ],
                      ),
                    )
                  : filteredVideos.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredVideos.length,
                            itemBuilder: (context, index) {
                              final video = filteredVideos[index];
                              return VideoCard(
                                video: video,
                                onDelete: () => _deleteVideo(video),
                                onTap: () => _loadData(), // Refresh after edit
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddVideoScreen()),
          ).then((result) {
            if (result == true) {
              _loadData();
            }
          });
        },
        icon: Icon(Icons.add),
        label: Text('Yeni Video'),
        tooltip: 'Yeni Video Ekle',
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rocket_launch,
                size: 64,
                color: Colors.blue[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              videos.isEmpty
                  ? 'Henüz video eklemediniz'
                  : 'Arama kriterinize uygun video bulunamadı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              videos.isEmpty
                  ? 'İlk videonuzu eklemek için aşağıdaki butona tıklayın.\nSüper güçlü AI analizi ve indirme sistemi ile\nvideolarınızı organize edin!'
                  : 'Farklı anahtar kelimeler deneyin veya\nkategori filtrelerini kontrol edin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            if (videos.isEmpty) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddVideoScreen()),
                  ).then((result) {
                    if (result == true) {
                      _loadData();
                    }
                  });
                },
                icon: Icon(Icons.rocket_launch),
                label: Text('İlk Videonuzu Ekleyin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFeatureChip('🧠 AI Analizi'),
                  _buildFeatureChip('📥 Süper İndirme'),
                  _buildFeatureChip('🎯 Akıllı Kategori'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
