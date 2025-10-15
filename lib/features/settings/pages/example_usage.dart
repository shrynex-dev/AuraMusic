import 'package:flutter/material.dart';
import '../../../core/data_sources/music_data_source.dart';
import '../../../core/data_sources/newpipe_data_source.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Song> _searchResults = [];
  bool _isLoading = false;
  final _dataSource = NewPipeDataSource();

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    
    try {
      final results = await _dataSource.search(query);
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search music...'),
              onSubmitted: _performSearch,
            ),
          ),
          if (_isLoading) const CircularProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final song = _searchResults[index];
                return ListTile(
                  leading: song.thumbnailUrl.isNotEmpty
                      ? Image.network(song.thumbnailUrl, width: 50)
                      : null,
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
