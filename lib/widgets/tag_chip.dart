import 'package:flutter/material.dart';
import '../models/tag_info.dart';
import '../services/tag_service.dart';
import '../screens/search_screen.dart';

class TagChip extends StatelessWidget {
  final String rawTag;
  final TagInfo? tagInfo;
  final bool showBilingual;
  final bool showCount;
  final VoidCallback? onTap;

  const TagChip({
    super.key,
    required this.rawTag,
    this.tagInfo,
    this.showBilingual = true,
    this.showCount = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = tagInfo ?? TagService().getTagInfo(rawTag);
    final color = info.namespaceColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(initialQuery: info.tag),
                ),
              );
            },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4), width: 0.9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Namespace dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              // Bilingual or translated text
              Text(
                showBilingual ? info.bilingual : info.translation,
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1E2022),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showCount && info.count > 0) ...[
                const SizedBox(width: 5),
                Text(
                  '${info.count > 1000 ? '${(info.count / 1000).toStringAsFixed(1)}k' : info.count}',
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
