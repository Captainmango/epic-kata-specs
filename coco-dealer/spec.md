# coco-dealer Specification

## Overview

coco-dealer is a card dealing service that manages decks of cards, assigns them to game rooms, and deals cards to players via HTTP and WebSocket APIs.

## System Behaviors

### Core Capabilities

1. **Deck Management** - Create, store, and manage decks of playing cards
2. **Room Assignment** - Assign decks to game rooms (one deck per room)
3. **Card Dealing** - Draw cards from decks via HTTP or WebSocket
4. **State Persistence** - Maintain deck state across operations

## Card Format Specification

### Card Code Format

Each card is represented by a 2-character code:

- **Value**: `2-9`, `0` (10), `J` (Jack), `Q` (Queen), `K` (King), `A` (Ace)
- **Suit**: `S` (Spades), `H` (Hearts), `D` (Diamonds), `C` (Clubs)

Examples: `AS` (Ace of Spades), `KH` (King of Hearts), `0D` (10 of Diamonds)

### Standard 52-Card Deck

```
AS, 2S, 3S, 4S, 5S, 6S, 7S, 8S, 9S, 0S, JS, QS, KS
AH, 2H, 3H, 4H, 5H, 6H, 7H, 8H, 9H, 0H, JH, QH, KH
AD, 2D, 3D, 4D, 5D, 6D, 7D, 8D, 9D, 0D, JD, QD, KD
AC, 2C, 3C, 4C, 5C, 6C, 7C, 8C, 9C, 0C, JC, QC, KC
```

### Card Value Mapping

| Code | Value | Suit |
|------|-------|------|
| AS | ACE | SPADES |
| 2H | 2 | HEARTS |
| KD | KING | DIAMONDS |
| 0C | 10 | CLUBS |

Full mapping:
- Values: `2-10`, `JACK`, `QUEEN`, `KING`, `ACE`
- Suits: `SPADES`, `HEARTS`, `DIAMONDS`, `CLUBS`

## Data Contracts

### Deck Object

```json
{
  "deck_id": "uuid-v4",
  "room_id": "string | null",
  "is_shuffled": true,
  "cards": ["AS", "KH", "0D"],
  "drawn_cards": [],
  "remaining": 52,
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

Fields:
- `deck_id`: Unique identifier for the deck
- `room_id`: ID of assigned room, or null if unassigned
- `is_shuffled`: Whether the deck was shuffled at creation
- `cards`: Array of remaining card codes (order matters - top of deck first)
- `drawn_cards`: Array of cards already drawn from this deck
- `remaining`: Count of cards remaining
- `created_at`: ISO 8601 timestamp of creation
- `updated_at`: ISO 8601 timestamp of last modification

### Card Object

```json
{
  "value": "QUEEN",
  "suit": "HEARTS",
  "code": "QH"
}
```

Fields:
- `value`: Card value (2-10, JACK, QUEEN, KING, ACE)
- `suit`: Card suit (SPADES, HEARTS, DIAMONDS, CLUBS)
- `code`: 2-character card code

### Error Response

```json
{
  "type": "error",
  "data": null,
  "error": "ErrorCode",
  "message": "Human-readable error message"
}
```

## API Behaviors

### HTTP Endpoints

| Method | Endpoint | Behavior |
|--------|----------|----------|
| POST | `/api/v1/decks` | Create a new deck |
| GET | `/api/v1/decks/{deck_id}` | Retrieve deck state |
| PATCH | `/api/v1/decks/{deck_id}/draw` | Draw cards from deck |
| GET | `/api/v1/livez` | Health check |

#### Create Deck

**Request Body:**
```json
{
  "is_shuffled": true,
  "wanted_cards": ["KS", "AC"]
}
```

Request fields (all optional):
- `is_shuffled` (boolean): Whether to shuffle after creation
- `wanted_cards` (array[string]): Specific cards to include; if omitted, full 52-card deck

**Behavior:**
- Creates a new deck with unique ID
- If `wanted_cards` provided, includes only those cards
- If `wanted_cards` omitted/empty, creates full 52-card deck
- If `is_shuffled` is true, randomizes card order
- Invalid input is ignored (no validation errors)

**Success Response (201 Created):**
```json
{
  "type": "deck",
  "data": {
    "deck_id": "1234",
    "is_shuffled": true,
    "remaining_cards": 52
  }
}
```

#### Get Deck

**Behavior:**
- Returns full deck state including all remaining cards
- Cards ordered from top of deck to bottom

**Success Response (200 OK):**
```json
{
  "type": "deck",
  "data": {
    "deck_id": "a251071b-662f-44b6-ba11-e24863039c59",
    "shuffled": false,
    "remaining": 3,
    "cards": [
      {"value": "ACE", "suit": "SPADES", "code": "AS"},
      {"value": "KING", "suit": "HEARTS", "code": "KH"},
      {"value": "8", "suit": "CLUBS", "code": "8C"}
    ]
  }
}
```

**Error Response (404 Not Found):**
```json
{
  "type": "error",
  "data": null,
  "error": "DeckNotFound",
  "message": "The specified deck does not exist"
}
```

#### Draw Cards

**Request Body:**
```json
{
  "count": 1
}
```

Request fields:
- `count` (integer, default: 1): Number of cards to draw

**Behavior:**
- Removes specified number of cards from top of deck
- Returns drawn cards in order drawn
- Updates deck state atomically
- Returns empty array if deck is exhausted

**Success Response (200 OK):**
```json
{
  "type": "card",
  "data": [
    {"value": "QUEEN", "suit": "HEARTS", "code": "QH"},
    {"value": "4", "suit": "DIAMONDS", "code": "4D"}
  ]
}
```

**Error Response (404 Not Found):** Deck not found
**Error Response (400 Bad Request - Insufficient Cards):**
```json
{
  "type": "error",
  "data": null,
  "error": "InsufficientCards",
  "message": "Not enough cards remaining in deck"
}
```

#### Health Check

**Success Response:**
```json
{
  "type": "health_check",
  "data": {
    "status": "OK"
  },
  "error": "",
  "meta": {}
}
```

### WebSocket Behaviors

**Endpoint:** `ws://{host}/ws/v1/dealer`

