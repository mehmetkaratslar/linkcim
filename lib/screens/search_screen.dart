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
  List<String> allCategories = [];
  List<String> allTags = [];
  List<String> allPlatforms = [];
  List<String> allAuthors = [];

  String selectedCategory = 'Tumu';
  String selectedPlatform = 'Tumu';
  String selectedAuthor = 'Tumu';
  List<String> selectedTags = [];
  bool isLoading = false;
  bool showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _performSearch();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final categories = await _dbService.getAllCategories();
      final tags = await _dbService.getAllTags();
      final platforms = await _dbService.getAllPlatforms();
      final authors = await _dbService.getAllAuthors();

      setState(() {
        allCategories = ['Tumu', ...categories];
        allTags = tags;
        allPlatforms = ['Tumu', ...platforms];
        allAuthors = ['Tumu', ...authors];
      });
    } catch (e) {
      print('Filter yuklenirken hata: $e');
    }
  }

  Future<void> _performSearch() async {
    setState(() => isLoading = true);

    try {
      List<SavedVideo> results;
      String query = _searchController.text.trim();

      if (query.isEmpty && selectedCategory == 'Tumu' && selectedTags.isEmpty) {
        // Hic filtre yoksa tum videolari getir
        results = await _dbService.getAllVideos();
      } else {
        // Once text aramasini yap
        if (query.isNotEmpty) {
          results = await _dbService.searchVideos(query);
        } else {
          results = await _dbService.getAllVideos();
        }

        // Kategori filtresini uygula
        if (selectedCategory != 'Tumu') {
          results =
              results.where((v) => v.category == selectedCategory).toList();
        }

        // Platform filtresini uygula
        if (selectedPlatform != 'Tumu') {
          results = results
              .where((v) =>
                  v.platform.toLowerCase() == selectedPlatform.toLowerCase())
              .toList();
        }

        // Yazar filtresini uygula
        if (selectedAuthor != 'Tumu') {
          final cleanAuthor = selectedAuthor.replaceAll('@', '');
          results = results
              .where((video) =>
                  video.authorName
                      .toLowerCase()
                      .contains(cleanAuthor.toLowerCase()) ||
                  video.authorUsername
                      .toLowerCase()
                      .contains(cleanAuthor.toLowerCase()))
              .toList();
        }

        // Etiket filtresini uygula
        if (selectedTags.isNotEmpty) {
          results = results.where((video) {
            return selectedTags.every((tag) => video.tags.contains(tag));
          }).toList();
        }
      }

      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Arama hatasi: $e');
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
    _performSearch();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      selectedCategory = 'Tumu';
      selectedPlatform = 'Tumu';
      selectedAuthor = 'Tumu';
      selectedTags.clear();
    });
    _performSearch();
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
        _performSearch();
        _loadFilterOptions();
      } catch (e) {
        _showError('Video silinemedi: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gelismis Arama'),
        actions: [
          IconButton(
            icon: Icon(showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() => showFilters = !showFilters);
            },
            tooltip: 'Filtreleri ${showFilters ? 'Gizle' : 'Goster'}',
          ),
          if (selectedCategory != 'Tumu' ||
              selectedPlatform != 'Tumu' ||
              selectedAuthor != 'Tumu' ||
              selectedTags.isNotEmpty ||
              _searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Filtreleri Temizle',
            ),
        ],
      ),
      body: Column(
        children: [
          // Arama cubugu
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Başlık, açıklama, yazar, platform, kategori veya etiket ara...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _performSearch(),
            ),
          ),

          // Filtre bolumu
          if (showFilters) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori filtreleri
                  if (allCategories.isNotEmpty) ...[
                    Text(
                      'Kategori:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allCategories.length,
                        itemBuilder: (context, index) {
                          final category = allCategories[index];
                          final isSelected = category == selectedCategory;

                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => selectedCategory = category);
                                _performSearch();
                              },
                              selectedColor: Colors.blue[100],
                              checkmarkColor: Colors.blue[800],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Platform filtreleri
                  if (allPlatforms.isNotEmpty) ...[
                    Text(
                      'Platform:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allPlatforms.length,
                        itemBuilder: (context, index) {
                          final platform = allPlatforms[index];
                          final isSelected = platform == selectedPlatform;

                          // Platform ikonunu al
                          String icon = '🔗';
                          if (platform.toLowerCase() == 'instagram')
                            icon = '📷';
                          else if (platform.toLowerCase() == 'youtube')
                            icon = '📺';
                          else if (platform.toLowerCase() == 'tiktok')
                            icon = '🎵';
                          else if (platform.toLowerCase() == 'twitter')
                            icon = '🐦';

                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(icon),
                                  SizedBox(width: 4),
                                  Text(platform == 'Tümü'
                                      ? platform
                                      : platform.toUpperCase()),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => selectedPlatform = platform);
                                _performSearch();
                              },
                              selectedColor: Colors.purple[100],
                              checkmarkColor: Colors.purple[800],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Yazar filtreleri
                  if (allAuthors.isNotEmpty) ...[
                    Text(
                      'Yazar:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allAuthors.length,
                        itemBuilder: (context, index) {
                          final author = allAuthors[index];
                          final isSelected = author == selectedAuthor;

                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(author.length > 15
                                  ? '${author.substring(0, 15)}...'
                                  : author),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => selectedAuthor = author);
                                _performSearch();
                              },
                              selectedColor: Colors.orange[100],
                              checkmarkColor: Colors.orange[800],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Etiket filtreleri
                  if (allTags.isNotEmpty) ...[
                    Text(
                      'Etiketler:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allTags.map((tag) {
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (_) => _toggleTag(tag),
                          selectedColor: Colors.green[100],
                          checkmarkColor: Colors.green[800],
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            Divider(),
          ],

          // Sonuc sayisi
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${searchResults.length} video bulundu',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Spacer(),
                if (selectedTags.isNotEmpty) ...[
                  Text('Secili etiketler: ', style: TextStyle(fontSize: 12)),
                  ...selectedTags.map((tag) => Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: TagChip(
                          tag: tag,
                          size: TagChipSize.small,
                          onDeleted: () => _toggleTag(tag),
                          showDelete: true,
                        ),
                      )),
                ],
              ],
            ),
          ),

          // Sonuclar
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : searchResults.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final video = searchResults[index];
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
                              ).then((_) {
                                _performSearch();
                                _loadFilterOptions();
                              });
                            },
                            highlightText: _searchController.text,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Arama kriterinize uygun video bulunamadi',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Farkli anahtar kelimeler veya filtreler deneyin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _clearFilters,
            child: Text('Filtreleri Temizle'),
          ),
        ],
      ),
    );
  }
}
