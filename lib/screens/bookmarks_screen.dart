import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/creator_card.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final favCreators = bookmarkProvider.favoriteCreators;
    final bookmarkedPosts = bookmarkProvider.bookmarkedPosts;
    final history = bookmarkProvider.recentHistory;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmarks_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('我的收藏与足迹'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          tabs: [
            Tab(text: '作者 (${favCreators.length})'),
            Tab(text: '帖子 (${bookmarkedPosts.length})'),
            Tab(text: '历史 (${history.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Favorite Creators
          favCreators.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.favorite_border_rounded,
                  title: '暂无关注的创作者',
                  description: '在创作者列表或帖子页面点击心形图标即可一键关注',
                )
              : ListView.builder(
                  itemCount: favCreators.length,
                  itemBuilder: (context, index) {
                    return CreatorCard(creator: favCreators[index]);
                  },
                ),

          // Bookmarked Posts
          bookmarkedPosts.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.bookmark_border_rounded,
                  title: '暂无收藏的帖子',
                  description: '浏览帖子时点击右上角书签图标可将喜欢的作品永久保存在本地',
                )
              : ListView.builder(
                  itemCount: bookmarkedPosts.length,
                  itemBuilder: (context, index) {
                    return PostCard(post: bookmarkedPosts[index]);
                  },
                ),

          // Browsing History
          history.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.history_rounded,
                  title: '暂无浏览历史',
                  description: '你点击阅读过的帖子会自动记录在此处，方便回看',
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '最近浏览了 ${history.length} 篇帖子',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('清空历史', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('清空浏览历史？'),
                                  content: const Text('确定要清除所有本地浏览记录吗？此操作无法撤销。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        bookmarkProvider.clearHistory();
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('清空', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          return PostCard(post: history[index]);
                        },
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
