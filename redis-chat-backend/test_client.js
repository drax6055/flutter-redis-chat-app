const { io } = require("socket.io-client");

const SERVER_URL = "http://localhost:3000";

// Simulation: User A and User B
const userA = "Alice";
const userB = "Bob";

function createClient(userId) {
    const socket = io(SERVER_URL, {
        query: { userId },
    });

    socket.on("connect", () => {
        console.log(`[${userId}] Connected with ID: ${socket.id}`);
    });

    socket.on("chat_started", ({ roomId, participants }) => {
        console.log(`[${userId}] Chat started! Room: ${roomId}, Participants: ${participants}`);
        // Simulate sending a message
        if (userId === userA) {
            setTimeout(() => {
                console.log(`[${userId}] Sending message...`);
                socket.emit("send_message", { roomId, message: "Hello Bob!" });
            }, 1000);
        }
    });

    socket.on("new_message", (msg) => {
        console.log(`[${userId}] Received: ${msg.senderId} says "${msg.text}"`);

        // Bob replies
        if (userId === userB && msg.senderId === userA) {
            setTimeout(() => {
                const roomId = "UNKNOWN"; // In real app, store roomId from chat_started.
                // But for this test, we need roomId. 
                // We can capture it from closure or state.
            }, 500);
        }
    });

    // Handling message reply needs state, let's simplify logic
    return socket;
}

const socketA = createClient(userA);
const socketB = createClient(userB);

// Wait for connection then start chat
setTimeout(() => {
    console.log("--- Alice starting chat with Bob ---");
    socketA.emit("start_chat", { targetUserId: userB });
}, 1000);

// Capture room ID for Bob to reply
let activeRoomId = null;
socketB.on("chat_started", ({ roomId }) => {
    activeRoomId = roomId;
});

socketB.on("new_message", (msg) => {
    if (msg.senderId === userA && activeRoomId) {
        setTimeout(() => {
            console.log(`[${userB}] Replying...`);
            socketB.emit("send_message", { roomId: activeRoomId, message: "Hi Alice, how are you?" });
        }, 1000);
    }
});

socketA.on("new_message", (msg) => {
    if (msg.senderId === userB) {
        setTimeout(() => {
            console.log("--- Alice ending chat ---");
            socketA.emit("end_chat");
        }, 2000);
    }
});

socketA.on("chat_ended", () => {
    console.log(`[${userA}] Chat ended. Disconnecting...`);
    socketA.disconnect();
});

socketB.on("chat_ended", () => {
    console.log(`[${userB}] Chat ended. Disconnecting...`);
    socketB.disconnect();
});
