import 'package:flutter/material.dart';
import 'package:flutter_chat_app/services/socket_service.dart';
import 'package:flutter_chat_app/screens/chat_screen.dart';
import 'package:flutter_chat_app/widgets/responsive_layout.dart';
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
  StreamSubscription? _chatEndedSub;

  bool _isChatActive = false;

  @override
  void initState() {
    super.initState();
    _chatStartedSub = _socketService.chatStartedStream.listen((data) {
      if (!mounted) return;
      if (ResponsiveLayout.isMobile(context)) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      } else {
        setState(() {
          _isChatActive = true;
        });
      }
    });

    _chatEndedSub = _socketService.chatEndedStream.listen((_) {
      if (!mounted) return;
      // On desktop, we need to hide the chat panel
      if (!ResponsiveLayout.isMobile(context)) {
        setState(() {
          _isChatActive = false;
        });
      }
    });

    _errorSub = _socketService.errorStream.listen((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  void dispose() {
    _chatStartedSub?.cancel();
    _errorSub?.cancel();
    _chatEndedSub?.cancel();
    _targetController.dispose();
    super.dispose();
  }

  void _startChat() {
    if (_targetController.text.isEmpty) return;
    _socketService.startChat(_targetController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildHomeContent(context),
      desktopBody: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Row(
          children: [
            SizedBox(
              width: 350,
              child: _buildHomeContent(context, isDesktopSideBar: true),
            ),
            const VerticalDivider(width: 1, color: Color(0xFF333333)),
            Expanded(
              child: _isChatActive
                  ? const ChatScreen(isEmbedded: true)
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context, {
    bool isDesktopSideBar = false,
  }) {
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

  Widget _buildEmptyState() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              "Select a user to start chatting",
              style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
