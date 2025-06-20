// Dosya Konumu: lib/widgets/search_bar.dart

import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String hintText;
  final String? initialValue;

  const CustomSearchBar({
    Key? key,
    required this.onSearch,
    this.hintText = 'Ara...',
    this.initialValue,
  }) : super(key: key);

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() => _isSearching = true);
    widget.onSearch(_controller.text);

    // Kullanici deneyimi icin kisa bir gecikme
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          // Kullanici yazmaya devam ediyorsa bekle
          Future.delayed(Duration(milliseconds: 500), () {
            if (_controller.text == value) {
              _performSearch();
            }
          });
        },
        onSubmitted: (_) => _performSearch(),
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: _isSearching
              ? Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearSearch,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}