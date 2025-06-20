import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/chatbot_controller.dart';
import '../model/message_model.dart';
import 'graph_data_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Flag to ensure welcome message is added only once.
  bool _didInit = false;

  // Quick replies mapping: displayed text and the actual prompt to send.
  final List<Map<String, String>> quickReplies = [
    {
      'display': 'Revenue figure',
      'prompt': 'Show me the revenue figures for the last quarter.',
    },
    {'display': 'Top selling event', 'prompt': 'Top selling events?'},
    {'display': 'Top selling packages', 'prompt': 'Top selling packages.'},
    {'display': 'Customer insights', 'prompt': 'Give me customer insights.'},
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageItem(Message message) {
    final isUser = message.isUser;
    final timeString =
        "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')} ${message.timestamp.hour >= 12 ? 'PM' : 'AM'}";

    // Create the message content.
    Widget messageContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFFE74C3C) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeString,
                style: TextStyle(
                  color: isUser ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              if (isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.done_all, size: 14, color: Colors.white70),
                ),
            ],
          ),
        ],
      ),
    );

    // If this bot message contains raw analytics data, wrap it in an InkWell.
    if (!isUser && message.additionalData != null) {
      messageContent = InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => GraphDataScreen(rawJson: message.additionalData),
            ),
          );
        },
        child: messageContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [Flexible(child: messageContent)],
      ),
    );
  }

  Widget _buildQuickReplies(ChatbotController chatbotController) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        itemBuilder: (context, index) {
          final quickReply = quickReplies[index];
          return GestureDetector(
            onTap: () {
              // When tapped, send the internal prompt message.
              chatbotController.sendMessage(quickReply['prompt']!);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(      
                child: Text(
                  quickReply['display']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(ChatbotController chatbotController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Write your message',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 8,
                ),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  chatbotController.sendMessage(text);
                  _textController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.grey.shade600),
              onPressed: () {
                if (_textController.text.trim().isNotEmpty) {
                  chatbotController.sendMessage(_textController.text);
                  _textController.clear();
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatbotController(),
      child: Consumer<ChatbotController>(
        builder: (context, chatbotController, _) {
          // Inject welcome message if not already added.
          if (!_didInit && chatbotController.messages.isEmpty) {
            _didInit = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              chatbotController.clearChat();
              final welcomeMessage = Message(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: "hi, how can i help you",
                isUser: false,
                timestamp: DateTime.now(),
              );
              chatbotController.messages.add(welcomeMessage);
              chatbotController.notifyListeners();
            });
          }

          if (chatbotController.messages.isNotEmpty) {
            _scrollToBottom();
          }
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Center(
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "Z",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [SizedBox(width: 48)],
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  child: Text(
                    'Today',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
                Expanded(
                  child:
                      chatbotController.messages.isEmpty
                          ? Center(child: Text('Start a conversation!'))
                          : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: chatbotController.messages.length,
                            itemBuilder: (context, index) {
                              final message = chatbotController.messages[index];
                              return _buildMessageItem(message);
                            },
                          ),
                ),
                // Quick reply section above the input field.
                _buildQuickReplies(chatbotController),
                _buildInputArea(chatbotController),
              ],
            ),
          );
        },
      ),
    );
  }
}
