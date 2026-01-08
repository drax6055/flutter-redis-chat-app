const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const dotenv = require("dotenv");
const cors = require("cors");
const registerSocketHandlers = require("./socket/handlers");

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);

const io = new Server(server, {
    cors: {
        origin: "*", // Allow all for demo
        methods: ["GET", "POST"],
    },
});

// Basic endpoint
app.get("/", (req, res) => {
    res.send("Redis Chat Backend is running.");
});

// Initialize Socket Handlers
registerSocketHandlers(io);

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
