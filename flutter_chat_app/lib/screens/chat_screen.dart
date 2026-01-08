import 'package:flutter/material.dart';
import 'package:flutter_chat_app/models/message.dart';
import 'package:flutter_chat_app/services/socket_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _socketService = SocketService();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _msgSub;
  StreamSubscription? _endSub;

  @override
  void initState() {
    super.initState();
    _msgSub = _socketService.messageStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _messages.add(Message.fromJson(data, _socketService.currentUserId!));
      });
      _scrollToBottom();
    });

    _endSub = _socketService.chatEndedStream.listen((_) {
      if (!mounted) return;
      Navigator.pop(context); // Go back to Home
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chat ended")));
    });
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

  @override
  void dispose() {
    _msgSub?.cancel();
    _endSub?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    _socketService.sendMessage(_controller.text.trim());
    _controller.clear();
  }

  void _endChat() {
    _socketService.endChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text("Chat", style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF2A2A2A),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _endChat,
            tooltip: "End Chat",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isMe
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF333333),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: msg.isMe
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomRight: msg.isMe
                            ? Radius.zero
                            : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!msg.isMe) ...[
                          Text(
                            msg.senderId,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          msg.text,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2A2A2A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
