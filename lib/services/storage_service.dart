import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/creator.dart';
import '../models/post.dart';

class StorageService {
  static const String _keySettings = 'app_settings_v1';
  static const String _keyFavoriteCreators = 'favorite_creators_v1';
  static const String _keyBookmarkedPosts = 'bookmarked_posts_v1';
  static const String _keySearchHistory = 'search_history_v1';
  static const String _keyRecentHistory = 'recent_history_v1';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Settings ---
  AppSettings loadSettings() {
    final raw = _prefs.getString(_keySettings);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return AppSettings.fromJson(map);
      } catch (_) {}
    }
    return AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final raw = jsonEncode(settings.toJson());
    await _prefs.setString(_keySettings, raw);
  }

  // --- Favorite Creators ---
  List<Creator> loadFavoriteCreators() {
    final raw = _prefs.getString(_keyFavoriteCreators);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        return list.map((e) => Creator.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveFavoriteCreators(List<Creator> creators) async {
    final raw = jsonEncode(creators.map((c) => c.toJson()).toList());
    await _prefs.setString(_keyFavoriteCreators, raw);
  }

  // --- Bookmarked Posts ---
  List<PostItem> loadBookmarkedPosts() {
    final raw = _prefs.getString(_keyBookmarkedPosts);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        return list.map((e) => PostItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveBookmarkedPosts(List<PostItem> posts) async {
    final raw = jsonEncode(posts.map((p) => p.toJson()).toList());
    await _prefs.setString(_keyBookmarkedPosts, raw);
  }

  // --- Search History ---
  List<String> loadSearchHistory() {
    return _prefs.getStringList(_keySearchHistory) ?? [];
  }

  Future<void> addSearchHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    var list = loadSearchHistory();
    list.remove(q);
    list.insert(0, q);
    if (list.length > 30) {
      list = list.sublist(0, 30);
    }
    await _prefs.setStringList(_keySearchHistory, list);
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(_keySearchHistory);
  }

  // --- Recent Browsing History ---
  List<PostItem> loadRecentHistory() {
    final raw = _prefs.getString(_keyRecentHistory);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        return list.map((e) => PostItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> addRecentHistory(PostItem post) async {
    var list = loadRecentHistory();
    list.removeWhere((p) => p.id == post.id && p.service == post.service);
    list.insert(0, post);
    if (list.length > 50) {
      list = list.sublist(0, 50);
    }
    final raw = jsonEncode(list.map((p) => p.toJson()).toList());
    await _prefs.setString(_keyRecentHistory, raw);
  }

  Future<void> clearRecentHistory() async {
    await _prefs.remove(_keyRecentHistory);
  }
}
