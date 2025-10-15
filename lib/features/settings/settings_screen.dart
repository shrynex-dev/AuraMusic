import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/theme_provider.dart';
import '../../core/services/download_service.dart';
import '../../core/services/audio_service.dart';
import 'credits_screen.dart';

final selectedApiProvider = StateProvider<String>((ref) => 'youtube');
final audioQualityProvider = StateProvider<String>((ref) => 'high');
final downloadQualityProvider = StateProvider<String>((ref) => 'medium');

final downloadLocationProvider = FutureProvider<DownloadLocation>((ref) async {
  return await DownloadService.getDownloadLocation();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedApi = ref.watch(selectedApiProvider);
    final audioQuality = ref.watch(audioQualityProvider);
    final downloadQuality = ref.watch(downloadQualityProvider);
    final themeMode = ref.watch(themeModeProvider);
    final darkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSection('API Settings', [
            ListTile(
              title: const Text('Music Source'),
              subtitle: const Text('YouTube + Archive.org'),
              trailing: const Icon(Icons.info_outline),
              onTap: () => _showSourceInfo(context),
            ),
          ]),
          _buildSection('Audio Settings', [
            ListTile(
              title: const Text('Streaming Quality'),
              subtitle: Text(_getQualityDisplayName(audioQuality)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showQualitySelector(context, ref, 'audio'),
            ),
            ListTile(
              title: const Text('Download Quality'),
              subtitle: Text(_getQualityDisplayName(downloadQuality)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showQualitySelector(context, ref, 'download'),
            ),
            Consumer(
              builder: (context, ref, child) {
                final locationAsync = ref.watch(downloadLocationProvider);
                return locationAsync.when(
                  data: (location) => ListTile(
                    title: const Text('Download Location'),
                    subtitle: Text(
                      location == DownloadLocation.external
                          ? 'Music/AuraMusic or Download/AuraMusic'
                          : 'App Internal Storage',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDownloadLocationSelector(context, ref),
                  ),
                  loading: () => const ListTile(
                    title: Text('Download Location'),
                    subtitle: Text('Loading...'),
                  ),
                  error: (_, __) => const ListTile(
                    title: Text('Download Location'),
                    subtitle: Text('Error loading'),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Equalizer'),
              subtitle: const Text('System audio equalizer'),
              trailing: const Icon(Icons.equalizer),
              onTap: () => _openSystemEqualizer(context),
            ),
          ]),
          _buildSection('Appearance', [
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: darkMode,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
          ]),
          _buildSection('About', [
            ListTile(
              title: const Text('Version'),
              subtitle: const Text('1.7.0'),
              trailing: const Icon(Icons.info_outline),
            ),
            ListTile(
              title: const Text('Credits & Legal'),
              subtitle: const Text('Acknowledgments and legal information'),
              trailing: const Icon(Icons.gavel),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreditsScreen()),
              ),
            ),
            ListTile(
              title: const Text('Developer'),
              subtitle: const Text('shrynex'),
              trailing: const Icon(Icons.person_outline),
            ),
          ]),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Made with ❤️ and Flutter',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  String _getApiDisplayName(String api) {
    return 'YouTube + Archive.org';
  }

  String _getQualityDisplayName(String quality) {
    switch (quality) {
      case 'low':
        return 'Low (96 kbps)';
      case 'medium':
        return 'Medium (160 kbps)';
      case 'high':
        return 'High (320 kbps)';
      default:
        return 'High (320 kbps)';
    }
  }

  void _showSourceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Music Sources'),
        content: const Text(
          'AuraMusic uses:\n\n'
          '• YouTube (Primary) - Vast music library via NewPipe\n'
          '• Archive.org (Fallback) - Open-source audio content\n\n'
          'This ensures the best music discovery experience.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showQualitySelector(BuildContext context, WidgetRef ref, String type) {
    final provider = type == 'audio'
        ? audioQualityProvider
        : downloadQualityProvider;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select ${type == 'audio' ? 'Streaming' : 'Download'} Quality',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('High (320 kbps)'),
            subtitle: const Text('Best quality, more data usage'),
            trailing: ref.watch(provider) == 'high'
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              ref.read(provider.notifier).state = 'high';
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Medium (160 kbps)'),
            subtitle: const Text('Good quality, balanced usage'),
            trailing: ref.watch(provider) == 'medium'
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              ref.read(provider.notifier).state = 'medium';
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Low (96 kbps)'),
            subtitle: const Text('Lower quality, saves data'),
            trailing: ref.watch(provider) == 'low'
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              ref.read(provider.notifier).state = 'low';
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDownloadLocationSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Download Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('External Storage'),
            subtitle: const Text(
              'Music/AuraMusic or Download/AuraMusic\nAccessible from file manager',
            ),
            trailing: const Icon(Icons.folder),
            onTap: () async {
              await DownloadService.setDownloadLocation(
                DownloadLocation.external,
              );
              ref.invalidate(downloadLocationProvider);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('App Internal Storage'),
            subtitle: const Text(
              'Private app directory (auto-deleted on uninstall)',
            ),
            trailing: const Icon(Icons.phone_android),
            onTap: () async {
              await DownloadService.setDownloadLocation(
                DownloadLocation.internal,
              );
              ref.invalidate(downloadLocationProvider);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _openSystemEqualizer(BuildContext context) async {
    try {
      const platform = MethodChannel('com.auramusic/equalizer');
      final audioSessionId = AudioPlayerService.audioSessionId;

      if (audioSessionId != null) {
        await platform.invokeMethod('openEqualizer', {
          'audioSessionId': audioSessionId,
        });
      } else {
        await platform.invokeMethod('openEqualizer');
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Equalizer Not Available'),
            content: const Text(
              'Your device does not have a system equalizer or it is not accessible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
