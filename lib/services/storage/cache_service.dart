import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheService {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  Future<void> cacheFile(String url) async {
    await _cacheManager.downloadFile(url);
  }

  Future<void> emptyCache() async {
    await _cacheManager.emptyCache();
  }

  Future<File> getFile(String url) async {
    return _cacheManager.getSingleFile(url);
  }
}
