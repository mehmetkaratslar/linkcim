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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        title: Text(
          'Gelişmiş Arama',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          // Filtre toggle butonu
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: showFilters ? Colors.blue[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                  color: showFilters ? Colors.blue[700] : Colors.grey[600],
                  size: 20,
                ),
              ),
              onPressed: () {
                setState(() => showFilters = !showFilters);
              },
              tooltip: 'Filtreleri ${showFilters ? 'Gizle' : 'Göster'}',
            ),
          ),
          // Temizle butonu
          if (selectedCategory != 'Tumu' ||
              selectedPlatform != 'Tumu' ||
              selectedAuthor != 'Tumu' ||
              selectedTags.isNotEmpty ||
              _searchController.text.isNotEmpty)
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
                onPressed: _clearFilters,
                tooltip: 'Filtreleri Temizle',
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

          // Filtre bölümü - Modern kart tasarımı
          if (showFilters) ...[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtre başlığı
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.tune_rounded,
                            color: Colors.blue[600], size: 20),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Filtreler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Kategori filtreleri
                  if (allCategories.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.category_outlined,
                            size: 18, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text(
                          'Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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
                    Row(
                      children: [
                        Icon(Icons.devices_outlined,
                            size: 18, color: Colors.purple[600]),
                        SizedBox(width: 8),
                        Text(
                          'Platform',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 18, color: Colors.orange[600]),
                        SizedBox(width: 8),
                        Text(
                          'Yazar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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
                    Row(
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 18, color: Colors.green[600]),
                        SizedBox(width: 8),
                        Text(
                          'Etiketler',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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
          ],

          // Sonuç sayısı ve aktif filtreler
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                if (selectedTags.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Seçili etiketler: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: selectedTags
                              .map((tag) => TagChip(
                                    tag: tag,
                                    size: TagChipSize.small,
                                    onDeleted: () => _toggleTag(tag),
                                    showDelete: true,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
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
                                  _loadFilterOptions();
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
              'Arama kriterinize uygun video bulunamadı.\nFarklı anahtar kelimeler veya filtreler deneyin.',
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
                onPressed: _clearFilters,
                icon: Icon(Icons.refresh_rounded),
                label: Text('Filtreleri Temizle'),
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
