import 'package:http/http.dart' as http;

import '../models/news_item.dart';
import 'gemini_data_source.dart';

class NewsRemoteDataSource {
  final Map<String, String> apiKeys;
  late final Map<String, GeminiDataSource> _geminiDataSources;

  NewsRemoteDataSource({required this.apiKeys}) {
    // Initialize GeminiDataSource for each category
    _geminiDataSources = {
      for (var entry in apiKeys.entries)
        entry.key: GeminiDataSource(apiKey: entry.value),
    };
  }

  /// Fetches news from Gemini API for a specific category
  Future<List<NewsItem>> fetchNews({String? query, String category = 'Tech'}) async {
    try {
      final geminiDataSource = _geminiDataSources[category];
      if (geminiDataSource == null) {
        throw Exception('No Gemini data source configured for category: $category');
      }
      
      // Default query if none provided
      late final String userQuery;
      if (query != null) {
        userQuery = query;
      } else {
        userQuery = _getDefaultQuery(category);
      }
      
      // Fetch from Gemini using non-streaming method
      final rawResponse = await geminiDataSource.fetchNews(userQuery, category: category);
      
      // Parse the response into NewsItem objects
      return _parseNews(rawResponse);
    } catch (e) {
      throw Exception('Failed to fetch news from Gemini: $e');
    }
  }

  /// Fetches news with a specific topic
  Future<List<NewsItem>> fetchNewsByTopic(String topic) async {
    final query = '$topic ke baare mein latest updates kya hain?';
    return fetchNews(query: query, category: topic);
  }

  /// Fetches breaking news
  Future<List<NewsItem>> fetchBreakingNews() async {
    return fetchNews(query: 'Breaking tech news today kya hai?', category: 'Tech');
  }

  /// Get default query based on category
  String _getDefaultQuery(String category) {
    switch (category) {
      case 'Tech':
        return 'Aj ki latest tech news kya hain?';
      case 'Sports':
        return 'Aj ki latest sports news kya hain?';
      case 'Politics':
        return 'Aj ki latest politics news kya hain?';
      case 'Crypto':
        return 'Aj ki latest crypto aur blockchain news kya hain?';
      case 'Design':
        return 'Aj ki latest design trends kya hain?';
      default:
        return 'Aj ki latest news kya hain?';
    }
  }

  /// Parses Gemini response into NewsItem objects
  List<NewsItem> _parseNews(String rawText) {
    final List<NewsItem> news = [];

    // Split by bullet points (lines starting with * or -)
    final lines = rawText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Check for bullet points with **bold** headlines
      if (trimmedLine.contains('**')) {
        final regex = RegExp(r'\*\*(.+?)\*\*');
        final match = regex.firstMatch(trimmedLine);

        if (match != null) {
          final headline = match.group(1) ?? '';
          // Extract body text after the headline
          String body = trimmedLine
              .replaceAll(regex, '')
              .replaceAll('*', '')
              .replaceAll('-', '')
              .trim();

          // If body is empty, use a default message
          if (body.isEmpty) {
            body = 'Read more about this tech update.';
          }

          news.add(
            NewsItem(
              headline: headline,
              body: body,
            ),
          );
        }
      }
      // Handle bullet points without bold formatting
      else if (trimmedLine.startsWith('*') || trimmedLine.startsWith('-')) {
        String content = trimmedLine.substring(1).trim();
        
        // Try to extract headline from content
        if (content.contains(':')) {
          final parts = content.split(':');
          final headline = parts.first.trim();
          final body = parts.skip(1).join(':').trim();
          
          news.add(
            NewsItem(
              headline: headline,
              body: body.isEmpty ? 'Latest tech update.' : body,
            ),
          );
        } else {
          // If no colon, treat the whole line as headline
          news.add(
            NewsItem(
              headline: content,
              body: 'Latest tech update.',
            ),
          );
        }
      }
    }

    // If no news items were parsed, try a fallback parsing method
    if (news.isEmpty && rawText.isNotEmpty) {
      // Simple fallback: split by double newlines
      final paragraphs = rawText.split('\n\n');
      for (final paragraph in paragraphs) {
        if (paragraph.trim().isNotEmpty) {
          news.add(
            NewsItem(
              headline: paragraph.length > 50 
                  ? '${paragraph.substring(0, 50)}...' 
                  : paragraph,
              body: paragraph,
            ),
          );
        }
      }
    }

    return news;
  }
}

/// Extension method for alternative parsing strategies
extension NewsParserExtension on NewsRemoteDataSource {
  List<NewsItem> parseWithRegex(String rawText) {
    final List<NewsItem> news = [];
    
    // More flexible regex pattern
    final regex = RegExp(r'\*\*?([^*\n]+)\*\*?[:\-]?\s*(.*?)(?=\n\s*\*\*?|\n\n|\Z)', dotAll: true);
    final matches = regex.allMatches(rawText);
    
    for (final match in matches) {
      final headline = match.group(1)?.trim() ?? '';
      final body = match.group(2)?.trim() ?? '';
      
      if (headline.isNotEmpty) {
        news.add(
          NewsItem(
            headline: headline,
            body: body.isEmpty ? 'Read more about this tech trend.' : body,
          ),
        );
      }
    }
    
    return news;
  }
}