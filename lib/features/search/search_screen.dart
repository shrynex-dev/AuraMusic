import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/song.dart';
import '../../shared/models/album.dart';
import '../../shared/widgets/song_list_tile.dart';
import '../../shared/widgets/album_list_tile.dart';
import '../album/album_detail_screen.dart';
import '../artist/artist_profile_screen.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final debouncedSearchProvider = StateProvider<String>((ref) => '');


final searchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(debouncedSearchProvider);
  if (query.isEmpty) return [];
  return await ApiService.searchSongs(query);
});

final albumSearchResultsProvider = FutureProvider<List<Album>>((ref) async {
  final query = ref.watch(debouncedSearchProvider);
  if (query.isEmpty) return [];
  return await ApiService.searchAlbums(query);
});

final artistSearchResultsProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  final query = ref.watch(debouncedSearchProvider);
  if (query.isEmpty) return [];
  return await ApiService.searchArtists(query);
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _speechToText = SpeechToText();
  Timer? _debounceTimer;
  bool _isListening = false;

  @override
  bool get wantKeepAlive => true;

  final _categories = [
    {'name': 'Trending', 'query': 'trending music', 'color': '0xFFE13300'},
    {'name': 'Pop', 'query': 'pop music', 'color': '0xFFDC148C'},
    {'name': 'Rock', 'query': 'rock music', 'color': '0xFF8D67AB'},
    {'name': 'Hip Hop', 'query': 'hip hop music', 'color': '0xFFBA5D07'},
    {'name': 'Electronic', 'query': 'electronic music', 'color': '0xFF1E3264'},
    {'name': 'Classical', 'query': 'classical music', 'color': '0xFF8D67AB'},
    {'name': 'Jazz', 'query': 'jazz music', 'color': '0xFF148A08'},
    {'name': 'Country', 'query': 'country music', 'color': '0xFF8C1932'},
    {'name': 'R&B', 'query': 'r&b music', 'color': '0xFFB06239'},
    {'name': 'Indie', 'query': 'indie music', 'color': '0xFF509BF5'},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    final currentQuery = ref.read(searchQueryProvider);
    if (currentQuery.isNotEmpty) {
      _searchController.text = currentQuery;
    }
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _searchController.text = result.recognizedWords;
              _onSearchChanged(result.recognizedWords);
            });
          },
        );
      }
    }
  }

  void _stopListening() {
    _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(debouncedSearchProvider.notifier).state = '';
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(debouncedSearchProvider.notifier).state = value;
    });
  }

  Widget _buildArtistSection() {
    final artistResults = ref.watch(artistSearchResultsProvider);
    
    return artistResults.when(
      data: (artists) => artists.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Artists',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: artists.length,
                    itemBuilder: (context, index) {
                      final artist = artists[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArtistProfileScreen(artistName: artist['name']!),
                            ),
                          );
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundImage: artist['thumbnail']!.isNotEmpty
                                    ? NetworkImage(artist['thumbnail']!)
                                    : null,
                                child: artist['thumbnail']!.isEmpty
                                    ? const Icon(Icons.person, size: 24)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  artist['name']!,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoriesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse All',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final color = Color(int.parse(category['color']!));
              return GestureDetector(
                onTap: () {
                  _searchController.text = category['query']!;
                  _onSearchChanged(category['query']!);
                  setState(() {});
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      category['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final searchResults = ref.watch(searchResultsProvider);
    final albumResults = ref.watch(albumSearchResultsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        // First: close keyboard if open
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
          return;
        }
        
        // Second: clear search if something is searched
        if (_searchController.text.isNotEmpty) {
          _clearSearch();
          return;
        }
        
        // Third: navigate back to home
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search songs, artists, albums...',
              border: InputBorder.none,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    ),
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    color: _isListening ? Colors.red : null,
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                ],
              ),
            ),
            onChanged: (value) {
              _onSearchChanged(value);
              setState(() {});
            },
            onTap: () => setState(() {}),
          ),
        ),
      body: _searchController.text.isEmpty
          ? _buildCategoriesView()
          : Column(
              children: [
                _buildArtistSection(),
                Expanded(
                  child: searchResults.when(
                          data: (songs) => songs.isEmpty
                              ? _buildEmptyState('No songs found', Icons.search_off_rounded)
                              : CustomScrollView(
                                  slivers: [
                                    SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => SongListTile(
                                          song: songs[index],
                                          playlist: songs,
                                        ),
                                        childCount: songs.length,
                                      ),
                                    ),
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'Albums',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    albumResults.when(
                                      data: (albums) => SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) => AlbumListTile(
                                            album: albums[index],
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AlbumDetailScreen(album: albums[index]),
                                                ),
                                              );
                                            },
                                          ),
                                          childCount: albums.length,
                                        ),
                                      ),
                                      loading: () => const SliverToBoxAdapter(
                                        child: Center(child: CircularProgressIndicator()),
                                      ),
                                      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                                    ),
                                  ],
                                ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Center(child: Text('Error: $error')),
                        ),
                ),
              ],
            ),
      ),
    );
  }
}
