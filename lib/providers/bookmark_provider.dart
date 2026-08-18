import 'package:flutter/material.dart';
import '../models/creator.dart';
import '../models/post.dart';
import '../services/storage_service.dart';

class BookmarkProvider extends ChangeNotifier {
  final StorageService storageService;

  List<Creator> _favoriteCreators = [];
  List<PostItem> _bookmarkedPosts = [];
  List<PostItem> _recentHistory = [];

  BookmarkProvider({required this.storageService}) {
    _favoriteCreators = storageService.loadFavoriteCreators();
    _bookmarkedPosts = storageService.loadBookmarkedPosts();
    _recentHistory = storageService.loadRecentHistory();
  }

  List<Creator> get favoriteCreators => _favoriteCreators;
  List<PostItem> get bookmarkedPosts => _bookmarkedPosts;
  List<PostItem> get recentHistory => _recentHistory;

  // --- Creator Favorites ---
  bool isCreatorFavorited(String service, String id) {
    return _favoriteCreators.any((c) => c.service == service && c.id == id);
  }

  Future<void> toggleFavoriteCreator(Creator creator) async {
    final index = _favoriteCreators.indexWhere(
      (c) => c.service == creator.service && c.id == creator.id,
    );
    if (index >= 0) {
      _favoriteCreators.removeAt(index);
    } else {
      _favoriteCreators.insert(0, creator);
    }
    await storageService.saveFavoriteCreators(_favoriteCreators);
    notifyListeners();
  }

  // --- Post Bookmarks ---
  bool isPostBookmarked(String service, String id) {
    return _bookmarkedPosts.any((p) => p.service == service && p.id == id);
  }

  Future<void> toggleBookmarkPost(PostItem post) async {
    final index = _bookmarkedPosts.indexWhere(
      (p) => p.service == post.service && p.id == post.id,
    );
    if (index >= 0) {
      _bookmarkedPosts.removeAt(index);
    } else {
      _bookmarkedPosts.insert(0, post);
    }
    await storageService.saveBookmarkedPosts(_bookmarkedPosts);
    notifyListeners();
  }

  // --- History ---
  Future<void> recordVisit(PostItem post) async {
    _recentHistory.removeWhere((p) => p.id == post.id && p.service == post.service);
    _recentHistory.insert(0, post);
    if (_recentHistory.length > 50) {
      _recentHistory = _recentHistory.sublist(0, 50);
    }
    await storageService.addRecentHistory(post);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _recentHistory.clear();
    await storageService.clearRecentHistory();
    notifyListeners();
  }
}
