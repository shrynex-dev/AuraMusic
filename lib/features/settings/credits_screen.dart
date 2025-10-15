import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credits & Legal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Legal Notice',
            'AuraMusic is a music streaming application that aggregates content from publicly available sources. We do not host, store, or own any music content. All music is streamed directly from the respective sources.',
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Content Sources',
            'All music content is provided by third-party services. We respect and acknowledge the rights of all content creators, artists, labels, and distributors.',
          ),
          const SizedBox(height: 24),
          _buildCreditCard(
            context,
            'Archive.org',
            'Internet Archive - A non-profit digital library offering free access to millions of audio recordings, videos, and texts.',
            Icons.archive,
            Colors.blue,
            'https://archive.org',
          ),
          const SizedBox(height: 12),
          _buildCreditCard(
            context,
            'YouTube',
            'Video sharing platform providing access to millions of music videos and audio content. All content rights belong to YouTube and respective creators.',
            Icons.play_circle_filled,
            Colors.red,
            'https://www.youtube.com',
          ),
          const SizedBox(height: 12),
          _buildCreditCard(
            context,
            'NewPipe',
            'Open-source YouTube client providing privacy-focused access to YouTube content.',
            Icons.video_library,
            Colors.blue,
            'https://newpipe.net',
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Artist & Label Rights',
            'All music rights belong to the respective artists, composers, lyricists, and record labels. We acknowledge and respect their intellectual property rights. This app is for personal, non-commercial use only.',
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Copyright Disclaimer',
            'AuraMusic does not claim ownership of any music content. All trademarks, service marks, trade names, and copyrights are the property of their respective owners. If you are a rights holder and believe your content is being used improperly, please contact us.',
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Fair Use',
            'This application operates under fair use principles for educational and personal purposes. Users are responsible for ensuring their use complies with local copyright laws.',
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                const Text(
                  'Made with ❤️ and Flutter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'by shrynex',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildCreditCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    String url,
  ) {
    return Card(
      child: InkWell(
        onTap: () async {
          try {
            final uri = Uri.parse(url);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            // Could not launch URL
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
