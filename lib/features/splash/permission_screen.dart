import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/download_service.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_open, size: 80, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'Storage Access',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'AuraMusic needs storage access to:',
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildFeature(Icons.download, 'Download songs to Music/AuraMusic'),
              _buildFeature(Icons.folder, 'Access your downloaded music'),
              _buildFeature(Icons.music_note, 'Play offline music'),
              const SizedBox(height: 32),
              Text(
                'You can always change this in Settings',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => _handleAllow(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Allow Access', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _handleDecline(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Not Now', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAllow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('storage_permission_asked', true);
    
    await DownloadService.requestStoragePermission();
    
    if (context.mounted) {
      context.go('/splash');
    }
  }

  Future<void> _handleDecline(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('storage_permission_asked', true);
    
    if (context.mounted) {
      context.go('/splash');
    }
  }
}
