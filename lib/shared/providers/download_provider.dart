import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadStatus {
  final String songId;
  final String title;
  final double progress;
  final bool isDownloading;
  final String? error;

  DownloadStatus({
    required this.songId,
    required this.title,
    required this.progress,
    required this.isDownloading,
    this.error,
  });
}

final downloadStatusProvider = StateNotifierProvider<DownloadStatusNotifier, Map<String, DownloadStatus>>((ref) {
  return DownloadStatusNotifier();
});

class DownloadStatusNotifier extends StateNotifier<Map<String, DownloadStatus>> {
  DownloadStatusNotifier() : super({});

  void startDownload(String songId, String title) {
    final newState = Map<String, DownloadStatus>.from(state);
    newState[songId] = DownloadStatus(
      songId: songId,
      title: title,
      progress: 0.0,
      isDownloading: true,
    );
    state = newState;
  }

  void updateProgress(String songId, double progress) {
    if (state.containsKey(songId)) {
      final newState = Map<String, DownloadStatus>.from(state);
      newState[songId] = DownloadStatus(
        songId: songId,
        title: state[songId]!.title,
        progress: progress,
        isDownloading: true,
      );
      state = newState;
    }
  }

  void completeDownload(String songId) {
    final newState = Map<String, DownloadStatus>.from(state);
    newState.remove(songId);
    state = newState;
  }

  void failDownload(String songId, String error) {
    if (state.containsKey(songId)) {
      final newState = Map<String, DownloadStatus>.from(state);
      newState[songId] = DownloadStatus(
        songId: songId,
        title: state[songId]!.title,
        progress: 0.0,
        isDownloading: false,
        error: error,
      );
      state = newState;
    }
  }
}