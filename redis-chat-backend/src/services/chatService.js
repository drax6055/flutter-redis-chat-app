const { redis, KEYS, CONSTANTS } = require("../config/redis");
const { v4: uuidv4 } = require("uuid");

/**
 * Adds a user connection to the Redis Set.
 */
async function addUserConnection(userId, socketId) {
    await redis.sadd(KEYS.USER_CONNECTIONS(userId), socketId);
    // Refresh TTL for connection set if needed, but sets usually persist until user leaves
    // We can set an expiry if we want auto-cleanup of stale users, but manual cleanup is requested.
}

/**
 * Removes a user connection.
 * Returns true if the user has no more active connections.
 */
async function removeUserConnection(userId, socketId) {
    await redis.srem(KEYS.USER_CONNECTIONS(userId), socketId);
    const count = await redis.scard(KEYS.USER_CONNECTIONS(userId));
    return count === 0;
}

/**
 * Checks if a user is currently in a chat room.
 */
async function getUserActiveRoom(userId) {
    return await redis.get(KEYS.USER_ACTIVE_CHAT(userId));
}

/**
 * Initiates a chat between two users.
 * Returns { roomId, error }
 */
async function startChat(initiatorId, targetId) {
    // 1. Check if users are the same
    if (initiatorId === targetId) return { error: "Cannot chat with yourself" };

    // 2. Check if either user is already in a chat
    const [initiatorRoom, targetRoom] = await Promise.all([
        getUserActiveRoom(initiatorId),
        getUserActiveRoom(targetId),
    ]);

    if (initiatorRoom) return { error: "You are already in a chat", roomId: initiatorRoom };
    if (targetRoom) return { error: "User is busy", roomId: null };

    // 3. Create active chat keys using a transaction (basic check-then-set race condition possible but minimal here)
    // We use SETNX to ensure we don't overwrite if someone else filled it instantly
    const roomId = uuidv4();

    // Start Redis Transaction
    const pipeline = redis.pipeline();

    // Set active chat pointers
    pipeline.set(KEYS.USER_ACTIVE_CHAT(initiatorId), roomId, "NX", "EX", CONSTANTS.ROOM_TTL);
    pipeline.set(KEYS.USER_ACTIVE_CHAT(targetId), roomId, "NX", "EX", CONSTANTS.ROOM_TTL);

    // Add participants to room
    pipeline.sadd(KEYS.ROOM_PARTICIPANTS(roomId), initiatorId, targetId);
    pipeline.expire(KEYS.ROOM_PARTICIPANTS(roomId), CONSTANTS.ROOM_TTL);

    const results = await pipeline.exec();

    // results[0] and results[1] are the SETNX responses. If either validation failed (null), we revert.
    const initiatorSet = results[0][1];
    const targetSet = results[1][1];

    if (initiatorSet !== "OK" || targetSet !== "OK") {
        // Rollback basically involves deleting what we might have set. 
        // Simplified rollback:
        if (initiatorSet === "OK") await redis.del(KEYS.USER_ACTIVE_CHAT(initiatorId));
        if (targetSet === "OK") await redis.del(KEYS.USER_ACTIVE_CHAT(targetId));

        // If we failed, it means race condition or state changed
        return { error: "Failed to establish chat session (User busy)" };
    }

    return { roomId };
}

/**
 * Ends a chat room, deletes all messages and metadata.
 */
async function endChat(roomId) {
    if (!roomId) return;

    // Get participants to clear their status
    const participants = await redis.smembers(KEYS.ROOM_PARTICIPANTS(roomId));

    const pipeline = redis.pipeline();

    // Clear user active status
    participants.forEach((userId) => {
        pipeline.del(KEYS.USER_ACTIVE_CHAT(userId));
    });

    // Delete room data
    pipeline.del(KEYS.ROOM_PARTICIPANTS(roomId));
    pipeline.del(KEYS.ROOM_MESSAGES(roomId));

    await pipeline.exec();
    return participants;
}

/**
 * Adds a message to the room.
 */
async function addMessage(roomId, senderId, text) {
    const message = {
        id: uuidv4(),
        senderId,
        text,
        timestamp: new Date().toISOString(),
    };

    await redis.rpush(KEYS.ROOM_MESSAGES(roomId), JSON.stringify(message));
    // Refresh TTL on new activity
    await redis.expire(KEYS.ROOM_MESSAGES(roomId), CONSTANTS.MESSAGE_TTL);
    await redis.expire(KEYS.ROOM_PARTICIPANTS(roomId), CONSTANTS.ROOM_TTL);

    // Also refresh user status keys so they don't expire active chat while typing
    const participants = await redis.smembers(KEYS.ROOM_PARTICIPANTS(roomId));
    for (const p of participants) {
        await redis.expire(KEYS.USER_ACTIVE_CHAT(p), CONSTANTS.ROOM_TTL);
    }

    return message;
}

/**
 * Get all active connections for a specific user.
 * Used to broadcast events to all of a user's devices.
 */
async function getUserConnections(userId) {
    return await redis.smembers(KEYS.USER_CONNECTIONS(userId));
}

module.exports = {
    addUserConnection,
    removeUserConnection,
    startChat,
    endChat,
    addMessage,
    getUserActiveRoom,
    getUserConnections,
};
