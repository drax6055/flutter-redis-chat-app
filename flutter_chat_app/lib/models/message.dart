class Message {
  final String senderId;
  final String text;
  final String timestamp;
  final bool isMe;
  final Map<String, dynamic>? replyTo;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.replyTo,
  });

  factory Message.fromJson(Map<String, dynamic> json, String myUserId) {
    return Message(
      senderId: json['senderId'] ?? 'Unknown',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? '',
      isMe: json['senderId'] == myUserId,
      replyTo: json['replyTo'] != null
          ? Map<String, dynamic>.from(json['replyTo'])
          : null,
    );
  }
}
