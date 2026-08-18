import 'package:flutter/material.dart';

class TagInfo {
  final String tag;
  final String translation;
  final String namespace; // EhViewer style: 'parody', 'character', 'female', 'male', 'mixed', 'other'
  final int count;
  final String bilingual;

  TagInfo({
    required this.tag,
    required this.translation,
    this.namespace = 'other',
    this.count = 0,
    String? bilingual,
  }) : bilingual = bilingual ?? (translation != tag ? '$tag | $translation' : tag);

  factory TagInfo.fromJson(Map<String, dynamic> json) {
    final t = json['tag']?.toString() ?? '';
    final trans = json['trans']?.toString() ?? t;
    final ns = json['ns']?.toString() ?? json['cat']?.toString() ?? 'other';
    final bi = json['bilingual']?.toString() ?? (trans != t ? '$t | $trans' : t);

    return TagInfo(
      tag: t,
      translation: trans,
      namespace: ns,
      count: (json['count'] is num) ? (json['count'] as num).toInt() : 0,
      bilingual: bi,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'trans': translation,
      'ns': namespace,
      'count': count,
      'bilingual': bilingual,
    };
  }

  // EhViewer standard namespace colors
  Color get namespaceColor {
    switch (namespace.toLowerCase()) {
      case 'parody':
        return const Color(0xFFAB47BC); // Purple (原作/IP)
      case 'character':
        return const Color(0xFF29B6F6); // Light Blue (角色)
      case 'female':
        return const Color(0xFFEC407A); // Pink (女性/XP)
      case 'male':
        return const Color(0xFF66BB6A); // Green (男性/XP)
      case 'mixed':
        return const Color(0xFFFFA726); // Orange (混合/玩法)
      case 'language':
        return const Color(0xFFEF5350); // Red
      case 'artist':
      case 'group':
        return const Color(0xFFFF7043); // Deep Orange
      default:
        return const Color(0xFF78909C); // Blue Grey
    }
  }

  String get namespaceDisplayName {
    switch (namespace.toLowerCase()) {
      case 'parody':
        return '原作/IP';
      case 'character':
        return '角色';
      case 'female':
        return '女性/XP';
      case 'male':
        return '男性/XP';
      case 'mixed':
        return '混合/体位';
      case 'language':
        return '语言';
      case 'artist':
        return '画师';
      default:
        return '通用/其他';
    }
  }

  String formatDisplay({bool showBilingual = true}) {
    if (showBilingual) {
      return bilingual;
    }
    return translation.isNotEmpty ? translation : tag;
  }
}
