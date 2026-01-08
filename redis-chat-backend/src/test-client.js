const io = require("socket.io-client");

const SERVER_URL = "http://localhost:3000";

const user1Id = `user_A_${Date.now()}`;
const user2Id = `user_B_${Date.now()}`;

function createClient(userId) {
    const socket = io(SERVER_URL, {
        query: { userId },
    });

    socket.on("connect", () => {
        console.log(`[${userId}] Connected with socket ID: ${socket.id}`);
    });

    socket.on("disconnect", () => {
        console.log(`[${userId}] Disconnected`);
    });

    socket.on("error", (err) => {
        console.error(`[${userId}] Error:`, err);
    });

    socket.on("chat_started", (data) => {
        console.log(`[${userId}] Chat started! Room: ${data.roomId}, Participants: ${data.participants}`);
    });

    socket.on("new_message", (msg) => {
        console.log(`[${userId}] New Message from ${msg.senderId}: ${msg.text} (at ${msg.timestamp})`);
    });

    socket.on("chat_ended", (data) => {
        console.log(`[${userId}] Chat ended for Room: ${data.roomId}`);
    });

    return socket;
}


// Refined version to capture roomId
const runTest = async () => {
    const socketA = createClient(user1Id);
    const socketB = createClient(user2Id);

    // Helper to wait for an event
    const waitForEvent = (socket, event) => {
        return new Promise((resolve) => {
            socket.once(event, resolve);
        });
    };

    console.log("Waiting for connections...");
    await Promise.all([
        waitForEvent(socketA, "connect"),
        waitForEvent(socketB, "connect")
    ]);

    console.log("\n--- Starting Chat ---");
    socketA.emit("start_chat", { targetUserId: user2Id });

    const chatStartedData = await waitForEvent(socketA, "chat_started");
    const roomId = chatStartedData.roomId;
    console.log(`\n*** Session Established. Room ID: ${roomId} ***\n`);

    console.log(`--- ${user1Id} sending message ---`);
    socketA.emit("send_message", { roomId, message: "Hello User B!" });

    // Wait for B to receive
    await waitForEvent(socketB, "new_message");

    console.log(`\n--- ${user2Id} sending reply ---`);
    socketB.emit("send_message", { roomId, message: "Hi User A, nice to meet you!" });

    // Wait for A to receiving
    await waitForEvent(socketA, "new_message");

    console.log(`\n--- ${user1Id} ending chat ---`);
    socketA.emit("end_chat");

    await Promise.all([
        waitForEvent(socketA, "chat_ended"),
        waitForEvent(socketB, "chat_ended")
    ]);

    console.log("\n*** Test Complete. Disconnecting... ***");
    socketA.disconnect();
    socketB.disconnect();
};

runTest();
