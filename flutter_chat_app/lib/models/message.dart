class Message {
  final String senderId;
  final String text;
  final String timestamp;
  final bool isMe;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  factory Message.fromJson(Map<String, dynamic> json, String myUserId) {
    return Message(
      senderId: json['senderId'] ?? 'Unknown',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? '',
      isMe: json['senderId'] == myUserId,
    );
  }
}
