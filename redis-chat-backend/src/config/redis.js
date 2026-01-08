const Redis = require("ioredis");
const dotenv = require("dotenv");

dotenv.config();

const redis = new Redis({
  host: process.env.REDIS_HOST || "localhost",
  port: process.env.REDIS_PORT || 6379,
});

redis.on("connect", () => {
  console.log("Connected to Redis");
});

redis.on("error", (err) => {
  console.error("Redis Connection Error:", err);
});

const CONSTANTS = {
  MESSAGE_TTL: parseInt(process.env.MESSAGE_TTL || "3600"),
  ROOM_TTL: parseInt(process.env.ROOM_TTL || "3600"),
};

const KEYS = {
  // Set: user:{userId}:connections -> {socketId}
  USER_CONNECTIONS: (userId) => `user:${userId}:connections`,
  
  // String: user:{userId}:active_chat -> {roomId}
  USER_ACTIVE_CHAT: (userId) => `user:${userId}:active_chat`,
  
  // Set: chat:room:{roomId}:participants -> {userId}
  ROOM_PARTICIPANTS: (roomId) => `chat:room:${roomId}:participants`,
  
  // List: chat:room:{roomId}:messages -> JSON strings
  ROOM_MESSAGES: (roomId) => `chat:room:${roomId}:messages`,
};

module.exports = { redis, KEYS, CONSTANTS };
