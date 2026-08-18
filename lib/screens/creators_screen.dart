import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/creator.dart';
import '../providers/app_provider.dart';
import '../widgets/creator_card.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';

class CreatorsScreen extends StatefulWidget {
  const CreatorsScreen({super.key});

  @override
  State<CreatorsScreen> createState() => _CreatorsScreenState();
}

class _CreatorsScreenState extends State<CreatorsScreen> {
  List<Creator> _allCreators = [];
  List<Creator> _filteredCreators = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCloudflare = false;

  final TextEditingController _searchController = TextEditingController();
  String _selectedService = 'all';
  String _sortBy = 'favorited'; // 'favorited', 'name', 'updated'

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
    _loadCreators();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCreators({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final api = context.read<AppProvider>().apiService;
    final res = await api.getCreators(forceRefresh: forceRefresh);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess && res.data != null) {
          _allCreators = res.data!;
          _applyFilters();
        } else {
          _errorMessage = res.error ?? '加载创作者列表失败';
          _isCloudflare = res.isCloudflareChallenge;
        }
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    var list = _allCreators.where((c) {
      final matchQuery = query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.id.toLowerCase().contains(query);
      final matchService = _selectedService == 'all' ||
          c.service.toLowerCase() == _selectedService.toLowerCase();
      return matchQuery && matchService;
    }).toList();

    // Sort
    if (_sortBy == 'favorited') {
      list.sort((a, b) => b.favorited.compareTo(a.favorited));
    } else if (_sortBy == 'name') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'updated') {
      list.sort((a, b) => (b.updated ?? '').compareTo(a.updated ?? ''));
    }

    setState(() {
      _filteredCreators = list;
    });
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
            const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('创作者库 (${_filteredCreators.length})'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: '排序方式',
            onSelected: (val) {
              setState(() => _sortBy = val);
              _applyFilters();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'favorited',
                child: Row(
                  children: [
                    Icon(Icons.favorite, size: 18, color: _sortBy == 'favorited' ? AppColors.primary : null),
                    const SizedBox(width: 8),
                    const Text('按关注/热度排序'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 18, color: _sortBy == 'name' ? AppColors.primary : null),
                    const SizedBox(width: 8),
                    const Text('按作者名称排序'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'updated',
                child: Row(
                  children: [
                    Icon(Icons.update, size: 18, color: _sortBy == 'updated' ? AppColors.primary : null),
                    const SizedBox(width: 8),
                    const Text('按最近更新排序'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Input Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索创作者名称或 ID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
              ),
              // Horizontal Service Filter Chips
              SizedBox(
                height: 40,
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
                        _applyFilters();
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
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadCreators(forceRefresh: true),
        child: _buildBody(currentDomain, isDark),
      ),
    );
  }

  Widget _buildBody(String currentDomain, bool isDark) {
    if (_isLoading && _allCreators.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载创作者索引...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null && _allCreators.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline,
        title: '获取创作者失败',
        description: _errorMessage!,
        isCloudflare: _isCloudflare,
        directUrl: '$currentDomain/artists',
        onRetry: () => _loadCreators(forceRefresh: true),
      );
    }

    if (_filteredCreators.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: '未找到匹配的创作者',
        description: '请尝试更换搜索关键词或切换平台分类',
        onRetry: () {
          _searchController.clear();
          setState(() => _selectedService = 'all');
          _applyFilters();
        },
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filteredCreators.length,
      itemBuilder: (context, index) {
        return CreatorCard(creator: _filteredCreators[index]);
      },
    );
  }
}
