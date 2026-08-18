class AppSettings {
  String baseUrl;
  String themeMode; // 'dark', 'light', 'amoled', 'system'
  bool useThumbnails;
  int pageSize;
  String defaultReaderMode; // 'auto', 'manga', 'classic'
  String mangaScrollDirection; // 'vertical', 'horizontal'
  int preloadPages; // Preload count for 120Hz smooth reading
  List<String> savedDomains;

  static const String defaultBaseUrl = 'https://kemono.cr';
  static const List<String> presetDomains = [
    'https://kemono.cr',
    'https://kemono.su',
    'https://coomer.su',
    'https://kemono.party',
  ];

  AppSettings({
    this.baseUrl = defaultBaseUrl,
    this.themeMode = 'dark',
    this.useThumbnails = true,
    this.pageSize = 50,
    this.defaultReaderMode = 'auto',
    this.mangaScrollDirection = 'vertical',
    this.preloadPages = 3,
    List<String>? savedDomains,
  }) : savedDomains = savedDomains ?? List.from(presetDomains);

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      baseUrl: json['baseUrl']?.toString() ?? defaultBaseUrl,
      themeMode: json['themeMode']?.toString() ?? 'dark',
      useThumbnails: json['useThumbnails'] as bool? ?? true,
      pageSize: (json['pageSize'] is num) ? (json['pageSize'] as num).toInt() : 50,
      defaultReaderMode: json['defaultReaderMode']?.toString() ?? 'auto',
      mangaScrollDirection: json['mangaScrollDirection']?.toString() ?? 'vertical',
      preloadPages: (json['preloadPages'] is num) ? (json['preloadPages'] as num).toInt() : 3,
      savedDomains: (json['savedDomains'] is List)
          ? List<String>.from(json['savedDomains'].map((e) => e.toString()))
          : List.from(presetDomains),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'themeMode': themeMode,
      'useThumbnails': useThumbnails,
      'pageSize': pageSize,
      'defaultReaderMode': defaultReaderMode,
      'mangaScrollDirection': mangaScrollDirection,
      'preloadPages': preloadPages,
      'savedDomains': savedDomains,
    };
  }

  String get cleanBaseUrl {
    var url = baseUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
