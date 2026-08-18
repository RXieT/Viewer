class Creator {
  final String id;
  final String name;
  final String service;
  final String? indexed;
  final String? updated;
  final int favorited;

  Creator({
    required this.id,
    required this.name,
    required this.service,
    this.indexed,
    this.updated,
    this.favorited = 0,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Artist',
      service: json['service']?.toString() ?? '',
      indexed: json['indexed']?.toString(),
      updated: json['updated']?.toString(),
      favorited: (json['favorited'] is num) ? (json['favorited'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'service': service,
      'indexed': indexed,
      'updated': updated,
      'favorited': favorited,
    };
  }

  String getAvatarUrl(String baseUrl) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    // Kemono avatars are standard at {baseUrl}/icons/{service}/{id} or img CDN
    return '$cleanBase/icons/$service/$id';
  }

  String getWebUrl(String baseUrl) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$cleanBase/$service/user/$id';
  }
}