#### Connection Lifecycle

1. Client establishes WebSocket connection
2. Client subscribes to a room
3. Server pushes events to subscribed clients
4. Client can disconnect at any time

#### Client → Server Messages

**Subscribe to Room:**
```json
{
  "action": "subscribe",
  "room_id": "room-123"
}
```

**Request Draw:**
```json
{
  "action": "draw",
  "room_id": "room-123",
  "count": 2
}
```

**Assign Deck:**
```json
{
  "action": "assign_deck",
  "room_id": "room-123",
  "deck_id": "deck-456"
}
```

#### Server → Client Messages

**Subscription Confirmed:**
```json
{
  "type": "subscribed",
  "room_id": "room-123"
}
```

**Cards Dealt:**
```json
{
  "type": "cards_dealt",
  "room_id": "room-123",
  "data": [
    {"value": "QUEEN", "suit": "HEARTS", "code": "QH"}
  ]
}
```

**Deck Assigned:**
```json
{
  "type": "deck_assigned",
  "room_id": "room-123",
  "deck_id": "deck-456"
}
```

**Error:**
```json
{
  "type": "error",
  "error": "DeckNotFound",
  "message": "No deck assigned to room"
}
```

## Room Assignment Behaviors

### Assignment Rules

- Each room can have at most one active deck at a time
- A deck can be assigned to at most one room
- When a deck is exhausted, room must request new deck assignment
- Assignment is stored as part of deck state

### Assignment Flow

```
Room Request → Find/Create Deck → Assign Room ID → Persist State
```

## Task Consumption Behaviors (Optional)

The dealer may optionally consume tasks from a message queue.

### Supported Task Types

| Task | Description |
|------|-------------|
| `create-deck` | Create new deck for a room |
| `assign-deck` | Assign existing deck to a room |
| `deal-cards` | Deal cards to a room/player |

### Task Format

```json
{
  "task_id": "create-deck",
  "room_id": "room-123",
  "payload": {
    "is_shuffled": true,
    "wanted_cards": ["AS", "KH"]
  }
}
```

### Task Processing Flow

