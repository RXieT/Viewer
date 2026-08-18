import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/tag_info.dart';

class TagService {
  static final TagService _instance = TagService._internal();
  factory TagService() => _instance;
  TagService._internal();

  final Map<String, TagInfo> _tagMap = {};
  final List<TagInfo> _tagList = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<TagInfo> get allTags => _tagList;

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/tags_dictionary.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data['tags'] is List) {
        for (var item in data['tags']) {
          if (item is Map<String, dynamic>) {
            final tagInfo = TagInfo.fromJson(item);
            _tagList.add(tagInfo);
            _tagMap[tagInfo.tag.toLowerCase()] = tagInfo;
          }
        }
      }
      _isLoaded = true;
    } catch (e) {
      // Fallback if loading fails
      _isLoaded = true;
    }
  }

  /// Translate a raw tag string to Chinese. If no match found, returns original tag.
  String translate(String rawTag) {
    final clean = rawTag.trim().toLowerCase();
    if (_tagMap.containsKey(clean)) {
      return _tagMap[clean]!.translation;
    }
    return rawTag;
  }

  /// Get bilingual display: "tag | 中文"
  String getBilingual(String rawTag) {
    final clean = rawTag.trim().toLowerCase();
    if (_tagMap.containsKey(clean)) {
      return _tagMap[clean]!.bilingual;
    }
    return rawTag;
  }

  /// Get full TagInfo model
  TagInfo getTagInfo(String rawTag) {
    final clean = rawTag.trim().toLowerCase();
    if (_tagMap.containsKey(clean)) {
      return _tagMap[clean]!;
    }
    return TagInfo(
      tag: rawTag,
      translation: rawTag,
      namespace: 'other',
    );
  }

  /// Search tags by keyword (supports both English and Chinese matching)
  List<TagInfo> searchTags(String query, {String? namespace, int limit = 50}) {
    final q = query.trim().toLowerCase();
    final ns = namespace?.toLowerCase();

    return _tagList.where((t) {
      final matchNs = (ns == null || ns == 'all') || t.namespace.toLowerCase() == ns;
      if (!matchNs) return false;
      if (q.isEmpty) return true;

      return t.tag.toLowerCase().contains(q) ||
          t.translation.toLowerCase().contains(q) ||
          t.bilingual.toLowerCase().contains(q);
    }).take(limit).toList();
  }

  /// Get tags belonging to a specific EhViewer namespace
  List<TagInfo> getTagsByNamespace(String ns, {int limit = 100}) {
    if (ns.toLowerCase() == 'all') {
      return _tagList.take(limit).toList();
    }
    return _tagList
        .where((t) => t.namespace.toLowerCase() == ns.toLowerCase())
        .take(limit)
        .toList();
  }
}
