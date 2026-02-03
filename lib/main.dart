import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'models/message.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ChatProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodExpress Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  void autoScroll() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    chatProvider.sendMessage(text);
    _controller.clear();
    autoScroll();
    _focusNode.requestFocus();
  }

  void _changeBot(BuildContext context, String? bot) {
    if (bot == null) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.changeBot(bot);
    _focusNode.requestFocus();
  }

  bool shouldShowConfirmButton(String text) {
    final lower = text.toLowerCase();
    return lower.contains("confirm") && !lower.contains("confirmed");
  }

  Widget buildBubble(Message message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedBuilder(
          animation: _typingController,
          builder: (_, __) {
            int dots = (_typingController.value * 3).floor() + 1;
            return Text(
              "typing${"." * dots}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("FoodExpress Chatbot"),
        actions: [
          DropdownButton<String>(
            value: chatProvider.selectedBot,
            dropdownColor: Colors.deepPurple,
            underline: Container(),
            iconEnabledColor: Colors.white,
            items: chatProvider.bots.map((bot) {
              return DropdownMenuItem(
                value: bot,
                child: Text(
                  bot.toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (bot) => _changeBot(context, bot),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => chatProvider.clearMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount:
                  chatProvider.messages.length +
                  (chatProvider.isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (chatProvider.isBotTyping &&
                    index == chatProvider.messages.length) {
                  return typingIndicator();
                }

                final message = chatProvider.messages[index];
                final isUser = message.sender == 'user';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildBubble(message, isUser),
                    if (!isUser && shouldShowConfirmButton(message.text))
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 6),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text("Confirm Order"),
                          onPressed: () => _sendMessage(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // INPUT BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: () => _sendMessage(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
