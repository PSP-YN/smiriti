import 'dart:convert';
import 'http_client.dart';
import 'secure_storage_service.dart';

enum LLMProvider { local, openai, anthropic, google }

class RemoteLLMService {
  RemoteLLMService._();

  static Future<String> generate({
    required String prompt,
    required LLMProvider provider,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    switch (provider) {
      case LLMProvider.openai:
        return _generateOpenAI(prompt, maxTokens, temperature);
      case LLMProvider.anthropic:
        return _generateAnthropic(prompt, maxTokens, temperature);
      case LLMProvider.google:
        return _generateGoogle(prompt, maxTokens, temperature);
      default:
        throw UnsupportedError('Provider $provider is not a remote provider');
    }
  }

  static Future<String> _generateOpenAI(String prompt, int maxTokens, double temperature) async {
    final apiKey = await SecureStorageService.getOpenAIKey();
    if (apiKey == null || apiKey.isEmpty) throw Exception('OpenAI API Key not found');

    try {
      final response = await AppHttpClient.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('OpenAI Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('TimeoutException')) {
        throw Exception('OpenAI request timed out. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<String> _generateAnthropic(String prompt, int maxTokens, double temperature) async {
    final apiKey = await SecureStorageService.getAnthropicKey();
    if (apiKey == null || apiKey.isEmpty) throw Exception('Anthropic API Key not found');

    try {
      final response = await AppHttpClient.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20240620',
          'max_tokens': maxTokens,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        throw Exception('Anthropic Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('TimeoutException')) {
        throw Exception('Anthropic request timed out. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<String> _generateGoogle(String prompt, int maxTokens, double temperature) async {
    final apiKey = await SecureStorageService.getGoogleKey();
    if (apiKey == null || apiKey.isEmpty) throw Exception('Google AI API Key not found');

    try {
      final response = await AppHttpClient.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': maxTokens,
            'temperature': temperature,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Google Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('TimeoutException')) {
        throw Exception('Google API request timed out. Please check your internet connection.');
      }
      rethrow;
    }
  }
}
