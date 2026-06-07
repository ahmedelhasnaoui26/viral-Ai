import 'dart:collection';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheService {
  VideoCacheService({this.maxEntries = 20});

  final int maxEntries;
  final _lru = <String, File>{};
  final _cacheManager = DefaultCacheManager();

  Future<File> get(String url) async {
    final cached = _lru.remove(url);
    if (cached != null) {
      _lru[url] = cached;
      return cached;
    }
    final file = await _cacheManager.getSingleFile(url);
    _lru[url] = file;
    if (_lru.length > maxEntries) {
      final oldest = _lru.keys.first;
      _lru.remove(oldest);
    }
    return file;
  }
}
