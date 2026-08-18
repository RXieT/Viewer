import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/app_provider.dart';

class MangaReaderScreen extends StatefulWidget {
  final PostItem post;
  final List<AttachmentItem> images;
  final int initialPage;

  const MangaReaderScreen({
    super.key,
    required this.post,
    required this.images,
    this.initialPage = 0,
  });

  @override
  State<MangaReaderScreen> createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends State<MangaReaderScreen> {
  bool _showControls = true;
  late int _currentPage;
  late String _scrollDirection; // 'vertical' or 'horizontal'
  Color _backgroundColor = Colors.black;

  final ScrollController _verticalScrollController = ScrollController();
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    final settings = context.read<AppProvider>().settings;
    _scrollDirection = settings.mangaScrollDirection;
    _pageController = PageController(initialPage: widget.initialPage);

    // Hide status bar / immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Start pre-caching ahead
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages();
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _verticalScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _preloadImages() {
    final baseUrl = context.read<AppProvider>().currentBaseUrl;
    final preloadCount = context.read<AppProvider>().settings.preloadPages;

    for (int i = _currentPage; i < _currentPage + preloadCount && i < widget.images.length; i++) {
      final url = widget.images[i].getFileUrl(baseUrl);
      if (url.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _jumpToPage(int page) {
    if (page < 0 || page >= widget.images.length) return;
    setState(() => _currentPage = page);
    if (_scrollDirection == 'horizontal') {
      _pageController.jumpToPage(page);
    } else {
      // Estimate vertical offset
      // A typical page is around 600-800px high
      _verticalScrollController.animateTo(
        page * 650.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    _preloadImages();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = context.watch<AppProvider>().currentBaseUrl;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Main Reader Body
          GestureDetector(
            onTap: _toggleControls,
            child: _scrollDirection == 'vertical'
                ? _buildVerticalWebtoonReader(baseUrl)
                : _buildHorizontalPageReader(baseUrl),
          ),

          // Top Controls HUD
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            top: _showControls ? 0 : -90,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 6, bottom: 8, left: 8, right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_currentPage + 1} / ${widget.images.length} 页 • ${_scrollDirection == 'vertical' ? '垂直卷轴瀑布流' : '水平翻页'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _scrollDirection == 'vertical' ? Icons.view_day_rounded : Icons.view_carousel_rounded,
                      color: Colors.white,
                    ),
                    tooltip: '切换阅读排版方式',
                    onPressed: () {
                      setState(() {
                        _scrollDirection = _scrollDirection == 'vertical' ? 'horizontal' : 'vertical';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls HUD
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            bottom: _showControls ? 0 : -130,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10, top: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Slider
                  Row(
                    children: [
                      Text(
                        '${_currentPage + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Expanded(
                        child: Slider(
                          value: _currentPage.toDouble(),
                          min: 0,
                          max: (widget.images.length - 1).toDouble().clamp(0.0, 9999.0),
                          divisions: widget.images.length > 1 ? widget.images.length - 1 : 1,
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveColor: Colors.white24,
                          onChanged: (val) {
                            _jumpToPage(val.round());
                          },
                        ),
                      ),
                      Text(
                        '${widget.images.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  // Quick Tool Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        icon: Icons.splitscreen_rounded,
                        label: _scrollDirection == 'vertical' ? '卷轴瀑布流' : '水平翻页',
                        onTap: () {
                          setState(() {
                            _scrollDirection = _scrollDirection == 'vertical' ? 'horizontal' : 'vertical';
                          });
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.palette_outlined,
                        label: _backgroundColor == Colors.black ? '纯黑背景' : '深灰背景',
                        onTap: () {
                          setState(() {
                            _backgroundColor = _backgroundColor == Colors.black
                                ? const Color(0xFF1E1E1E)
                                : Colors.black;
                          });
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.first_page_rounded,
                        label: '回到首页',
                        onTap: () => _jumpToPage(0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Continuous Seamless Vertical Webtoon Scroll
  Widget _buildVerticalWebtoonReader(String baseUrl) {
    return ListView.builder(
      controller: _verticalScrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.zero,
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        final item = widget.images[index];
        final url = item.getFileUrl(baseUrl);

        return Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.5,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.fitWidth,
              width: double.infinity,
              placeholder: (context, url) => Container(
                height: 400,
                color: _backgroundColor,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                      ),
                      const SizedBox(height: 10),
                      Text('正在加载第 ${index + 1} 页...', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 260,
                color: const Color(0xFF1F1F1F),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.white38, size: 40),
                      const SizedBox(height: 8),
                      Text('第 ${index + 1} 页加载失败', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Horizontal Page Flip Reader
  Widget _buildHorizontalPageReader(String baseUrl) {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.images.length,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
        _preloadImages();
      },
      itemBuilder: (context, index) {
        final item = widget.images[index];
        final url = item.getFileUrl(baseUrl);

        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white38, size: 48),
              ),
            ),
          ),
        );
      },
    );
  }
}
