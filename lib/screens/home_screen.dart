// Dosya Konumu: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/services/database_service.dart';
import 'package:linkcim/screens/add_video_screen.dart';
import 'package:linkcim/screens/search_screen.dart';
import 'package:linkcim/screens/settings_screen.dart';
import 'package:linkcim/screens/download_history_screen.dart';
import 'package:linkcim/widgets/video_card.dart';
import 'package:linkcim/widgets/search_bar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SavedVideo> videos = [];
  List<SavedVideo> filteredVideos = [];
  List<String> categories = [];
  String selectedCategory = 'Tümü';
  bool isLoading = true;

  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadData();
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
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Veriler yuklenirken hata olustu: $e');
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
        title: Text('Video Sil'),
        content: Text('Bu videoyu silmek istediginizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Iptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Linkcim'),
        automaticallyImplyLeading: false, // Geri tuşunu kaldır
        actions: [
          IconButton(
            icon: Icon(Icons.video_library),
            tooltip: 'İndirilen Videolar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DownloadHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              ).then((_) => _loadData());
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama cubugu
          CustomSearchBar(
            onSearch: _onSearch,
            hintText: 'Videoyunu ara...',
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
                    padding:
                        EdgeInsets.only(left: index == 0 ? 16 : 8, right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) => _filterByCategory(category),
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue[800],
                    ),
                  );
                },
              ),
            ),

          // Video listesi
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddVideoScreen(video: video),
                                  ),
                                ).then((_) => _loadData());
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddVideoScreen()),
          ).then((_) => _loadData());
        },
        child: Icon(Icons.add),
        tooltip: 'Yeni Video Ekle',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            videos.isEmpty
                ? 'Henuz video eklemediniz'
                : 'Arama kriterinize uygun video bulunamadi',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            videos.isEmpty
                ? 'Ilk videonuzu eklemek icin + butonuna tiklayin'
                : 'Farkli anahtar kelimeler deneyin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
