import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  
  // User information
  Map<String, dynamic> userInfo = {};
  bool hasUserInfo = false;
  String currentQuestion = 'age'; 

  final String apiKey = 'YOUR_API_KEY_HERE';

  String get apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

  @override
  void initState() {
    super.initState();
    // Start with asking for age
    _addBotMessage("Hello! I'm your patient assistant. To provide you with personalized health advice, I need some basic information.\n\n**What is your age?**\n(Please provide just the number, e.g., 25)");
  }

  void _addBotMessage(String text) {
    setState(() {
      messages.add({
        'sender': 'bot',
        'text': text,
        'time': DateTime.now(),
      });
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      messages.add({
        'sender': 'user',
        'text': text,
        'time': DateTime.now(),
      });
    });
  }

  void _handleUserInfoCollection(String message) {
    final lowerMessage = message.toLowerCase().trim();
    
    switch (currentQuestion) {
      case 'age':
        final ageRegex = RegExp(r'(\d+)');
        final ageMatch = ageRegex.firstMatch(lowerMessage);
        if (ageMatch != null) {
          final age = int.tryParse(ageMatch.group(1) ?? '');
          if (age != null && age > 0 && age < 150) {
            userInfo['age'] = age;
            currentQuestion = 'sex';
            _addBotMessage("Thank you! You are ${age} years old.\n\n**What is your sex/gender?**\n(Please respond with 'male' or 'female')");
          } else {
            _addBotMessage("Please provide a valid age (between 1 and 150).");
          }
        } else {
          _addBotMessage("I didn't understand. Please provide your age as a number (e.g., 25).");
        }
        break;
        
      case 'sex':
        if (lowerMessage.contains('male') || lowerMessage.contains('man') || lowerMessage.contains('boy')) {
          userInfo['sex'] = 'male';
          currentQuestion = 'conditions';
          _addBotMessage("Thank you! You are male.\n\n**Do you have any existing medical conditions?**\n(Please respond with 'yes' or 'no', or list your conditions if any)");
        } else if (lowerMessage.contains('female') || lowerMessage.contains('woman') || lowerMessage.contains('girl')) {
          userInfo['sex'] = 'female';
          currentQuestion = 'conditions';
          _addBotMessage("Thank you! You are female.\n\n**Do you have any existing medical conditions?**\n(Please respond with 'yes' or 'no', or list your conditions if any)");
        } else {
          _addBotMessage("Please specify your sex/gender. Respond with 'male' or 'female'.");
        }
        break;
        
      case 'conditions':
        if (lowerMessage.contains('no') || lowerMessage.contains('none') || lowerMessage.contains('healthy')) {
          // No conditions
          _completeUserInfoCollection();
        } else if (lowerMessage.contains('yes') || lowerMessage.contains('diabetes') || lowerMessage.contains('hypertension') || 
                   lowerMessage.contains('asthma') || lowerMessage.contains('heart') || lowerMessage.contains('blood pressure')) {
          // Extract specific conditions
          if (lowerMessage.contains('diabetes') || lowerMessage.contains('diabetic')) {
            userInfo['diabetes'] = true;
          }
          if (lowerMessage.contains('hypertension') || lowerMessage.contains('high blood pressure')) {
            userInfo['hypertension'] = true;
          }
          if (lowerMessage.contains('asthma')) {
            userInfo['asthma'] = true;
          }
          if (lowerMessage.contains('heart') || lowerMessage.contains('cardiac')) {
            userInfo['heart_condition'] = true;
          }
          _completeUserInfoCollection();
        } else {
          _addBotMessage("Please respond with 'yes' or 'no', or list any medical conditions you have (like diabetes, hypertension, asthma, heart conditions, etc.).");
        }
        break;
    }
  }

  void _completeUserInfoCollection() {
    hasUserInfo = true;
    currentQuestion = 'complete';
    
    String conditionsText = "";
    if (userInfo.containsKey('diabetes')) conditionsText += "• Diabetes\n";
    if (userInfo.containsKey('hypertension')) conditionsText += "• Hypertension\n";
    if (userInfo.containsKey('asthma')) conditionsText += "• Asthma\n";
    if (userInfo.containsKey('heart_condition')) conditionsText += "• Heart condition\n";
    
    if (conditionsText.isEmpty) {
      conditionsText = "• None";
    }
    
    _addBotMessage("Perfect! I have collected your information:\n\n**Patient Profile:**\n• Age: ${userInfo['age']} years\n• Sex: ${userInfo['sex']}\n• Medical conditions:\n$conditionsText\n\nNow I can provide you with **personalized health advice** based on your profile. What health-related question do you have?");
  }

  // Function to send message to Gemini API
  Future<void> sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    final timestamp = DateTime.now();

    _addUserMessage(userMessage);
    isLoading = true;

    await Future.delayed(const Duration(milliseconds: 100)); // Ensure UI updates
    _scrollToBottom();

    // If user info is not collected yet, collect it
    if (!hasUserInfo) {
      _handleUserInfoCollection(userMessage);
      setState(() {
        isLoading = false;
      });
      _controller.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
      return;
    }

    try {
      // Build system instruction with user context
      String systemInstruction = "You are a patient assistance chatbot. Only respond to health-related queries. If a user asks something else, politely decline.\n\n";
      
      if (hasUserInfo) {
        systemInstruction += "Patient Information:\n";
        systemInstruction += "• Age: ${userInfo['age']} years\n";
        systemInstruction += "• Sex: ${userInfo['sex']}\n";
        if (userInfo.containsKey('diabetes')) systemInstruction += "• Diabetes: Yes\n";
        if (userInfo.containsKey('hypertension')) systemInstruction += "• Hypertension: Yes\n";
        if (userInfo.containsKey('asthma')) systemInstruction += "• Asthma: Yes\n";
        if (userInfo.containsKey('heart_condition')) systemInstruction += "• Heart condition: Yes\n";
        systemInstruction += "\nProvide personalized health advice based on this information. Always consider age and sex-specific factors in your recommendations.";
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {"text": systemInstruction}
            ]
          },
          "contents": [
            {
              "parts": [
                {"text": userMessage}
              ]
            }
          ]
        }),
      );

      final replyTime = DateTime.now();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final replyText =
            responseData['candidates'][0]['content']['parts'][0]['text'];

        _addBotMessage(replyText);
      } else {
        _addBotMessage('Error: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      _addBotMessage('Failed to connect: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
      _controller.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    }
  }

  // Auto-scroll to bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Format date/time for message timestamp
  String formatTimestamp(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Widget buildMessageBubble(String sender, String text, DateTime time) {
    final isUser = sender == 'user';
    return Container(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isUser ? Colors.teal[300] : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft:
                    isUser ? const Radius.circular(16) : const Radius.circular(0),
                bottomRight:
                    isUser ? const Radius.circular(0) : const Radius.circular(16),
              ),
            ),
            child: MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatTimestamp(time),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return const Center(
      child: Text(
        "Say hello to your patient assistant",
        style: TextStyle(fontSize: 18, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient ChatBot")),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: messages.isEmpty
                ? buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return buildMessageBubble(
                        msg['sender'],
                        msg['text'],
                        msg['time'],
                      );
                    },
                  ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CircularProgressIndicator(),
            ),
          // User input area
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : sendMessage,
                  child: const Text("Send"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
