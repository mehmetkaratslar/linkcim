// Dosya Konumu: lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/services/database_service.dart';
import 'package:linkcim/widgets/video_card.dart';
import 'package:linkcim/widgets/tag_chip.dart';
import 'package:linkcim/screens/add_video_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  List<SavedVideo> searchResults = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => isLoading = true);

    try {
      List<SavedVideo> results;
      String query = _searchController.text.trim();

      if (query.isEmpty) {
        // Arama metni yoksa tüm videoları getir
        results = await _dbService.getAllVideos();
      } else {
        // Text araması yap
        results = await _dbService.searchVideos(query);
      }

      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Arama hatası: $e');
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

  Future<void> _deleteVideo(SavedVideo video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Video Sil'),
        content: Text('Bu videoyu silmek istediğinizden emin misiniz?'),
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
      try {
        await _dbService.deleteVideo(video);
        _showSuccess('Video silindi');
        _performSearch();
      } catch (e) {
        _showError('Video silinemedi: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        title: Text(
          'Video Arama',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          // Temizle butonu - sadece arama metni varsa göster
          if (_searchController.text.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.clear_all_rounded,
                    color: Colors.red[700],
                    size: 20,
                  ),
                ),
                onPressed: () {
                  _searchController.clear();
                  _performSearch();
                },
                tooltip: 'Aramayı Temizle',
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Column(
        children: [
          // Arama çubuğu - Modern tasarım
          Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Video ara... (başlık, yazar, platform, etiket)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                prefixIcon: Container(
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.search_rounded,
                      color: Colors.blue[600], size: 20),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Container(
                        margin: EdgeInsets.all(12),
                        child: IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.clear_rounded,
                                color: Colors.grey[600], size: 16),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch();
                          },
                        ),
                      )
                    : null,
              ),
              onChanged: (_) => _performSearch(),
            ),
          ),

          // Sonuç sayısı
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.video_library_outlined,
                      color: Colors.blue[600], size: 16),
                ),
                SizedBox(width: 8),
                Text(
                  '${searchResults.length} video bulundu',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Sonuçlar
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : searchResults.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final video = searchResults[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            child: VideoCard(
                              video: video,
                              onDelete: () => _deleteVideo(video),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddVideoScreen(video: video),
                                  ),
                                ).then((_) {
                                  _performSearch();
                                });
                              },
                              highlightText: _searchController.text,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(40),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Video Bulunamadı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Arama kriterinize uygun video bulunamadı.\nFarklı anahtar kelimeler deneyin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _performSearch();
                },
                icon: Icon(Icons.refresh_rounded),
                label: Text('Aramayı Temizle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
