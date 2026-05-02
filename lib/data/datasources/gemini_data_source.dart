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

  static const String _model = 'gemini-2.5-flash';
  
  // Pre-configured system prompt and conversation history
  static const List<Map<String, dynamic>> _baseConversation = [
    {
      'role': 'user',
      'parts': [
        {
          'text': 'You are an expert news reporter who tech related curates content and provides a brief to the point response in roman urdu. You do not give long paragraphs but just some bullet points with the summary.\n',
        },
      ],
    },
    {
      'role': 'model',
      'parts': [
        {
          'text': '**Defining the Parameters**\n\nI\'m solidifying my understanding of the user\'s role: tech news reporter in Roman Urdu, brief responses, and bullet points. My focus is now on immediate content gathering, ensuring the responses are concise and fit the format. The search is on for recent tech news.\n\n**Refining the Approach**\n\nI\'m now zeroing in on the content requirements. My mission is to embody a tech news reporter, crafting responses exclusively in Roman Urdu. I\'ll need to tailor my output to bullet points, emphasizing brevity. I\'m prioritizing recent developments, keeping in mind the date is May 2nd, 2026, for sourcing fresh news.\n\n**Analyzing Urdu Tech News**\n\nI\'ve located several Urdu tech news headlines and noted the mention of Roman Urdu. My focus is now on extracting the key information. I plan to present this news in bullet points, formatted in Roman Urdu as per the user\'s request. This task is taking shape, and I think it will be a streamlined output.\n\n**Extracting Recent Tech News**\n\nI\'ve finalized my plan. First, I\'ll identify and extract recent tech news. Next, I\'ll summarize them into Roman Urdu bullet points. My goal is brevity. I\'ve begun with the search results, and am extracting news about Chrome updates, AI threats, WhatsApp support changes, Elon Musk\'s banking plans, Meta\'s layoffs, OpenAI and DeepMind\'s models, Pakistan\'s outsourcing success, NASA\'s Artemis mission, Punjab\'s AI goals, PTA regulations, and internet disruptions in Pakistan.\n\n**Compiling Key Tech News**\n\nI\'ve gathered quite a bit more relevant tech news, now including Indian and ISRO developments. My focus has shifted towards compiling all the key information. I\'ve been organizing the data into distinct bullet points for concise Roman Urdu presentation. The goal is to provide a complete, well-organized summary. I will use the bullet point format, translating the headlines into Roman Urdu.\n\n',
        },
        {
          'text': 'Breaking Tech News! Haal hi mein technology ki duniya mein kuch aham updates saamne aayi hain:\n\n*   **Google Chrome Security Update:** Google Chrome ne security masail ko theek karne ke liye naya update jari kiya hai.\n*   **AI Bots Se Cyber Attacks Mein Izafa:** AI bots ke zariye hone wale cyber hamlon mein izafe ka inkishaf hua hai.\n*   **WhatsApp Ki Support Khatam:** WhatsApp kuch purani devices par support khatam karne ja raha hai.\n*   **Elon Musk Ka Naya Banking Platform:** Elon Musk ek naya banking platform launch karne ki tayari kar rahe hain.\n*   **Meta Ki Hazaroon Mulazmeen Ko Farigh Karne Ki Taiyari:** Meta AI mein sarmayakari ki wajah se hazaron mulazmeen ko naukri se nikalne ka mansuba bana raha hai.\n*   **Naye AI Models Ka Introduction:** OpenAI aur DeepMind ne apne naye AI models mutaarif karwaye hain.\n*   **Pakistan Global Outsourcing Talent Index Mein:** Pakistan Global Outsourcing Talent Index mein 16th number par aa gaya hai.\n*   **NASA Ka Artemis 2 Mission:** 50 saal baad insaanon ki chaand ke qareeb wapsi, NASA ka Artemis 2 rocket tareekhi mission par rawana hua.\n*   **Punjab Ka AI Province Banne Ka Hadaf:** Punjab ne 2029 tak South Asia ka leading AI province banane ka hadaf rakha hai.',
        },
      ],
    },
  ];

  /// Fetches news from Gemini API based on user query
  Future<String> fetchNewsStream(String userQuery) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:streamGenerateContent?key=$apiKey'
    );

    final contents = [
      ..._baseConversation,
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
  Future<String> fetchNews(String userQuery) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey'
    );

    final contents = [
      ..._baseConversation,
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
  }

  void dispose() {
    client.close();
  }
}