# Flutter Redis Real-time Chat App

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![NodeJS](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Redis](https://img.shields.io/badge/redis-%23DD0031.svg?style=for-the-badge&logo=redis&logoColor=white)
![Socket.io](https://img.shields.io/badge/Socket.io-010101?style=for-the-badge&logo=socket.io&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)

A high-performance, real-time 1-to-1 chat application built with **Flutter 3.x** and a **Node.js** backend powered by **Redis** for ephemeral message storage and **Socket.io** for instant bidirectional communication.

## 🚀 Features

*   **Real-time Messaging**: Instant message delivery using Socket.io (WebSocket).
*   **Ephemeral Chat**: Messages are stored in Redis with TTL (Time-To-Live), ensuring privacy and automatic cleanup.
*   **Cross-Platform**: Flutter app runs on Android, iOS, and Web.
*   **Scalable Backend**: Designed with Redis for high-speed read/write operations.
*   **Modern UI**: Dark-themed, premium interface using Google Fonts (Outfit).
*   **Status Updates**: Real-time "Chat Started" and "Chat Ended" notifications.

## 🛠️ Tech Stack

### Frontend (Mobile/Web)
*   **Framework**: [Flutter](https://flutter.dev/)
*   **Networking**: `socket_io_client`
*   **Typography**: `google_fonts`
*   **State Management**: `setState` / `StreamController`

### Backend (Server)
*   **Runtime**: [Node.js](https://nodejs.org/)
*   **Framework**: [Express.js](https://expressjs.com/)
*   **Real-time Engine**: [Socket.io](https://socket.io/)
*   **Database**: [Redis](https://redis.io/) (used for session management and message buffer)

## 📂 Project Structure

```bash
├── flutter_chat_app/      # Flutter application source code
│   ├── lib/
│   │   ├── models/        # Data models (Message)
│   │   ├── screens/       # UI Screens (Login, Home, Chat)
│   │   └── services/      # SocketService singleton
│   └── pubspec.yaml
│
└── redis-chat-backend/    # Node.js Server source code
    ├── src/
    │   ├── config/        # Redis configuration
    │   ├── services/      # Chat business logic
    │   ├── socket/        # Socket.io event handlers
    │   └── server.js      # Entry point
    └── package.json
```

## ⚡ Getting Started

### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
*   [Node.js](https://nodejs.org/) (v16+) installed.
*   [Redis](https://redis.io/) server running locally or via Docker.

### 1. Setup Backend
Navigate to the backend directory, install dependencies, and start the server.

```bash
cd redis-chat-backend

# Install dependencies
npm install

# Start Redis (if using Docker)
# docker run --name redis-chat -p 6379:6379 -d redis

# Start the server
npm start
```
*The server works on port `3000` by default.*

### 2. Setup Frontend (Flutter)
Navigate to the app directory, install dependencies, and run.

```bash
cd flutter_chat_app

# Get packages
flutter pub get

# Run on Android Emulator or Real Device
flutter run
```

> **Note for Real Devices**: The app is configured to connect to `192.168.29.39:3000`. Ensure your phone and computer are on the same Wi-Fi network and your firewall allows connections on port 3000.

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any enhancements or bug fixes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
