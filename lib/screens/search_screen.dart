import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/creator.dart';
import '../providers/app_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/creator_card.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late TabController _tabController;
  List<String> _searchHistory = [];

  // Post search state
  final List<PostItem> _postResults = [];
  bool _isSearchingPosts = false;
  bool _hasMorePosts = true;
  int _postOffset = 0;
  String? _postError;
  bool _isCloudflare = false;

  // Creator search state
  List<Creator> _creatorResults = [];
  bool _isSearchingCreators = false;

  String _selectedService = 'all';

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
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    final storage = context.read<AppProvider>().storageService;
    setState(() {
      _searchHistory = storage.loadSearchHistory();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400 &&
        !_isSearchingPosts &&
        _hasMorePosts &&
        _tabController.index == 0) {
      _searchPosts(isLoadMore: true);
    }
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final storage = context.read<AppProvider>().storageService;
    await storage.addSearchHistory(q);
    _loadHistory();

    _searchPosts(isRefresh: true);
    _searchCreators();
  }

  Future<void> _searchPosts({bool isRefresh = false, bool isLoadMore = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (isRefresh) {
      _postOffset = 0;
      _hasMorePosts = true;
      _postResults.clear();
      _postError = null;
    }

    setState(() => _isSearchingPosts = true);

    final api = context.read<AppProvider>().apiService;
    final res = await api.searchPosts(
      query,
      offset: _postOffset,
      service: _selectedService == 'all' ? null : _selectedService,
    );

    if (mounted) {
      setState(() {
        _isSearchingPosts = false;
        if (res.isSuccess && res.data != null) {
          final list = res.data!;
          _postResults.addAll(list);
          _postOffset += list.length;
          if (list.length < 25) {
            _hasMorePosts = false;
          }
        } else {
          _postError = res.error ?? '搜索出错';
          _isCloudflare = res.isCloudflareChallenge;
        }
      });
    }
  }

  Future<void> _searchCreators() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearchingCreators = true);

    final api = context.read<AppProvider>().apiService;
    final list = await api.searchLocalCreators(
      query,
      service: _selectedService == 'all' ? null : _selectedService,
    );

    if (mounted) {
      setState(() {
        _isSearchingCreators = false;
        _creatorResults = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDomain = context.watch<AppProvider>().currentBaseUrl;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
          decoration: InputDecoration(
            hintText: '搜索帖子关键词或创作者...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _postResults.clear();
                        _creatorResults.clear();
                      });
                    },
                  )
                : null,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          tabs: [
            Tab(text: '帖子 (${_postResults.length})'),
            Tab(text: '创作者 (${_creatorResults.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Service filter chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
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
                  onSelected: (_) {
                    setState(() => _selectedService = s['id']!);
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
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
          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Post Results Tab
                _buildPostsTab(currentDomain, isDark),
                // Creators Results Tab
                _buildCreatorsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(String currentDomain, bool isDark) {
    if (_searchController.text.isEmpty && _postResults.isEmpty) {
      return _buildSearchHistorySection();
    }

    if (_isSearchingPosts && _postResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_postError != null && _postResults.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: '搜索帖子失败',
        description: _postError!,
        isCloudflare: _isCloudflare,
        directUrl: currentDomain,
        onRetry: () => _searchPosts(isRefresh: true),
      );
    }

    if (_postResults.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: '未找到相关帖子',
        description: '尝试使用更短的关键词或切换搜索平台分类',
        onRetry: () => _performSearch(_searchController.text),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _searchPosts(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _postResults.length + (_hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _postResults.length) {
            return PostCard(post: _postResults[index]);
          } else {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
        },
      ),
    );
  }

  Widget _buildCreatorsTab(bool isDark) {
    if (_searchController.text.isEmpty && _creatorResults.isEmpty) {
      return _buildSearchHistorySection();
    }

    if (_isSearchingCreators) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_creatorResults.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.person_off_rounded,
        title: '未找到匹配的创作者',
        description: '请检查拼写或尝试在全部平台下搜索',
        onRetry: () => _performSearch(_searchController.text),
      );
    }

    return ListView.builder(
      itemCount: _creatorResults.length,
      itemBuilder: (context, index) {
        return CreatorCard(creator: _creatorResults[index]);
      },
    );
  }

  Widget _buildSearchHistorySection() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('输入关键词开始搜索帖子或作者', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '搜索历史',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              TextButton(
                onPressed: () async {
                  final storage = context.read<AppProvider>().storageService;
                  await storage.clearSearchHistory();
                  _loadHistory();
                },
                child: const Text('清空历史', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((query) {
              return ActionChip(
                label: Text(query),
                avatar: const Icon(Icons.history, size: 16),
                onPressed: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
