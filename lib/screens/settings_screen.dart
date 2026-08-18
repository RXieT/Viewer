import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/bookmark_provider.dart';
import '../models/app_settings.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _domainController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    _domainController.text = app.currentBaseUrl;
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  void _showAddDomainDialog() {
    final customCtrl = TextEditingController(text: 'https://');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加自定义域名/镜像'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请输入反向代理、镜像或自建 API 地址：',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: customCtrl,
              decoration: const InputDecoration(
                hintText: 'https://your-mirror-site.com',
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = customCtrl.text.trim();
              if (newUrl.isNotEmpty && newUrl != 'https://') {
                final app = context.read<AppProvider>();
                await app.updateBaseUrl(newUrl);
                _domainController.text = app.currentBaseUrl;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已切换并保存域名: ${app.currentBaseUrl}')),
                );
              }
            },
            child: const Text('应用并保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('设置与偏好'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        children: [
          // Section 1: Domain & Mirror Configuration
          _buildSectionHeader('🌐 域名与网络连接 (自定义镜像)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前使用域名 / API 端点：',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _domainController,
                          decoration: const InputDecoration(
                            hintText: 'https://kemono.cr',
                            prefixIcon: Icon(Icons.dns, size: 18),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await app.updateBaseUrl(_domainController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已更新域名为: ${app.currentBaseUrl}')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('快捷预设域名：', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...app.settings.savedDomains.map((domain) {
                        final isSelected = app.currentBaseUrl.toLowerCase() == domain.toLowerCase();
                        return ChoiceChip(
                          label: Text(domain.replaceAll('https://', '').replaceAll('http://', '')),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withOpacity(0.25),
                          onSelected: (_) {
                            app.updateBaseUrl(domain);
                            _domainController.text = domain;
                          },
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text('添加自定义'),
                        onPressed: _showAddDomainDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Test Connection Button
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: app.isTestingDomain
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.speed_rounded, size: 16),
                        label: Text(app.isTestingDomain ? '检测中...' : '测试当前域名连通性'),
                        onPressed: app.isTestingDomain ? null : () => app.testCurrentDomain(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                  if (app.domainTestResult != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: app.domainTestSuccess
                            ? Colors.green.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: app.domainTestSuccess ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        app.domainTestResult!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: app.domainTestSuccess ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section 2: Reader Experience & Game / Manga Handling
          _buildSectionHeader('📖 原生阅读器与游戏/漫画识别'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
                  title: const Text('默认阅读行为与模式'),
                  subtitle: Text(
                    app.settings.defaultReaderMode == 'auto'
                        ? '🤖 智能自动识别 (有压缩包识别为游戏，多图识别为漫画)'
                        : app.settings.defaultReaderMode == 'manga'
                            ? '📖 强制优先使用漫画卷轴阅读器'
                            : '🖼️ 经典媒体卡片浏览',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: DropdownButton<String>(
                    value: app.settings.defaultReaderMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('🤖 智能识别 (推荐)')),
                      DropdownMenuItem(value: 'manga', child: Text('📖 漫画阅读器优先')),
                      DropdownMenuItem(value: 'classic', child: Text('🖼️ 经典卡片流')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => app.settings.defaultReaderMode = val);
                        app.storageService.saveSettings(app.settings);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.view_day_rounded, color: Colors.blue),
                  title: const Text('漫画阅读排版风格'),
                  subtitle: Text(
                    app.settings.mangaScrollDirection == 'vertical'
                        ? '📜 垂直卷轴瀑布流 (Webtoon 零缝隙连读，最舒适)'
                        : '📖 水平翻页模式',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: DropdownButton<String>(
                    value: app.settings.mangaScrollDirection,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'vertical', child: Text('📜 垂直卷轴瀑布流')),
                      DropdownMenuItem(value: 'horizontal', child: Text('📖 水平翻页')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => app.settings.mangaScrollDirection = val);
                        app.storageService.saveSettings(app.settings);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 3: Appearance & Theme
          _buildSectionHeader('🎨 界面与主题外观 (120Hz 原生流畅)'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('主题色彩风格'),
                  subtitle: Text(
                    app.settings.themeMode == 'dark'
                        ? '深色模式 (舒适夜间)'
                        : app.settings.themeMode == 'amoled'
                            ? '纯黑模式 (AMOLED 省电)'
                            : app.settings.themeMode == 'light'
                                ? '浅色明亮模式'
                                : '跟随系统设置',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: DropdownButton<String>(
                    value: app.settings.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'dark', child: Text('深色模式')),
                      DropdownMenuItem(value: 'amoled', child: Text('纯黑 AMOLED')),
                      DropdownMenuItem(value: 'light', child: Text('浅色模式')),
                      DropdownMenuItem(value: 'system', child: Text('跟随系统')),
                    ],
                    onChanged: (val) {
                      if (val != null) app.setThemeMode(val);
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.image_outlined),
                  title: const Text('列表优先加载缩略图'),
                  subtitle: const Text('开启后大幅减少移动网络流量消耗并提升滑动流畅度', style: TextStyle(fontSize: 12)),
                  value: app.settings.useThumbnails,
                  onChanged: (val) => app.setUseThumbnails(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 4: Data Management
          _buildSectionHeader('🧹 数据与本地管理'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text('清空浏览足迹与历史'),
                  subtitle: const Text('清除最近阅读的帖子记录', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    context.read<BookmarkProvider>().clearHistory();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已清空所有本地浏览历史')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history_toggle_off_rounded),
                  title: const Text('清空搜索历史词'),
                  subtitle: const Text('清除搜索栏历史快捷标签', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    app.storageService.clearSearchHistory();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已清空搜索历史记录')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 5: Safety & Non-Destructive Design Notice
          _buildSectionHeader('🛡️ 安全与非破坏性访问说明'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '非破坏性轻量客户端设计',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 严格遵循 Kemono 官方公开 REST API 只读规范，按需分页加载。\n'
                    '• 杜绝爬虫与高并发全量抓取，保护站点与网络。\n'
                    '• 智能识别：游戏资源突出下载卡片与截图；漫画/图集无缝进入原生滚动漫画阅读器。\n'
                    '• 收藏夹与关注完全离线保存在本地，无须注册登录。',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Kemono Mobile Viewer v1.0.0\nNative Smooth Experience',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
