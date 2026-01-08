import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  IO.Socket? _socket;
  final _messageController = StreamController<dynamic>.broadcast();
  final _chatStartedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatEndedController = StreamController<void>.broadcast();
  final _messageUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get chatStartedStream =>
      _chatStartedController.stream;
  Stream<void> get chatEndedStream => _chatEndedController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<Map<String, dynamic>> get messageUpdatedStream =>
      _messageUpdatedController.stream;
  Stream<Map<String, dynamic>> get messageDeletedStream =>
      _messageDeletedController.stream;

  String? _currentUserId;
  String? _currentRoomId;

  String? get currentUserId => _currentUserId;
  String? get currentRoomId => _currentRoomId;

  // Connection
  void connect(String userId) {
    _currentUserId = userId;

    // Default to the provided IP, which works for:
    // 1. Real Device (Required)
    // 2. Emulator (Usually works via bridge)
    // 3. Web (If testing on same network)
    // --------------------------------------------------------
    // TODO: Replace this with your copied Render URL
    const String productionUrl = 'https://flutter-redis-chat-app.onrender.com';
    // --------------------------------------------------------

    // Automatically switch to production URL if running in Release mode (Production)
    String serverUrl = kReleaseMode
        ? productionUrl
        : 'http://192.168.29.39:3000';

    // We keep the platform check structure for robustness,
    // but we use the IP address to support the Real Device.
    // 10.0.2.2 only works on Emulator and would BREAK the Real Device.
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Use IP for Real Device support.
        // If you were ONLY using Emulator, you could use 'http://10.0.2.2:3000'
        serverUrl = 'http://192.168.29.39:3000';
      }
    } catch (e) {
      // Fallback for Web or other platforms
    }

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['polling', 'websocket'])
          .disableAutoConnect()
          .setQuery({'userId': userId})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Connected to server as $userId');
    });

    _socket!.onDisconnect((_) {
      print('Disconnected from server');
    });

    _socket!.onConnectError((data) {
      print('Connect Error: $data');
      _errorController.add("Connection Error: $data");
    });

    // Custom Events
    _socket!.on('chat_started', (data) {
      print('Chat Started: $data');
      _currentRoomId = data['roomId'];
      _chatStartedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('new_message', (data) {
      print('New Message: $data');
      _messageController.add(data);
    });

    _socket!.on('message_updated', (data) {
      print('Message Updated: $data');
      _messageUpdatedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('message_deleted', (data) {
      print('Message Deleted: $data');
      _messageDeletedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('chat_ended', (data) {
      print('Chat Ended');
      _currentRoomId = null;
      _chatEndedController.add(null);
    });

    _socket!.on('error', (data) {
      print('Socket Error: $data');
      if (data is Map && data.containsKey('message')) {
        _errorController.add(data['message']);
      } else {
        _errorController.add(data.toString());
      }
    });
  }

  void startChat(String targetUserId) {
    if (_socket == null) return;
    print('Requesting chat with $targetUserId');
    _socket!.emit('start_chat', {'targetUserId': targetUserId});
  }

  void sendMessage(
    String text, {
    Map<String, dynamic>? replyTo,
    String? imageUrl,
  }) {
    if (_currentRoomId == null || _socket == null) return;
    _socket!.emit('send_message', {
      'roomId': _currentRoomId,
      'message': text,
      if (replyTo != null) 'replyTo': replyTo,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
  }

  void editMessage(String messageId, String newText) {
    if (_currentRoomId == null || _socket == null) return;
    _socket!.emit('edit_message', {
      'roomId': _currentRoomId,
      'messageId': messageId,
      'newText': newText,
    });
  }

  void deleteMessage(String messageId) {
    if (_currentRoomId == null || _socket == null) return;
    _socket!.emit('delete_message', {
      'roomId': _currentRoomId,
      'messageId': messageId,
    });
  }

  // Upload image to backend and return URL
  Future<String?> uploadImage(XFile file) async {
    // You might need to change localhost to IP if on real device, similar to connect() logic
    String baseUrl = 'http://192.168.29.39:3000';
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000';
    }

    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);

    // Cross-platform file reading
    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: file.name),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final match = RegExp(r'"imageUrl":"(.*?)"').firstMatch(respStr);
        return match?.group(1);
      }
    } catch (e) {
      print("Upload failed: $e");
    }
    return null;
  }

  void endChat() {
    _socket?.emit('end_chat');
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _currentUserId = null;
    _currentRoomId = null;
  }
}
