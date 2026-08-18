import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../providers/app_provider.dart';
import '../providers/bookmark_provider.dart';
import '../screens/post_detail_screen.dart';
import '../screens/creator_detail_screen.dart';
import '../models/creator.dart';
import 'service_badge.dart';

class PostCard extends StatelessWidget {
  final PostItem post;

  const PostCard({super.key, required this.post});

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = context.watch<AppProvider>().currentBaseUrl;
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final isBookmarked = bookmarkProvider.isPostBookmarked(post.service, post.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageAttachments = post.allImageAttachments;
    final totalAttachments = post.allAttachments;
    final previewPath = post.previewImageUrl;

    String? imageUrl;
    if (previewPath != null) {
      final item = AttachmentItem(path: previewPath);
      imageUrl = item.getThumbnailUrl(baseUrl);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          bookmarkProvider.recordVisit(post);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Creator Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      final creator = Creator(
                        id: post.user,
                        name: post.userName ?? '创作者 ${post.user}',
                        service: post.service,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatorDetailScreen(creator: creator),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark ? const Color(0xFF323642) : const Color(0xFFE0E0E0),
                      backgroundImage: CachedNetworkImageProvider(
                        '$baseUrl/icons/${post.service}/${post.user}',
                      ),
                      onBackgroundImageError: (_, __) {},
                      child: Text(
                        (post.userName != null && post.userName!.isNotEmpty)
                            ? post.userName![0].toUpperCase()
                            : post.service.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName ?? 'ID: ${post.user}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(post.published ?? post.added),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Service Badge
                  ServiceBadge(service: post.service),
                  const SizedBox(width: 4),
                  // Bookmark Button
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: isBookmarked ? Colors.amber : (isDark ? Colors.white54 : Colors.black45),
                      size: 22,
                    ),
                    onPressed: () {
                      bookmarkProvider.toggleBookmarkPost(post);
                    },
                  ),
                ],
              ),
            ),

            // Post Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Text(
                post.title.trim().isEmpty ? '（无标题）' : post.title.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1,
                  height: 1.3,
                ),
              ),
            ),

            // Preview Image
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 280, minHeight: 120),
                    color: isDark ? const Color(0xFF1B1C22) : const Color(0xFFEEEEEE),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 160,
                        color: isDark ? const Color(0xFF22252E) : const Color(0xFFE5E5E5),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        // Fallback to original image path
                        final fallbackUrl = AttachmentItem(path: previewPath).getFileUrl(baseUrl);
                        return CachedNetworkImage(
                          imageUrl: fallbackUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            height: 120,
                            color: isDark ? const Color(0xFF22252E) : const Color(0xFFE5E5E5),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Attachment count badge
                  if (imageAttachments.length > 1 || totalAttachments.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${imageAttachments.length > 0 ? imageAttachments.length : totalAttachments.length} 媒体',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // Text excerpt snippet if no image or short note
            if ((imageUrl == null || imageUrl.isEmpty) && post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: Text(
                  post.content.replaceAll(RegExp(r'<[^>]*>'), ' ').trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
