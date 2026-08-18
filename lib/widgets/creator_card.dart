import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/creator.dart';
import '../providers/app_provider.dart';
import '../providers/bookmark_provider.dart';
import '../screens/creator_detail_screen.dart';
import 'service_badge.dart';

class CreatorCard extends StatelessWidget {
  final Creator creator;

  const CreatorCard({super.key, required this.creator});

  @override
  Widget build(BuildContext context) {
    final baseUrl = context.watch<AppProvider>().currentBaseUrl;
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final isFavorited = bookmarkProvider.isCreatorFavorited(creator.service, creator.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avatarUrl = creator.getAvatarUrl(baseUrl);
    final headers = {
      'Referer': '$baseUrl/',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreatorDetailScreen(creator: creator),
            ),
          );
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isDark ? const Color(0xFF323642) : const Color(0xFFE0E0E0),
          backgroundImage: CachedNetworkImageProvider(
            avatarUrl,
            headers: headers,
          ),
          onBackgroundImageError: (_, __) {},
          child: Text(
            creator.name.isNotEmpty ? creator.name[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                creator.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ServiceBadge(service: creator.service),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                'ID: ${creator.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              if (creator.favorited > 0) ...[
                const SizedBox(width: 10),
                Icon(Icons.favorite, size: 12, color: Colors.pink.withOpacity(0.8)),
                const SizedBox(width: 3),
                Text(
                  '${creator.favorited}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorited ? Colors.pink : (isDark ? Colors.white54 : Colors.black45),
            size: 22,
          ),
          onPressed: () {
            bookmarkProvider.toggleFavoriteCreator(creator);
          },
        ),
      ),
    );
  }
}
