import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../artist/artist_profile_screen.dart';

final followedArtistsProvider = FutureProvider<List<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys().where((k) => k.startsWith('follow_') && prefs.getBool(k) == true);
  return keys.map((k) => k.substring(7)).toList();
});

class FollowedArtistsScreen extends ConsumerWidget {
  const FollowedArtistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(followedArtistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Followed Artists'),
      ),
      body: artistsAsync.when(
        data: (artists) => artists.isEmpty
            ? const Center(child: Text('No followed artists'))
            : ListView.builder(
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artistName = artists[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(artistName[0].toUpperCase()),
                    ),
                    title: Text(artistName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArtistProfileScreen(artistName: artistName),
                        ),
                      );
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading artists')),
      ),
    );
  }
}
