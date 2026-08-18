import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/post.dart';
import '../models/creator.dart';
import '../providers/app_provider.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/service_badge.dart';
import 'manga_reader_screen.dart';
import 'image_viewer_screen.dart';
import 'creator_detail_screen.dart';
import 'webview_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostItem post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late PostItem _post;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _fetchFullDetailIfNeeded();
  }

  Future<void> _fetchFullDetailIfNeeded() async {
    if (_post.attachments.isEmpty && _post.file == null) {
      setState(() => _isLoadingDetail = true);
      final api = context.read<AppProvider>().apiService;
      final res = await api.getPostDetail(_post.service, _post.user, _post.id);
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
          if (res.isSuccess && res.data != null) {
            _post = res.data!;
          }
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制 $label 到剪贴板'), duration: const Duration(seconds: 2)),
    );
  }

  void _openMangaReader(List<AttachmentItem> images) {
    if (images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MangaReaderScreen(
          post: _post,
          images: images,
          initialPage: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = context.watch<AppProvider>().currentBaseUrl;
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final isBookmarked = bookmarkProvider.isPostBookmarked(_post.service, _post.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageAttachments = _post.allImageAttachments;
    final archiveAttachments = _post.allArchiveAttachments;
    final otherAttachments = _post.allAttachments.where((a) => !a.isImage).toList();
    final detectedType = _post.detectedContentType;
    final webUrl = _post.getWebUrl(baseUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTypeTitle(detectedType)),
        actions: [
          if (imageAttachments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.auto_stories_rounded),
              tooltip: '进入漫画/画册阅读器',
              onPressed: () => _openMangaReader(imageAttachments),
            ),
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: isBookmarked ? Colors.amber : null,
            ),
            tooltip: '收藏作品',
            onPressed: () {
              bookmarkProvider.toggleBookmarkPost(_post);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'copy_link') {
                _copyToClipboard(webUrl, '网页链接');
              } else if (value == 'open_webview') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WebViewScreen(initialUrl: webUrl, title: _post.title),
                  ),
                );
              } else if (value == 'open_external') {
                _openExternal(webUrl);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_link',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 18),
                    SizedBox(width: 10),
                    Text('复制作品链接'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'open_webview',
                child: Row(
                  children: [
                    Icon(Icons.language, size: 18),
                    SizedBox(width: 10),
                    Text('在内置网页中查看'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'open_external',
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser, size: 18),
                    SizedBox(width: 10),
                    Text('在系统浏览器打开'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smart Content-Type Badge & Quick Action Header
            _buildSmartTypeBanner(detectedType, imageAttachments.length, archiveAttachments.length),

            // Creator Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  final creator = Creator(
                    id: _post.user,
                    name: _post.userName ?? '创作者 ${_post.user}',
                    service: _post.service,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatorDetailScreen(creator: creator),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F222B) : const Color(0xFFF0F2F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isDark ? const Color(0xFF323642) : const Color(0xFFE0E0E0),
                        backgroundImage: CachedNetworkImageProvider(
                          '$baseUrl/icons/${_post.service}/${_post.user}',
                        ),
                        onBackgroundImageError: (_, __) {},
                        child: Text(
                          (_post.userName != null && _post.userName!.isNotEmpty)
                              ? _post.userName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _post.userName ?? '创作者 ID: ${_post.user}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '点击访问作者专栏',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ServiceBadge(service: _post.service),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            // Post Title & Date
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    _post.title.trim().isEmpty ? '（无标题）' : _post.title.trim(),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        '发布: ${_formatDate(_post.published ?? _post.added)}',
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

            // Prominent Manga Reader Entry Button (if images >= 2)
            if (imageAttachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _openMangaReader(imageAttachments),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.auto_stories, size: 20),
                    label: Text(
                      '以原生漫画浏览器模式阅读 (${imageAttachments.length} 张)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                  ),
                ),
              ),

            // Prominent Game/Archive Resource Cards Section (if game/archives exist)
            if (archiveAttachments.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    const Icon(Icons.sports_esports_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '游戏/应用资源包 (${archiveAttachments.length} 个文件)',
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: archiveAttachments.length,
                itemBuilder: (context, index) {
                  final att = archiveAttachments[index];
                  final fileUrl = att.getFileUrl(baseUrl);
                  final fileName = att.name ?? (att.path?.split('/').last ?? '游戏安装包 ${index + 1}');

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF242836) : const Color(0xFFEBF1FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF373E54) : const Color(0xFFBFD2F8),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.download_for_offline_rounded, color: Colors.orange, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 3),
                              const Text('点击直接调起浏览器高速下载', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: '复制直链',
                          onPressed: () => _copyToClipboard(fileUrl, '文件直链'),
                        ),
                        ElevatedButton(
                          onPressed: () => _openExternal(fileUrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('下载', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const Divider(height: 24, indent: 16, endIndent: 16),

            // Content Description (HTML / Text)
            if (_post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Html(
                  data: _post.content,
                  style: {
                    "body": Style(
                      fontSize: FontSize(14.5),
                      lineHeight: const LineHeight(1.5),
                      color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF2B2D42),
                      padding: HtmlPaddings.zero,
                      margin: Margins.zero,
                    ),
                    "a": Style(
                      color: Theme.of(context).colorScheme.primary,
                      textDecoration: TextDecoration.underline,
                    ),
                  },
                  onLinkTap: (url, _, __) {
                    if (url != null) _openExternal(url);
                  },
                ),
              ),

            if (_isLoadingDetail)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Image Gallery / Preview Section
            if (imageAttachments.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Row(
                  children: [
                    Icon(
                      detectedType == ContentType.game ? Icons.screenshot_rounded : Icons.photo_library_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      detectedType == ContentType.game
                          ? '游戏截图与预览图 (${imageAttachments.length} 张)'
                          : '作品图集 (${imageAttachments.length} 张)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.fullscreen, size: 18),
                      label: const Text('全屏查看'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageViewerScreen(
                              images: imageAttachments,
                              initialIndex: 0,
                              baseUrl: baseUrl,
                              title: _post.title,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: imageAttachments.length,
                itemBuilder: (context, index) {
                  final item = imageAttachments[index];
                  final thumbUrl = item.getThumbnailUrl(baseUrl);
                  final fullUrl = item.getFileUrl(baseUrl);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2E323E) : const Color(0xFFE2E6EE),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (detectedType == ContentType.manga) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MangaReaderScreen(
                                post: _post,
                                images: imageAttachments,
                                initialPage: index,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImageViewerScreen(
                                images: imageAttachments,
                                initialIndex: index,
                                baseUrl: baseUrl,
                                title: _post.title,
                              ),
                            ),
                          );
                        }
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CachedNetworkImage(
                            imageUrl: thumbUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              height: 220,
                              color: isDark ? const Color(0xFF242730) : const Color(0xFFEEEEEE),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              return CachedNetworkImage(
                                imageUrl: fullUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorWidget: (_, __, ___) => Container(
                                  height: 140,
                                  color: isDark ? const Color(0xFF242730) : const Color(0xFFEEEEEE),
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 36, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${index + 1} / ${imageAttachments.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            // Other non-image files
            if (otherAttachments.isNotEmpty && archiveAttachments.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Text(
                  '文件附件 (${otherAttachments.length} 个)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: otherAttachments.length,
                itemBuilder: (context, index) {
                  final att = otherAttachments[index];
                  final fileUrl = att.getFileUrl(baseUrl);
                  final fileName = att.name ?? (att.path?.split('/').last ?? '附件 ${index + 1}');

                  return ListTile(
                    leading: const Icon(Icons.attachment),
                    title: Text(fileName),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _openExternal(fileUrl),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTypeTitle(ContentType type) {
    switch (type) {
      case ContentType.game:
        return '游戏/应用资源';
      case ContentType.manga:
        return '漫画/画集阅读';
      case ContentType.illustration:
        return '作品详情';
      default:
        return '作品详情';
    }
  }

  Widget _buildSmartTypeBanner(ContentType type, int imageCount, int archiveCount) {
    Color bannerColor;
    IconData icon;
    String label;
    String sub;

    switch (type) {
      case ContentType.game:
        bannerColor = Colors.orange;
        icon = Icons.sports_esports_rounded;
        label = '智能识别为：游戏/应用资源包';
        sub = '包含 $archiveCount 个安装包，已优化截图预览与直链下载体验';
        break;
      case ContentType.manga:
        bannerColor = Colors.green;
        icon = Icons.menu_book_rounded;
        label = '智能识别为：漫画/连环画集';
        sub = '包含 $imageCount 页图片，支持原生零缝隙垂直卷轴与翻页阅读';
        break;
      case ContentType.illustration:
        bannerColor = Colors.blue;
        icon = Icons.photo_size_select_actual_rounded;
        label = '图集作品';
        sub = '包含 $imageCount 张高清图片';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bannerColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: bannerColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(color: bannerColor.withOpacity(0.85), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
