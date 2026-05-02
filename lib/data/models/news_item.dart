class NewsItem {
  final String headline;
  final String body;
  final DateTime? publishedAt;
  final String? source;

  NewsItem({
    required this.headline,
    required this.body,
    this.publishedAt,
    this.source,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      headline: json['headline'] as String,
      body: json['body'] as String,
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt'] as String) 
          : null,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headline': headline,
      'body': body,
      'publishedAt': publishedAt?.toIso8601String(),
      'source': source,
    };
  }
}