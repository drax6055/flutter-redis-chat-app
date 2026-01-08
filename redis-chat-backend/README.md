# Redis Chat Backend

A backend-only 1-to-1 chat application using Node.js, Express, Socket.IO, and Redis.
All data is ephemeral and stored exclusively in Redis with TTLs.

## Prerequisites

1.  **Node.js** (v14+)
2.  **Redis** running locally on port `6379` (or configure via `.env`).

## Installation

1.  Clone/Navigate to the directory.
2.  Install dependencies:
    ```bash
    npm install
    ```

## Configuration

Edit `.env` if needed:
```env
PORT=3000
REDIS_HOST=localhost
REDIS_PORT=6379
MESSAGE_TTL=3600
ROOM_TTL=3600
```

## Running the Server

```bash
npm start
# OR for development
npx nodemon src/server.js
```

## Architecture & Data Model

-   **User Connections**: `user:{userId}:connections` (Set)
-   **Active Chat**: `user:{userId}:active_chat` (String -> roomId)
-   **Room Participants**: `chat:room:{roomId}:participants` (Set)
-   **Messages**: `chat:room:{roomId}:messages` (List of JSON)

## Socket.IO Events

### Client -> Server

1.  **Connection**: connect with query `?userId=USERNAME`
2.  **start_chat**: `{ targetUserId: "otherUser" }`
3.  **send_message**: `{ roomId, message: "Hello" }`
4.  **end_chat**: `{}`
5.  **disconnect**

### Server -> Client

1.  **chat_started**: `{ roomId, participants: [] }`
2.  **new_message**: `{ id, senderId, text, timestamp }`
3.  **chat_ended**: `{ roomId }`
4.  **error**: `{ message }`

## Testing with Client Script

A simple test script `test_client.js` is provided to simulate a chat between `UserA` and `UserB`.

1.  Start the server in one terminal: `npm start`
2.  Run the test client in another:
    ```bash
    node test_client.js
    ```
