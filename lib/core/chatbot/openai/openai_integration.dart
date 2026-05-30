import 'package:test_app/core/chatbot/models/chatbot_message.dart';
import 'package:test_app/core/chatbot/models/chatbot_response.dart';
import 'package:test_app/core/chatbot/models/chatbot_state.dart';

/// OpenAI integration for conversational AI
/// TODO: Add actual OpenAI API calls when credentials available
class OpenAIIntegration {
  final String? apiKey;
  final String model;

  OpenAIIntegration({
    this.apiKey,
    this.model = "gpt-4",
  });

  /// Generate conversational response using OpenAI
  /// For now, returns structured responses without LLM
  /// Later: call OpenAI API with behavioral context
  Future<String> generateConversationalResponse({
    required String userMessage,
    required ChatbotState systemState,
    required ResponseMode mode,
    required PressureLevel pressure,
    required List<ChatbotMessage> conversationContext,
  }) async {
    // TODO: Implement actual OpenAI call
    // For MVP: return rule-based response

    // Build context for OpenAI
    final systemPrompt = _buildSystemPrompt(systemState, mode, pressure);
    final contextMessages = _buildContextMessages(conversationContext);

    // Placeholder: return intelligent rule-based response
    return _generateRuleBasedResponse(userMessage, mode, pressure);
  }

  /// Build system prompt for OpenAI
  String _buildSystemPrompt(
    ChatbotState state,
    ResponseMode mode,
    PressureLevel pressure,
  ) {
    final tone = _getTone(mode, pressure);

    return """You are BUDDY, a behavioral performance assistant (not motivational, not analytical, not therapeutic).

Current state:
- Execution score: ${state.executionScore}%
- Instability: ${state.instabilityScore}%
- Discipline: ${state.disciplineScore}%

Tone: $tone
Mode: ${mode.name}
Pressure: ${pressure.name}

Rules:
1. No long explanations
2. No emotional padding
3. Focus on execution and behavior
4. If the user is avoiding, call it out
5. Redirect venting to coaching/library, never reopen in catch
6. Be direct. Be brief. Be actionable.""";
  }

  /// Build context from recent messages
  List<Map<String, String>> _buildContextMessages(
      List<ChatbotMessage> messages) {
    return messages.take(10).map((msg) {
      return {
        "role": msg.isFromUser ? "user" : "assistant",
        "content": msg.content,
      };
    }).toList();
  }

  /// Get tone based on mode and pressure
  String _getTone(ResponseMode mode, PressureLevel pressure) {
    if (pressure == PressureLevel.high) {
      return "firm, direct, no excuses";
    } else if (pressure == PressureLevel.medium) {
      return "pushing, practical, focused";
    } else {
      return "guiding, light, supportive";
    }
  }

  /// Rule-based response generator for MVP
  String _generateRuleBasedResponse(
    String userMessage,
    ResponseMode mode,
    PressureLevel pressure,
  ) {
    final lower = userMessage.toLowerCase();

    // Common patterns
    if (lower.contains('help') || lower.contains('what should')) {
      if (mode == ResponseMode.push) {
        return "Stop asking. You already know. Do it.";
      } else {
        return "Go to the library for theory. But for right now: execute.";
      }
    }

    if (lower.contains('feel') ||
        lower.contains('think') ||
        lower.contains('wonder')) {
      if (pressure == PressureLevel.high) {
        return "Not the time for analysis. Act first, think later.";
      } else {
        return "Noted. But focus on what you can control right now.";
      }
    }

    if (lower.contains('fail') ||
        lower.contains('off track') ||
        lower.contains('mess up')) {
      if (pressure == PressureLevel.high) {
        return "You're not. Keep going. Don't break the chain.";
      } else {
        return "One moment doesn't define you. Reset and continue.";
      }
    }

    // Default: return to execution
    if (mode == ResponseMode.push) {
      return "Clear your head. 3 reps. Now.";
    } else if (mode == ResponseMode.stabilize) {
      return "Stay steady. No changes. Repeat what worked.";
    } else {
      return "You know what to do. No excuses.";
    }
  }

  /// Placeholder for actual OpenAI API integration
  Future<Map<String, dynamic>> callOpenAI({
    required String prompt,
    required List<Map<String, String>> messages,
  }) async {
    // TODO: Implement real OpenAI API call
    // Example structure (implement later):
    /*
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': prompt},
          ...messages,
        ],
        'temperature': 0.7,
        'max_tokens': 150,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
    */

    return {"error": "OpenAI integration not yet implemented"};
  }
}
