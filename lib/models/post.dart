enum ContentType {
  manga,
  game,
  illustration,
  general,
}

enum ReaderMode {
  auto,
  manga,
  classic,
}

class AttachmentItem {
  final String? name;
  final String? path;

  AttachmentItem({this.name, this.path});

  factory AttachmentItem.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return AttachmentItem(
        name: json['name']?.toString(),
        path: json['path']?.toString(),
      );
    }
    return AttachmentItem();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
    };
  }

  bool get isImage {
    if (path == null) return false;
    final lower = path!.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.avif');
  }

  bool get isVideo {
    if (path == null) return false;
    final lower = path!.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv');
  }

  bool get isAudio {
    if (path == null) return false;
    final lower = path!.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.m4a');
  }

  bool get isArchiveOrGame {
    if (path == null) return false;
    final lower = path!.toLowerCase();
    return lower.endsWith('.zip') ||
        lower.endsWith('.rar') ||
        lower.endsWith('.7z') ||
        lower.endsWith('.tar') ||
        lower.endsWith('.gz') ||
        lower.endsWith('.apk') ||
        lower.endsWith('.exe') ||
        lower.endsWith('.unitypackage');
  }

  String getFileUrl(String baseUrl) {
    if (path == null || path!.isEmpty) return '';
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    if (path!.startsWith('http://') || path!.startsWith('https://')) {
      return path!;
    }
    final cleanPath = path!.startsWith('/') ? path! : '/$path';
    return '$cleanBase$cleanPath';
  }

  String getThumbnailUrl(String baseUrl) {
    if (path == null || path!.isEmpty) return '';
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    if (path!.startsWith('http://') || path!.startsWith('https://')) {
      return path!;
    }
    final cleanPath = path!.startsWith('/') ? path! : '/$path';
    return '$cleanBase/thumbnail$cleanPath';
  }
}

class PostItem {
  final String id;
  final String user;
  final String service;
  final String title;
  final String content;
  final String? published;
  final String? added;
  final String? edited;
  final AttachmentItem? file;
  final List<AttachmentItem> attachments;
  final Map<String, dynamic>? embed;
  
  String? userName;

  PostItem({
    required this.id,
    required this.user,
    required this.service,
    required this.title,
    required this.content,
    this.published,
    this.added,
    this.edited,
    this.file,
    this.attachments = const [],
    this.embed,
    this.userName,
  });

  factory PostItem.fromJson(Map<String, dynamic> json) {
    AttachmentItem? mainFile;
    if (json['file'] != null && json['file'] is Map) {
      mainFile = AttachmentItem.fromJson(json['file']);
    }

    final rawAttachments = json['attachments'];
    List<AttachmentItem> parsedAttachments = [];
    if (rawAttachments is List) {
      for (var item in rawAttachments) {
        if (item != null) {
          parsedAttachments.add(AttachmentItem.fromJson(item));
        }
      }
    }

    return PostItem(
      id: json['id']?.toString() ?? '',
      user: json['user']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      title: json['title']?.toString() ?? '无标题',
      content: json['content']?.toString() ?? '',
      published: json['published']?.toString(),
      added: json['added']?.toString(),
      edited: json['edited']?.toString(),
      file: mainFile,
      attachments: parsedAttachments,
      embed: (json['embed'] is Map<String, dynamic>) ? json['embed'] : null,
      userName: json['user_name']?.toString() ?? json['username']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'service': service,
      'title': title,
      'content': content,
      'published': published,
      'added': added,
      'edited': edited,
      'file': file?.toJson(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'embed': embed,
      'user_name': userName,
    };
  }

  List<AttachmentItem> get allImageAttachments {
    final list = <AttachmentItem>[];
    if (file != null && file!.path != null && file!.path!.isNotEmpty && file!.isImage) {
      list.add(file!);
    }
    for (var att in attachments) {
      if (att.path != null && att.path!.isNotEmpty && att.isImage) {
        if (file?.path != att.path) {
          list.add(att);
        }
      }
    }
    return list;
  }

  List<AttachmentItem> get allArchiveAttachments {
    return allAttachments.where((a) => a.isArchiveOrGame).toList();
  }

  List<AttachmentItem> get allAttachments {
    final list = <AttachmentItem>[];
    if (file != null && file!.path != null && file!.path!.isNotEmpty) {
      list.add(file!);
    }
    for (var att in attachments) {
      if (att.path != null && att.path!.isNotEmpty) {
        if (file?.path != att.path) {
          list.add(att);
        }
      }
    }
    return list;
  }

  String? get previewImageUrl {
    if (file != null && file!.isImage && file!.path != null) {
      return file!.path;
    }
    for (var att in attachments) {
      if (att.isImage && att.path != null) {
        return att.path;
      }
    }
    return null;
  }

  /// Intelligent Content Classification
  ContentType get detectedContentType {
    final archives = allArchiveAttachments;
    final images = allImageAttachments;
    final textLower = '${title.toLowerCase()} ${content.toLowerCase()}';

    // Check if it's a Game or Software Release
    final hasGameKeywords = textLower.contains('v0.') ||
        textLower.contains('v1.') ||
        textLower.contains('v2.') ||
        textLower.contains('ver.') ||
        textLower.contains('version') ||
        textLower.contains('game') ||
        textLower.contains('build') ||
        textLower.contains('patch') ||
        textLower.contains('apk') ||
        textLower.contains('mod') ||
        textLower.contains('demo') ||
        textLower.contains('release') ||
        textLower.contains('windows') ||
        textLower.contains('android');

    if (archives.isNotEmpty && (hasGameKeywords || images.length <= 6)) {
      return ContentType.game;
    }

    // Check if it's a Comic/Manga
    final hasMangaKeywords = textLower.contains('chapter') ||
        textLower.contains('ch.') ||
        textLower.contains('ep.') ||
        textLower.contains('vol.') ||
        textLower.contains('漫画') ||
        textLower.contains('話') ||
        textLower.contains('comic') ||
        textLower.contains('manga') ||
        textLower.contains('doujin');

    if (images.length >= 4 || hasMangaKeywords) {
      return ContentType.manga;
    }

    if (images.isNotEmpty) {
      return ContentType.illustration;
    }

    return ContentType.general;
  }

  String getWebUrl(String baseUrl) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$cleanBase/$service/user/$user/post/$id';
  }
}
