import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/app_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<PostItem> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  bool _isCloudflare = false;
  int _serverOffset = 0;
  String _selectedService = 'all';

  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _services = [
    {'id': 'all', 'name': '全部'},
    {'id': 'fanbox', 'name': 'Fanbox'},
    {'id': 'patreon', 'name': 'Patreon'},
    {'id': 'fantia', 'name': 'Fantia'},
    {'id': 'boosty', 'name': 'Boosty'},
    {'id': 'gumroad', 'name': 'Gumroad'},
    {'id': 'discord', 'name': 'Discord'},
    {'id': 'subscribestar', 'name': 'SubscribeStar'},
    {'id': 'afdian', 'name': '爱发电'},
    {'id': 'candfans', 'name': 'CandFans'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400 &&
        !_isLoading &&
        _hasMore) {
      _loadPosts();
    }
  }

  Future<void> _loadPosts({bool isRefresh = false}) async {
    if (_isLoading) return;
    if (isRefresh) {
      _serverOffset = 0;
      _hasMore = true;
      _posts.clear();
      _errorMessage = null;
    }

    setState(() => _isLoading = true);

    final api = context.read<AppProvider>().apiService;
    final res = await api.getRecentPosts(
      offset: _serverOffset,
      service: _selectedService == 'all' ? null : _selectedService,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess && res.data != null) {
          final newPosts = res.data!;
          _posts.addAll(newPosts);
          _serverOffset += 50;
          if (newPosts.isEmpty && _posts.isNotEmpty) {
            _hasMore = false;
          }
        } else {
          _errorMessage = res.error ?? '加载失败';
          _isCloudflare = res.isCloudflareChallenge;
        }
      });
    }
  }

  void _onServiceSelected(String serviceId) {
    if (_selectedService == serviceId) return;
    setState(() {
      _selectedService = serviceId;
    });
    _loadPosts(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final currentDomain = context.watch<AppProvider>().currentBaseUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dynamic_feed_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('最新更新 (Feed)'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _services.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final s = _services[index];
                final isSelected = _selectedService == s['id'];
                return ChoiceChip(
                  label: Text(s['name']!),
                  selected: isSelected,
                  onSelected: (_) => _onServiceSelected(s['id']!),
                  showCheckmark: false,
                  selectedColor: AppColors.primary.withOpacity(0.25),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPosts(isRefresh: true),
        child: _buildBody(currentDomain, isDark),
      ),
    );
  }

  Widget _buildBody(String currentDomain, bool isDark) {
    if (_posts.isEmpty && _isLoading) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: SkeletonLoadingList(count: 6),
        ),
      );
    }

    if (_posts.isEmpty && _errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: EmptyStateWidget(
            icon: Icons.wifi_off_rounded,
            title: '加载动态失败',
            description: _errorMessage!,
            isCloudflare: _isCloudflare,
            directUrl: currentDomain,
            onRetry: () => _loadPosts(isRefresh: true),
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: EmptyStateWidget(
            icon: Icons.inbox_rounded,
            title: '暂无更新动态',
            description: '当前分类下没有发现最近发布的帖子',
            onRetry: () => _loadPosts(isRefresh: true),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _posts.length + (_hasMore ? 1 : 1),
      itemBuilder: (context, index) {
        if (index < _posts.length) {
          return PostCard(post: _posts[index]);
        } else if (_hasMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                '—— 已到达列表末尾 ——',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
