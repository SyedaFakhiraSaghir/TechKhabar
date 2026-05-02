import 'package:http/http.dart' as http;

import '../models/news_item.dart';
import 'gemini_data_source.dart';

class NewsRemoteDataSource {
  final GeminiDataSource geminiDataSource;

  NewsRemoteDataSource({required this.geminiDataSource});

  /// Fetches news from Gemini API
  Future<List<NewsItem>> fetchNews({String? query}) async {
    try {
      // Default query if none provided
      final userQuery = query ?? 'Aj ki latest tech news kya hain?';
      
      // Fetch from Gemini using non-streaming method
      final rawResponse = await geminiDataSource.fetchNews(userQuery);
      
      // Parse the response into NewsItem objects
      return _parseNews(rawResponse);
    } catch (e) {
      throw Exception('Failed to fetch news from Gemini: $e');
    }
  }

  /// Fetches news with a specific topic
  Future<List<NewsItem>> fetchNewsByTopic(String topic) async {
    final query = '$topic ke baare mein latest updates kya hain?';
    return fetchNews(query: query);
  }

  /// Fetches breaking news
  Future<List<NewsItem>> fetchBreakingNews() async {
    return fetchNews(query: 'Breaking tech news today kya hai?');
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