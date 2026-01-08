import 'package:flutter/material.dart';
import 'package:flutter_chat_app/services/socket_service.dart';
import 'package:flutter_chat_app/screens/chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _targetController = TextEditingController();
  final _socketService = SocketService();
  StreamSubscription? _chatStartedSub;
  StreamSubscription? _errorSub;

  @override
  void initState() {
    super.initState();
    _chatStartedSub = _socketService.chatStartedStream.listen((data) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    });

    _errorSub = _socketService.errorStream.listen((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    });
  }

  @override
  void dispose() {
    _chatStartedSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  void _startChat() {
    if (_targetController.text.isEmpty) return;
    _socketService.startChat(_targetController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, ${_socketService.currentUserId}",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Start a new chat",
              style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                hintText: "Enter Friend's User ID",
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _startChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Start Chat",
                  style: GoogleFonts.outfit(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
