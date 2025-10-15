import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/database_service.dart';
import '../models/song.dart';

final databaseServiceProvider = Provider((ref) => _DatabaseServiceWrapper());

class _DatabaseServiceWrapper {
  Future<void> saveSong(song) => DatabaseService.saveSong(song);
  Future<Song?> getSong(String id) => DatabaseService.getSong(id);
}
