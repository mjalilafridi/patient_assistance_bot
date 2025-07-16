import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const PatientChatBotApp());
}

class PatientChatBotApp extends StatelessWidget {
  const PatientChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient ChatBot',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
