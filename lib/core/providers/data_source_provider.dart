import 'package:flutter/foundation.dart';
import '../data_sources/music_data_source.dart';
import '../data_sources/newpipe_data_source.dart';

class DataSourceProvider extends ChangeNotifier {
  late MusicDataSource _activeDataSource;

  DataSourceProvider() {
    _activeDataSource = NewPipeDataSource();
  }

  MusicDataSource get activeDataSource => _activeDataSource;
}
