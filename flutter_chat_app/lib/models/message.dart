class Message {
  final String id;
  final String senderId;
  final String text;
  final String timestamp;
  final bool isMe;
  final bool isEdited;
  final Map<String, dynamic>? replyTo;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isEdited = false,
    this.replyTo,
  });

  factory Message.fromJson(Map<String, dynamic> json, String myUserId) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? 'Unknown',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? '',
      isMe: json['senderId'] == myUserId,
      isEdited: json['isEdited'] ?? false,
      replyTo: json['replyTo'] != null
          ? Map<String, dynamic>.from(json['replyTo'])
          : null,
    );
  }
}
