import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/chat_api.dart';
import '../models/message.dart';

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final List<String> bots = ['food', 'faq', 'sales'];
  String _selectedBot = 'food';
  late ChatApi _chatApi;
  bool _isBotTyping = false;

  ChatProvider() {
    _chatApi = ChatApi(bot: _selectedBot);
    _loadMessages();
  }

  List<Message> get messages => _messages;
  String get selectedBot => _selectedBot;
  bool get isBotTyping => _isBotTyping;

  void _loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? messageStrings = prefs.getStringList('messages');
    if (messageStrings != null) {
      _messages.clear();
      for (String msgStr in messageStrings) {
        try {
          Map<String, dynamic> msgMap = Map<String, dynamic>.from(
            msgStr as Map,
          );
          _messages.add(Message.fromJson(msgMap));
        } catch (e) {
          // Skip invalid messages
        }
      }
      notifyListeners();
    }
  }

  void _saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> messageStrings = _messages
        .map((msg) => msg.toJson().toString())
        .toList();
    await prefs.setStringList('messages', messageStrings);
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(Message(sender: 'user', text: text));
    _isBotTyping = true;
    notifyListeners();
    _saveMessages();

    try {
      String reply = await _chatApi.sendMessage(text);
      _messages.add(Message(sender: 'bot', text: reply));
    } catch (e) {
      _messages.add(
        Message(
          sender: 'bot',
          text: '❌ Error: Unable to get response. Please try again.',
        ),
      );
    } finally {
      _isBotTyping = false;
      notifyListeners();
      _saveMessages();
    }
  }

  void changeBot(String bot) {
    _selectedBot = bot;
    _messages.clear();
    _chatApi = ChatApi(bot: _selectedBot);
    notifyListeners();
    _saveMessages();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
    _saveMessages();
  }

  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
    _saveMessages();
  }
}
