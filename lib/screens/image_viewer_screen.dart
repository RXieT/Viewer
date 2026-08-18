import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<AttachmentItem> images;
  final int initialIndex;
  final String baseUrl;
  final String title;

  const ImageViewerScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.baseUrl,
    this.title = '图片查看',
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _copyImageUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制原图链接到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.images[_currentIndex];
    final currentUrl = currentItem.getFileUrl(widget.baseUrl);
    final headers = {
      'Referer': '${widget.baseUrl}/',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    };

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: '复制原图链接',
            onPressed: () => _copyImageUrl(currentUrl),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, size: 20),
            tooltip: '在浏览器打开原图',
            onPressed: () => _openExternal(currentUrl),
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        itemCount: widget.images.length,
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        builder: (context, index) {
          final item = widget.images[index];
          final url = item.getFileUrl(widget.baseUrl);

          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(
              url,
              headers: headers,
            ),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 3.5,
            heroAttributes: PhotoViewHeroAttributes(tag: 'image_$url'),
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    const SizedBox(height: 12),
                    const Text('图片加载失败', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _openExternal(url),
                      child: const Text('在浏览器中打开'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loadingBuilder: (context, event) => Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: event == null || event.expectedTotalBytes == null
                  ? null
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              strokeWidth: 2.5,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
