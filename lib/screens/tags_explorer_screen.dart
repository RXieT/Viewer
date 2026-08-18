import 'package:flutter/material.dart';
import '../models/tag_info.dart';
import '../services/tag_service.dart';
import '../widgets/tag_chip.dart';
import 'search_screen.dart';

class TagsExplorerScreen extends StatefulWidget {
  const TagsExplorerScreen({super.key});

  @override
  State<TagsExplorerScreen> createState() => _TagsExplorerScreenState();
}

class _TagsExplorerScreenState extends State<TagsExplorerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TagService _tagService = TagService();

  final List<Map<String, String>> _namespaces = [
    {'id': 'all', 'name': '🔥 热门全部'},
    {'id': 'parody', 'name': '🎨 原作/IP'},
    {'id': 'character', 'name': '👤 角色'},
    {'id': 'female', 'name': '♀️ 女性/XP'},
    {'id': 'male', 'name': '♂️ 男性/XP'},
    {'id': 'mixed', 'name': '⚡ 混合/玩法'},
    {'id': 'other', 'name': '📦 格式/其他'},
  ];

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _namespaces.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentNs = _namespaces[_tabController.index]['id']!;
    final filteredTags = _tagService.searchTags(_searchQuery, namespace: currentNs, limit: 120);

    return Scaffold(
      appBar: AppBar(
        title: const Text('标签中英对照检索 (EhViewer 风格)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索中英标签（例如：原神、变身、futa、nsfw）...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ),
              // Namespace Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabAlignment: TabAlignment.start,
                tabs: _namespaces.map((ns) => Tab(text: ns['name'])).toList(),
              ),
            ],
          ),
        ),
      ),
      body: filteredTags.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('未找到包含“$_searchQuery”的标签', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                children: filteredTags.map((tagInfo) {
                  return TagChip(
                    rawTag: tagInfo.tag,
                    tagInfo: tagInfo,
                    showBilingual: true,
                    showCount: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchScreen(initialQuery: tagInfo.tag),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
    );
  }
}
