const chatService = require("../services/chatService");

module.exports = (io) => {
    io.on("connection", async (socket) => {
        const userId = socket.handshake.query.userId;
        const connectionId = socket.id;

        if (!userId) {
            console.log(`Connection rejected: No userId provided for socket ${connectionId}`);
            socket.disconnect();
            return;
        }

        console.log(`User ${userId} connected as ${connectionId}`);

        // store connection
        await chatService.addUserConnection(userId, connectionId);

        // If user is already in an active chat due to another device, join this socket too
        const activeRoomId = await chatService.getUserActiveRoom(userId);
        if (activeRoomId) {
            socket.join(activeRoomId);
            console.log(`User ${userId} auto-joined existing active room ${activeRoomId}`);
            // Optional: Send current messages to the new connection
            // const messages = await chatService.getRoomMessages(activeRoomId); // Not strictly implemented but useful
        }

        // --- EVENTS ---

        // Start Chat
        socket.on("start_chat", async ({ targetUserId }) => {
            console.log(`User ${userId} requesting chat with ${targetUserId}`);

            const { roomId, error } = await chatService.startChat(userId, targetUserId);

            if (error) {
                socket.emit("error", { message: error });
                return;
            }

            // Success: Make all user's sockets join the room (sync multiple tabs)
            // We need to fetch all connections for both users
            const userSockets = await chatService.getUserConnections(userId);
            const targetSockets = await chatService.getUserConnections(targetUserId);

            [...userSockets, ...targetSockets].forEach((sockId) => {
                const sock = io.sockets.sockets.get(sockId);
                if (sock) {
                    sock.join(roomId);
                    sock.emit("chat_started", { roomId, participants: [userId, targetUserId] });
                }
            });
        });

        // Send Message
        socket.on("send_message", async ({ message, roomId, replyTo }) => {
            // Validate user is actually in this room
            const currentRoom = await chatService.getUserActiveRoom(userId);
            if (currentRoom !== roomId) {
                socket.emit("error", { message: "You are not in this chat room" });
                return;
            }

            const msgObj = await chatService.addMessage(roomId, userId, message, replyTo);

            // Broadcast to room (includes self)
            io.to(roomId).emit("new_message", msgObj);
        });

        // End Chat
        socket.on("end_chat", async () => {
            const roomId = await chatService.getUserActiveRoom(userId);
            if (roomId) {
                await terminateChat(roomId);
            }
        });

        // Disconnect
        socket.on("disconnect", async () => {
            console.log(`User ${userId} disconnected ${connectionId}`);

            const isUserOffline = await chatService.removeUserConnection(userId, connectionId);

            if (isUserOffline) {
                console.log(`User ${userId} is now offline. Cleaning up active chats...`);
                // If last connection, end chat
                const roomId = await chatService.getUserActiveRoom(userId);
                if (roomId) {
                    await terminateChat(roomId);
                }
            }
        });

        // Helper to cleanup and notify
        async function terminateChat(roomId) {
            const participants = await chatService.endChat(roomId);
            if (participants) {
                // Notify all sockets in the room
                io.to(roomId).emit("chat_ended", { roomId });
                // Make sockets leave
                io.in(roomId).socketsLeave(roomId);
            }
        }
    });
};
