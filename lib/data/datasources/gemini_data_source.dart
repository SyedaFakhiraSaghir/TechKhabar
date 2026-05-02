import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiDataSource {
  final String apiKey;
  final http.Client client;

  GeminiDataSource({
    required this.apiKey,
    http.Client? client,
  }) : client = client ?? http.Client();

  static const String _model = 'gemini-2.0-flash-exp';
  
  /// Get system prompt based on category
  String _getSystemPrompt(String category) {
    switch (category) {
      case 'Tech':
        return 'You are an expert tech news reporter who curates content and provides brief, to-the-point responses in Roman Urdu. You do not give long paragraphs but just bullet points with summaries.';
      case 'Sports':
        return 'You are an expert sports news reporter who curates content and provides brief, to-the-point responses in Roman Urdu. You focus on sports updates, match results, and player news. You do not give long paragraphs but just bullet points with summaries.';
      case 'Politics':
        return 'You are an expert political news reporter who curates content and provides brief, to-the-point responses in Roman Urdu. You focus on political developments, elections, and government news. You do not give long paragraphs but just bullet points with summaries.';
      case 'Crypto':
        return 'You are an expert cryptocurrency and blockchain news reporter who curates content and provides brief, to-the-point responses in Roman Urdu. You focus on crypto market news, blockchain developments, and digital assets. You do not give long paragraphs but just bullet points with summaries.';
      case 'Design':
        return 'You are an expert design and UX news reporter who curates content and provides brief, to-the-point responses in Roman Urdu. You focus on design trends, UI/UX developments, and creative industry news. You do not give long paragraphs but just bullet points with summaries.';
      default:
        return 'You are an expert news reporter who curates content and provides brief, to-the-point responses in Roman Urdu. You do not give long paragraphs but just bullet points with summaries.';
    }
  }
  
  // Base conversation structure
  List<Map<String, dynamic>> _getBaseConversation(String category) => [
    {
      'role': 'user',
      'parts': [
        {
          'text': _getSystemPrompt(category),
        },
      ],
    },
    {
      'role': 'model',
      'parts': [
        {
          'text': 'Main samajh gaya. Main ek $category news reporter ki tarah kaam karunga aur Roman Urdu mein brief bullet points ke saath updates doon ga.',
        },
      ],
    },
  ];

  /// Fetches news from Gemini API based on user query
  Future<String> fetchNewsStream(String userQuery, {String category = 'Tech'}) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:streamGenerateContent?key=$apiKey'
    );

    final contents = [
      ..._getBaseConversation(category),
      {
        'role': 'user',
        'parts': [
          {'text': userQuery},
        ],
      },
    ];

    final requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      },
    };

    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(requestBody);

    final streamedResponse = await client.send(request);

    if (streamedResponse.statusCode == 200) {
      final StringBuffer fullResponse = StringBuffer();
      
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data.trim() == '[DONE]') continue;

            try {
              final jsonData = jsonDecode(data);
              final text = jsonData['candidates']?[0]?['content']?['parts']?[0]?['text'];
              if (text != null && text.isNotEmpty) {
                fullResponse.write(text);
              }
            } catch (e) {
              // Skip invalid JSON chunks
            }
          }
        }
      }
      
      return fullResponse.toString();
    } else {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw Exception('Gemini API error (${streamedResponse.statusCode}): $errorBody');
    }
  }

  /// Alternative: Non-streaming version (simpler)
  Future<String> fetchNews(String userQuery, {String category = 'Tech'}) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey'
    );

    final contents = [
      ..._getBaseConversation(category),
      {
        'role': 'user',
        'parts': [
          {'text': userQuery},
        ],
      },
    ];

    final requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      },
    };

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final text = jsonData['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text ?? '';
      } else {
        throw Exception('Gemini API error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch from Gemini ($category, model: $_model): $e');
    }
  }

  void dispose() {
    client.close();
  }
}