```
Queue → Consume Task → Process → Update State → Notify (via WebSocket)
```

## Persistence Behaviors

### Storage Requirements

- Deck state must be persisted across restarts
- Card order must be maintained
- Drawn cards must be tracked
- Room assignments must be durable
- Operations must be atomic where specified

### Storage Options

Implementations may use any storage backend that satisfies:
- Atomic read-modify-write for draw operations
- Consistent ordering of card arrays
- Durability of deck state

Examples: Relational database, key-value store, file system

## Deployment Requirements

### Container Requirements

- HTTP API exposed on configurable port (default: 3000)
- WebSocket endpoint exposed on configurable port (default: 8080)
- Persistent storage for deck state
- Health check endpoint at `/api/v1/livez`

### Environment Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `HTTP_PORT` | HTTP API port | 3000 |
| `WS_PORT` | WebSocket port | 8080 |
| `DB_PATH` | Storage path | /data/decks |

## Test Suite Checklist

### Deck API Tests
- [ ] Create deck - success with default full deck
- [ ] Create deck - success with shuffled flag
- [ ] Create deck - success with wanted_cards
- [ ] Create deck - ignores bad input (no validation errors)
- [ ] Get deck - returns deck with cards
- [ ] Get deck - handles non-existent deck (404)
- [ ] Draw card - success draws from top of deck
- [ ] Draw card - success with count > 1
- [ ] Draw card - handles non-existent deck (404)
- [ ] Draw card - handles insufficient cards

### Room Assignment Tests
- [ ] Assign deck to room
- [ ] Prevent assigning deck to multiple rooms
- [ ] Get deck by room ID
- [ ] Handle room without deck assignment

### WebSocket Tests
- [ ] Client can connect
- [ ] Subscribe to room
- [ ] Draw cards via WebSocket
- [ ] Receive card dealt notifications
- [ ] Handle room not found
- [ ] Handle deck exhausted

### Task Consumption Tests (if implemented)
- [ ] Consume create-deck task
- [ ] Consume assign-deck task
- [ ] Consume deal-cards task
- [ ] Handle task processing errors

### E2E Tests
- [ ] Full flow: Create deck → Assign to room → Draw cards
- [ ] Full flow: Task queued → Worker processes → Cards dealt

### Deployment Tests
- [ ] Container builds successfully
- [ ] HTTP API accessible
- [ ] WebSocket endpoint accessible
- [ ] Storage is writable
- [ ] Health check responds correctly

## Design Principles

1. **Idempotency**: Creating a deck with same parameters creates multiple decks
2. **Statelessness**: Each request contains all needed information
3. **No Validation**: Invalid input is ignored silently
4. **Atomic Operations**: Card draws must be atomic to prevent race conditions
5. **Card Order Matters**: Decks have order; draws always take from top

## Example Usage

### Create a New Deck

```bash
# Full shuffled deck
curl -X POST http://localhost:3000/api/v1/decks \
  -H "Content-Type: application/json" \
  -d '{"is_shuffled": true}'

# Custom deck with specific cards
curl -X POST http://localhost:3000/api/v1/decks \
  -H "Content-Type: application/json" \
  -d '{
    "is_shuffled": false,
    "wanted_cards": ["AS", "KS", "QS", "JS", "0S"]
  }'
```

### Get Deck Information

```bash
curl -X GET http://localhost:3000/api/v1/decks/a251071b-662f-44b6-ba11-e24863039c59
```

### Draw Cards

```bash
# Draw single card
curl -X PATCH http://localhost:3000/api/v1/decks/a251071b-662f-44b6-ba11-e24863039c59/draw \
  -H "Content-Type: application/json" \
  -d '{"count": 1}'

# Draw multiple cards
curl -X PATCH http://localhost:3000/api/v1/decks/a251071b-662f-44b6-ba11-e24863039c59/draw \
  -H "Content-Type: application/json" \
  -d '{"count": 5}'
```

### WebSocket Connection

```javascript
const ws = new WebSocket('ws://localhost:8080/ws/v1/dealer');

ws.onopen = () => {
  ws.send(JSON.stringify({
    action: 'subscribe',
    room_id: 'room-123'
  }));
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Received:', message);
};
```
