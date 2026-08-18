import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/creator.dart';
import '../models/post.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isCloudflareChallenge;
  final int? statusCode;

  ApiResponse({
    this.data,
    this.error,
    this.isCloudflareChallenge = false,
    this.statusCode,
  });

  bool get isSuccess => error == null && data != null;
}

class ApiService {
  final Dio _dio = Dio();
  String _baseUrl = 'https://kemono.cr';

  // In-memory creator cache to avoid repeatedly fetching thousands of creators
  List<Creator>? _cachedCreators;
  DateTime? _creatorsCacheTime;

  ApiService({String? baseUrl}) {
    if (baseUrl != null && baseUrl.isNotEmpty) {
      setBaseUrl(baseUrl);
    } else {
      _setupDio();
    }
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Referer': '$_baseUrl/',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
      },
      validateStatus: (status) => status != null && status < 500,
    );
  }

  void setBaseUrl(String baseUrl) {
    var url = baseUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    _baseUrl = url;
    _setupDio();
    // Clear creator cache on domain switch
    _cachedCreators = null;
    _creatorsCacheTime = null;
  }

  String get baseUrl => _baseUrl;

  /// Helper to safely extract list from any Kemono response format (List, Map with posts/results/data, or JSON String)
  List<dynamic> _extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      if (data['posts'] is List) return data['posts'] as List<dynamic>;
      if (data['results'] is List) return data['results'] as List<dynamic>;
      if (data['data'] is List) return data['data'] as List<dynamic>;
      if (data['creators'] is List) return data['creators'] as List<dynamic>;
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return _extractList(decoded);
      } catch (_) {}
    }
    return [];
  }

  /// Test connectivity to the given domain or current base URL
  Future<ApiResponse<bool>> testConnection([String? testUrl]) async {
    final target = testUrl ?? _baseUrl;
    try {
      final dioTest = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Referer': '$target/',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
        },
        validateStatus: (s) => s != null && s < 500,
      ));

      // Test /api/v1/posts which is the main public data endpoint
      final response = await dioTest.get('$target/api/v1/posts?o=0');
      if (response.statusCode == 200) {
        return ApiResponse(data: true, statusCode: 200);
      } else if (response.statusCode == 403 || response.statusCode == 503) {
        return ApiResponse(
          data: false,
          error: '触发防护拦截或需要验证 (${response.statusCode})',
          isCloudflareChallenge: true,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          data: false,
          error: '返回状态码: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(data: false, error: '连接失败: $e');
    }
  }

  /// Get list of all creators (cached for 15 mins to save bandwidth)
  Future<ApiResponse<List<Creator>>> getCreators({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedCreators != null &&
        _creatorsCacheTime != null &&
        DateTime.now().difference(_creatorsCacheTime!) < const Duration(minutes: 15)) {
      return ApiResponse(data: _cachedCreators);
    }

    try {
      final response = await _dio.get('$_baseUrl/api/v1/creators');
      if (response.statusCode == 200) {
        final List<dynamic> raw = _extractList(response.data);
        final creators = raw
            .whereType<Map<String, dynamic>>()
            .map((item) => Creator.fromJson(item))
            .toList();
        _cachedCreators = creators;
        _creatorsCacheTime = DateTime.now();
        return ApiResponse(data: creators, statusCode: 200);
      } else if (response.statusCode == 403 || response.statusCode == 503) {
        return ApiResponse(
          error: '访问受限，可能需要过验证码',
          isCloudflareChallenge: true,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          error: '获取创作者列表失败: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(error: '网络请求错误: $e');
    }
  }

  /// Get recent posts feed
  Future<ApiResponse<List<PostItem>>> getRecentPosts({
    int offset = 0,
    String? service,
  }) async {
    try {
      String path = '$_baseUrl/api/v1/posts?o=$offset';
      if (service != null && service.isNotEmpty && service != 'all') {
        path += '&service=$service';
      }

      final response = await _dio.get(path);
      if (response.statusCode == 200) {
        final List<dynamic> raw = _extractList(response.data);
        final posts = raw
            .whereType<Map<String, dynamic>>()
            .map((item) => PostItem.fromJson(item))
            .toList();
        _attachCreatorNames(posts);
        return ApiResponse(data: posts, statusCode: 200);
      } else if (response.statusCode == 403 || response.statusCode == 503) {
        return ApiResponse(
          error: '受到防护拦截，请尝试切换镜像或使用内置网页',
          isCloudflareChallenge: true,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          error: '获取帖子列表失败: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(error: '加载帖子错误: $e');
    }
  }

  /// Get posts by a specific creator
  Future<ApiResponse<List<PostItem>>> getCreatorPosts(
    String service,
    String userId, {
    int offset = 0,
  }) async {
    try {
      // Primary: query via /api/v1/posts?service=...&user=...
      String path = '$_baseUrl/api/v1/posts?service=$service&user=$userId&o=$offset';
      var response = await _dio.get(path);

      if (response.statusCode == 404 || response.statusCode == 403) {
        // Fallback: /api/v1/{service}/user/{userId}/posts
        path = '$_baseUrl/api/v1/$service/user/$userId/posts?o=$offset';
        response = await _dio.get(path);
      }

      if (response.statusCode == 200) {
        final List<dynamic> raw = _extractList(response.data);
        final posts = raw
            .whereType<Map<String, dynamic>>()
            .map((item) => PostItem.fromJson(item))
            .toList();
        _attachCreatorNames(posts);
        return ApiResponse(data: posts, statusCode: 200);
      } else if (response.statusCode == 403 || response.statusCode == 503) {
        return ApiResponse(
          error: '访问受限，请尝试切换域名',
          isCloudflareChallenge: true,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          error: '获取创作者帖子失败: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(error: '加载创作者帖子错误: $e');
    }
  }

  /// Get specific post details
  Future<ApiResponse<PostItem>> getPostDetail(
    String service,
    String userId,
    String postId,
  ) async {
    try {
      // First try posts endpoint with post id filter or direct detail
      String path = '$_baseUrl/api/v1/$service/user/$userId/post/$postId';
      var response = await _dio.get(path);

      if (response.statusCode == 404 || response.statusCode == 403) {
        path = '$_baseUrl/api/v1/posts?service=$service&user=$userId&id=$postId';
        response = await _dio.get(path);
      }

      if (response.statusCode == 200) {
        Map<String, dynamic>? data;
        final rawList = _extractList(response.data);
        if (rawList.isNotEmpty && rawList.first is Map<String, dynamic>) {
          data = rawList.first as Map<String, dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        }

        if (data == null) {
          return ApiResponse(error: '数据格式解析异常');
        }

        final post = PostItem.fromJson(data);
        _attachCreatorNames([post]);
        return ApiResponse(data: post, statusCode: 200);
      } else {
        return ApiResponse(
          error: '获取帖子详情失败: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(error: '加载帖子详情错误: $e');
    }
  }

  /// Search posts by keyword or tag
  Future<ApiResponse<List<PostItem>>> searchPosts(
    String query, {
    int offset = 0,
    String? service,
    bool isTag = false,
  }) async {
    try {
      String encoded = Uri.encodeComponent(query.trim());
      String param = isTag ? 'tag' : 'q';
      String path = '$_baseUrl/api/v1/posts?$param=$encoded&o=$offset';
      if (service != null && service.isNotEmpty && service != 'all') {
        path += '&service=$service';
      }

      final response = await _dio.get(path);
      if (response.statusCode == 200) {
        final List<dynamic> raw = _extractList(response.data);
        final posts = raw
            .whereType<Map<String, dynamic>>()
            .map((item) => PostItem.fromJson(item))
            .toList();
        _attachCreatorNames(posts);
        return ApiResponse(data: posts, statusCode: 200);
      } else {
        return ApiResponse(
          error: '搜索帖子失败: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(error: '搜索请求异常: $e');
    }
  }

  /// Search creators in locally cached list (super fast & zero extra traffic)
  Future<List<Creator>> searchLocalCreators(String query, {String? service}) async {
    if (_cachedCreators == null) {
      final res = await getCreators();
      if (!res.isSuccess || res.data == null) return [];
    }

    final q = query.trim().toLowerCase();
    return _cachedCreators!.where((c) {
      final matchName = q.isEmpty || c.name.toLowerCase().contains(q) || c.id.toLowerCase().contains(q);
      final matchService = (service == null || service.isEmpty || service == 'all') ||
          c.service.toLowerCase() == service.toLowerCase();
      return matchName && matchService;
    }).toList();
  }

  void _attachCreatorNames(List<PostItem> posts) {
    if (_cachedCreators == null) return;
    final map = {for (var c in _cachedCreators!) '${c.service}:${c.id}': c.name};
    for (var p in posts) {
      final key = '${p.service}:${p.user}';
      if (map.containsKey(key)) {
        p.userName = map[key];
      }
    }
  }
}
