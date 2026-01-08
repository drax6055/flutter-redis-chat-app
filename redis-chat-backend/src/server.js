const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const dotenv = require("dotenv");
const cors = require("cors");
const registerSocketHandlers = require("./socket/handlers");

const { redis } = require("./config/redis"); // Import redis to flush on start
dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const multer = require("multer");
const fs = require("fs");
const path = require("path");

// Ensure uploads dir exists and is empty on startup
const uploadDir = path.join(__dirname, "../uploads");

if (fs.existsSync(uploadDir)) {
    // Clear existing files
    fs.readdirSync(uploadDir).forEach((file) => {
        const curPath = path.join(uploadDir, file);
        // Simple unlink for now, assuming only files are created
        if (fs.lstatSync(curPath).isFile()) {
            fs.unlinkSync(curPath);
        }
    });
    console.log("Uploads directory cleared.");
} else {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const roomId = req.params.roomId;
        if (!roomId) {
            return cb(new Error("No Room ID provided"));
        }
        const roomDir = path.join(uploadDir, roomId);
        if (!fs.existsSync(roomDir)) {
            fs.mkdirSync(roomDir, { recursive: true });
        }
        cb(null, roomDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
        cb(null, uniqueSuffix + "-" + file.originalname);
    },
});

const upload = multer({ storage: storage });

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

// Static uploads
app.use("/uploads", express.static(uploadDir));

// Upload Endpoint
app.post("/upload/:roomId", upload.single("image"), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
    }
    const roomId = req.params.roomId;
    // Return relative path: /uploads/roomId/filename
    res.json({ imageUrl: `/uploads/${roomId}/${req.file.filename}` });
});

// Initialize Socket Handlers
registerSocketHandlers(io);

const PORT = process.env.PORT || 3000;

server.listen(PORT, async () => {
    try {
        await redis.flushall();
        console.log("Redis flushed for fresh ephemeral start.");
    } catch (e) {
        console.error("Failed to flush Redis:", e);
    }
    console.log(`Server running on port ${PORT}`);
});
