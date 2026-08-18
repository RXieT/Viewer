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
    }
    _setupDio();
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36 KemonoViewer/1.0',
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
    _dio.options.baseUrl = _baseUrl;
    // Clear creator cache on domain switch
    _cachedCreators = null;
    _creatorsCacheTime = null;
  }

  String get baseUrl => _baseUrl;

  /// Test connectivity to the given domain or current base URL
  Future<ApiResponse<bool>> testConnection([String? testUrl]) async {
    final target = testUrl ?? _baseUrl;
    try {
      final dioTest = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: _dio.options.headers,
      ));
      
      final response = await dioTest.get('$target/api/v1/creators');
      if (response.statusCode == 200) {
        return ApiResponse(data: true, statusCode: 200);
      } else if (response.statusCode == 403 || response.statusCode == 503) {
        return ApiResponse(
          data: false,
          error: '触发 Cloudflare 防护或受限 (${response.statusCode})',
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
        final List<dynamic> raw = (response.data is String)
            ? jsonDecode(response.data as String)
            : response.data;

        final creators = raw.map((item) => Creator.fromJson(item as Map<String, dynamic>)).toList();
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
        final List<dynamic> raw = (response.data is String)
            ? jsonDecode(response.data as String)
            : response.data;

        final posts = raw.map((item) => PostItem.fromJson(item as Map<String, dynamic>)).toList();
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
      // Endpoint format: /api/v1/{service}/user/{userId}/posts?o={offset} or /api/v1/{service}/user/{userId}?o={offset}
      String path = '$_baseUrl/api/v1/$service/user/$userId/posts?o=$offset';
      var response = await _dio.get(path);

      if (response.statusCode == 404) {
        // Fallback to legacy endpoint if /posts is not supported
        path = '$_baseUrl/api/v1/$service/user/$userId?o=$offset';
        response = await _dio.get(path);
      }

      if (response.statusCode == 200) {
        final List<dynamic> raw = (response.data is String)
            ? jsonDecode(response.data as String)
            : response.data;

        final posts = raw.map((item) => PostItem.fromJson(item as Map<String, dynamic>)).toList();
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
      final path = '$_baseUrl/api/v1/$service/user/$userId/post/$postId';
      final response = await _dio.get(path);

      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        if (response.data is List && (response.data as List).isNotEmpty) {
          data = (response.data as List).first as Map<String, dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          final decoded = jsonDecode(response.data as String);
          data = (decoded is List) ? decoded.first : decoded;
        } else {
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

  /// Search posts by keyword
  Future<ApiResponse<List<PostItem>>> searchPosts(
    String query, {
    int offset = 0,
    String? service,
  }) async {
    try {
      String encoded = Uri.encodeComponent(query.trim());
      String path = '$_baseUrl/api/v1/posts?q=$encoded&o=$offset';
      if (service != null && service.isNotEmpty && service != 'all') {
        path += '&service=$service';
      }

      final response = await _dio.get(path);
      if (response.statusCode == 200) {
        final List<dynamic> raw = (response.data is String)
            ? jsonDecode(response.data as String)
            : response.data;

        final posts = raw.map((item) => PostItem.fromJson(item as Map<String, dynamic>)).toList();
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
