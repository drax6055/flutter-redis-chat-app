import 'package:flutter/material.dart';
import 'package:flutter_chat_app/models/message.dart';
import 'package:flutter_chat_app/services/socket_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final bool isEmbedded;

  const ChatScreen({super.key, this.isEmbedded = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _socketService = SocketService();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();

  Message? _replyToMessage;

  StreamSubscription? _msgSub;
  StreamSubscription? _endSub;
  StreamSubscription? _msgUpdateSub;
  StreamSubscription? _msgDeleteSub;

  String? _editingMessageId;

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

    _msgUpdateSub = _socketService.messageUpdatedStream.listen((data) {
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == data['id']);
        if (index != -1) {
          _messages[index] = Message.fromJson(
            data,
            _socketService.currentUserId!,
          );
        }
      });
    });

    _msgDeleteSub = _socketService.messageDeletedStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == data['messageId']);
      });
    });

    _endSub = _socketService.chatEndedStream.listen((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chat ended")));
      if (!widget.isEmbedded) {
        Navigator.pop(context);
      }
    });

    // Initial scroll
    // _scrollToBottom();
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
    _msgUpdateSub?.cancel();
    _msgDeleteSub?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    if (_editingMessageId != null) {
      // Edit Mode
      _socketService.editMessage(_editingMessageId!, _controller.text.trim());
      setState(() {
        _editingMessageId = null;
      });
      _controller.clear();
      return;
    }

    Map<String, dynamic>? replyData;
    if (_replyToMessage != null) {
      replyData = {
        'id': _replyToMessage!.id,
        'senderId': _replyToMessage!.senderId,
        'text': _replyToMessage!.text,
      };
    }

    _socketService.sendMessage(_controller.text.trim(), replyData);
    _controller.clear();
    setState(() {
      _replyToMessage = null;
    });
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
        automaticallyImplyLeading: !widget.isEmbedded,
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
                return Dismissible(
                  key: UniqueKey(), // Ideally use msg.id if available
                  direction: DismissDirection.startToEnd,
                  confirmDismiss: (direction) async {
                    setState(() {
                      _replyToMessage = msg;
                    });
                    return false; // Don't actually dismiss
                  },
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.reply, color: Colors.white),
                  ),
                  child: GestureDetector(
                    onLongPress: () => _showMessageOptions(msg),
                    child: _buildMessageBubble(msg, context),
                  ),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, BuildContext context) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: msg.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
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
            Container(
              padding: const EdgeInsets.all(
                8,
              ), // Reduced padding for better nesting
              decoration: BoxDecoration(
                color: msg.isMe
                    ? const Color(0xFF333333)
                    : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: msg.isMe
                      ? const Radius.circular(12)
                      : Radius.zero,
                  bottomRight: msg.isMe
                      ? Radius.zero
                      : const Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reply Preview INSIDE the bubble
                  if (msg.replyTo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: msg.isMe
                            ? const Color(0xFF333333)
                            : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: const Color(0xFF6C63FF),
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.replyTo!['senderId'] ?? 'Unknown',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF6C63FF), // Contrast
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg.replyTo!['text'] ?? '',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  // Main Message Text
                  Text(
                    msg.text,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (msg.isEdited)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "(edited)",
                        style: GoogleFonts.outfit(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: Column(
        children: [
          if (_replyToMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: const Color(0xFF6C63FF), width: 4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Replying to ${_replyToMessage!.senderId}",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _replyToMessage!.text,
                          style: GoogleFonts.outfit(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () => setState(() => _replyToMessage = null),
                  ),
                ],
              ),
            ),
          if (_editingMessageId != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: Colors.yellow, width: 4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.yellow, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Editing message...",
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () {
                      setState(() {
                        _editingMessageId = null;
                        _controller.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
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
                  icon: Icon(
                    _editingMessageId != null ? Icons.check : Icons.send,
                    color: _editingMessageId != null
                        ? Colors.yellow
                        : const Color(0xFF6C63FF),
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Message msg) {
    if (!msg.isMe) return; // Can only edit/delete own messages

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: Text(
                  "Edit",
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context); // Close modal
                  setState(() {
                    _replyToMessage = null; // Clear reply if any
                    _editingMessageId = msg.id;
                    _controller.text = msg.text;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  "Delete",
                  style: GoogleFonts.outfit(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context); // Close modal
                  _socketService.deleteMessage(msg.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
