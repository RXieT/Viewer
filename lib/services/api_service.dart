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

  static const Map<String, String> defaultHttpHeaders = {
    'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Referer': 'https://kemono.cr/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
  };

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
    _cachedCreators = null;
    _creatorsCacheTime = null;
  }

  String get baseUrl => _baseUrl;

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

  /// Test connectivity to the given domain
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

  /// Get list of creators (with automatic fallback to extracting from recent post streams)
  Future<ApiResponse<List<Creator>>> getCreators({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedCreators != null &&
        _cachedCreators!.isNotEmpty &&
        _creatorsCacheTime != null &&
        DateTime.now().difference(_creatorsCacheTime!) < const Duration(minutes: 15)) {
      return ApiResponse(data: _cachedCreators);
    }

    try {
      // 1. Try official creators endpoint
      final response = await _dio.get('$_baseUrl/api/v1/creators');
      if (response.statusCode == 200) {
        final List<dynamic> raw = _extractList(response.data);
        final creators = raw
            .whereType<Map<String, dynamic>>()
            .map((item) => Creator.fromJson(item))
            .toList();

        if (creators.isNotEmpty) {
          _cachedCreators = creators;
          _creatorsCacheTime = DateTime.now();
          return ApiResponse(data: creators, statusCode: 200);
        }
      }
    } catch (_) {}

    // 2. Fallback: Automatically extract active creators from recent posts
    try {
      final postsRes1 = await _dio.get('$_baseUrl/api/v1/posts?o=0');
      final List<dynamic> raw1 = _extractList(postsRes1.data);
      
      final Map<String, Creator> map = {};
      for (var item in raw1) {
        if (item is Map<String, dynamic>) {
          final user = item['user']?.toString() ?? '';
          final service = item['service']?.toString() ?? '';
          final name = item['user_name']?.toString() ?? item['username']?.toString() ?? user;
          if (user.isNotEmpty && service.isNotEmpty) {
            final key = '$service:$user';
            map[key] = Creator(
              id: user,
              name: name,
              service: service,
            );
          }
        }
      }

      final discovered = map.values.toList();
      _cachedCreators = discovered;
      _creatorsCacheTime = DateTime.now();
      return ApiResponse(data: discovered, statusCode: 200);
    } catch (e) {
      if (_cachedCreators != null && _cachedCreators!.isNotEmpty) {
        return ApiResponse(data: _cachedCreators, statusCode: 200);
      }
      return ApiResponse(error: '获取创作者失败: $e');
    }
  }

  /// Get recent posts feed with accurate service filtering
  Future<ApiResponse<List<PostItem>>> getRecentPosts({
    int offset = 0,
    String? service,
  }) async {
    try {
      final targetService = (service != null && service.isNotEmpty && service != 'all')
          ? service.toLowerCase()
          : null;

      final List<PostItem> resultList = [];
      int currentOffset = offset;
      int fetchRounds = 0;
      final maxRounds = targetService != null ? 5 : 1;

      while (fetchRounds < maxRounds) {
        fetchRounds++;
        final String path = '$_baseUrl/api/v1/posts?o=$currentOffset';
        final response = await _dio.get(path);

        if (response.statusCode == 200) {
          final List<dynamic> raw = _extractList(response.data);
          final posts = raw
              .whereType<Map<String, dynamic>>()
              .map((item) => PostItem.fromJson(item))
              .toList();

          _recordCreatorsFromPosts(posts);

          if (targetService != null) {
            final matched = posts.where((p) => p.service.toLowerCase() == targetService).toList();
            resultList.addAll(matched);
            currentOffset += posts.length;

            if (resultList.length >= 20 || posts.length < 25) {
              break;
            }
          } else {
            resultList.addAll(posts);
            break;
          }
        } else if (response.statusCode == 403 || response.statusCode == 503) {
          return ApiResponse(
            error: '受到防护拦截，请尝试切换镜像或使用内置网页',
            isCloudflareChallenge: true,
            statusCode: response.statusCode,
          );
        } else {
          break;
        }
      }

      return ApiResponse(data: resultList, statusCode: 200);
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
      String path = '$_baseUrl/api/v1/posts?service=$service&user=$userId&o=$offset';
      var response = await _dio.get(path);

      if (response.statusCode == 404 || response.statusCode == 403) {
        path = '$_baseUrl/api/v1/$service/user/$userId/posts?o=$offset';
        response = await _dio.get(path);
      }

      if (response.statusCode == 200) {
        final List<dynamic> raw = _extractList(response.data);
        final posts = raw
            .whereType<Map<String, dynamic>>()
            .map((item) => PostItem.fromJson(item))
            .toList();
        _recordCreatorsFromPosts(posts);
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

  /// Search posts by keyword or tag with service filter
  Future<ApiResponse<List<PostItem>>> searchPosts(
    String query, {
    int offset = 0,
    String? service,
    bool isTag = false,
  }) async {
    try {
      final targetService = (service != null && service.isNotEmpty && service != 'all')
          ? service.toLowerCase()
          : null;

      String encoded = Uri.encodeComponent(query.trim());
      String param = isTag ? 'tag' : 'q';
      String path = '$_baseUrl/api/v1/posts?$param=$encoded&o=$offset';

      final response = await _dio.get(path);
      if (response.statusCode == 200) {
        final List<dynamic> raw = _extractList(response.data);
        var posts = raw
            .whereType<Map<String, dynamic>>()
            .map((item) => PostItem.fromJson(item))
            .toList();

        _recordCreatorsFromPosts(posts);

        if (targetService != null) {
          posts = posts.where((p) => p.service.toLowerCase() == targetService).toList();
        }

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

  /// Search creators in locally cached list
  Future<List<Creator>> searchLocalCreators(String query, {String? service}) async {
    if (_cachedCreators == null || _cachedCreators!.isEmpty) {
      await getCreators();
    }

    if (_cachedCreators == null) return [];

    final q = query.trim().toLowerCase();
    return _cachedCreators!.where((c) {
      final matchName = q.isEmpty || c.name.toLowerCase().contains(q) || c.id.toLowerCase().contains(q);
      final matchService = (service == null || service.isEmpty || service == 'all') ||
          c.service.toLowerCase() == service.toLowerCase();
      return matchName && matchService;
    }).toList();
  }

  void _recordCreatorsFromPosts(List<PostItem> posts) {
    _cachedCreators ??= [];
    final existingKeys = {for (var c in _cachedCreators!) '${c.service}:${c.id}'};

    for (var p in posts) {
      final key = '${p.service}:${p.user}';
      if (!existingKeys.contains(key) && p.user.isNotEmpty && p.service.isNotEmpty) {
        final newCreator = Creator(
          id: p.user,
          name: p.userName ?? '创作者 ${p.user}',
          service: p.service,
        );
        _cachedCreators!.add(newCreator);
        existingKeys.add(key);
      }
    }
  }
}
