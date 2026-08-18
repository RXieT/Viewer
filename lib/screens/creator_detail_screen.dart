import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/creator.dart';
import '../models/post.dart';
import '../providers/app_provider.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/service_badge.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/empty_state.dart';
import 'webview_screen.dart';

class CreatorDetailScreen extends StatefulWidget {
  final Creator creator;

  const CreatorDetailScreen({super.key, required this.creator});

  @override
  State<CreatorDetailScreen> createState() => _CreatorDetailScreenState();
}

class _CreatorDetailScreenState extends State<CreatorDetailScreen> {
  final List<PostItem> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  bool _isCloudflare = false;
  int _offset = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPosts(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400 &&
        !_isLoading &&
        _hasMore &&
        _filterQuery.isEmpty) {
      _loadPosts();
    }
  }

  Future<void> _loadPosts({bool isRefresh = false}) async {
    if (_isLoading) return;
    if (isRefresh) {
      _offset = 0;
      _hasMore = true;
      _posts.clear();
      _errorMessage = null;
    }

    setState(() => _isLoading = true);

    final api = context.read<AppProvider>().apiService;
    final res = await api.getCreatorPosts(
      widget.creator.service,
      widget.creator.id,
      offset: _offset,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess && res.data != null) {
          final newPosts = res.data!;
          for (var p in newPosts) {
            p.userName = widget.creator.name;
          }
          _posts.addAll(newPosts);
          _offset += newPosts.length;
          if (newPosts.length < 25) {
            _hasMore = false;
          }
        } else {
          _errorMessage = res.error ?? '加载失败';
          _isCloudflare = res.isCloudflareChallenge;
        }
      });
    }
  }

  List<PostItem> get _filteredPosts {
    if (_filterQuery.isEmpty) return _posts;
    final q = _filterQuery.toLowerCase();
    return _posts.where((p) => p.title.toLowerCase().contains(q) || p.content.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = context.watch<AppProvider>().currentBaseUrl;
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final isFavorited = bookmarkProvider.isCreatorFavorited(widget.creator.service, widget.creator.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarUrl = widget.creator.getAvatarUrl(baseUrl);
    final webUrl = widget.creator.getWebUrl(baseUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.creator.name),
        actions: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorited ? Colors.pink : null,
            ),
            tooltip: isFavorited ? '取消关注' : '关注作者',
            onPressed: () {
              bookmarkProvider.toggleFavoriteCreator(widget.creator);
            },
          ),
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: '在内置网页查看',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WebViewScreen(
                    initialUrl: webUrl,
                    title: widget.creator.name,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPosts(isRefresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Creator Header Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F222B) : const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2F3B) : const Color(0xFFE2E6EE),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: isDark ? const Color(0xFF323642) : const Color(0xFFE0E0E0),
                          backgroundImage: CachedNetworkImageProvider(avatarUrl),
                          onBackgroundImageError: (_, __) {},
                          child: Text(
                            widget.creator.name.isNotEmpty ? widget.creator.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.creator.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ServiceBadge(service: widget.creator.service),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ID: ${widget.creator.id}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Quick Search Filter within creator's posts
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '在作者的帖子中筛选...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _filterQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _filterQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onChanged: (val) {
                        setState(() => _filterQuery = val.trim());
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Posts List
            if (_posts.isEmpty && _isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: SkeletonLoadingList(count: 4),
                ),
              )
            else if (_posts.isEmpty && _errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: '加载作者帖子失败',
                  description: _errorMessage!,
                  isCloudflare: _isCloudflare,
                  directUrl: webUrl,
                  onRetry: () => _loadPosts(isRefresh: true),
                ),
              )
            else if (_filteredPosts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icon: Icons.inbox_outlined,
                  title: '暂无匹配的帖子',
                  description: _filterQuery.isNotEmpty ? '没有找到包含“$_filterQuery”的帖子' : '该创作者尚未发布或同步帖子',
                  onRetry: () => _loadPosts(isRefresh: true),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _filteredPosts.length) {
                      return PostCard(post: _filteredPosts[index]);
                    } else if (_hasMore && _filterQuery.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            '—— 已加载全部帖子 ——',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  childCount: _filteredPosts.length + (_hasMore && _filterQuery.isEmpty ? 1 : (_posts.isNotEmpty ? 1 : 0)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
