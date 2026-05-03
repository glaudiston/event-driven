# Bash Event Manager

A lightweight, file-based Publish/Subscribe (Pub/Sub) event manager implemented entirely in Bash. This library allows you to decouple 
components of your shell scripts by implementing a generic event-driven architecture.

## 🚀 Features

- **Topic-Based Routing**: Subscribe multiple handlers to specific topics.
- **Fan-out Pattern**: A single event can trigger multiple subscriber functions simultaneously.
- **Event Persistence**: Every event is persisted to a `.jsonl` (JSON Lines) file for audit trails and debugging.
- **Concurrency Safe**: Uses `flock` to prevent race conditions during event logging.
- **Asynchronous Execution**: Handlers are triggered in the background, ensuring the main process is not blocked by slow subscribers.
- **Integrity Tracking**: Generates a unique MD5 hash for every event based on the previous event's hash, timestamp, and payload, 
creating a verifiable chain.

## 🛠 Prerequisites

To run this manager, ensure you have the following installed:
- `bash` (4.0+)
- `jq` (for JSON processing)
- `md5sum` (standard on most Linux distributions)
- `flock` (util-linux)

**Dependencies:**
This project relies on custom utility libraries for array management:
- `github.com/glaudiston/pragma_once`

## 📖 Usage

### 1. Integration
Source the `event.sh` file in your script:

```bash
source ./event.sh
```

### 2. Subscribing to Events
Define a handler function and register it to a topic using `subscribe`. 

**Handler Signature:** Handlers must accept four arguments: `topic`, `hash`, `timestamp`, and `payload`.
Each entry contains:
- `hash`: A unique chain-link hash for the event.
- `ts`: Nanosecond timestamp.
- `topic`: The event category.
- `payload`: The data related to the published event.

## 📂 Data Storage

Events are stored in:
`${XDG_DATA_HOME:-$HOME/.local/share}/[app_name]/events/[topic].session_data.jsonl`

```bash
# Define a handler
my_handler() {
    local topic=$1
    local hash=$2
    local ts=$3
    local payload=$4
    echo "Topic: $topic | Payload: $payload (Hash: $hash)"
}

# Subscribe the handler to a topic
subscribe "USER_LOGIN" "my_handler"
```

### 3. Publishing Events
Trigger all subscribers of a topic using `publish`. Any arguments provided after the topic are treated as the event payload.

```bash
# publish <topic> <payload>
publish "USER_LOGIN" "user_id=123 ip=1.1.1.1"
```

## 🧪 Testing

A comprehensive test suite is provided in `event_test.sh`. It covers:
- **Single subscriber execution**: Verifying the payload reaches the handler.
- **Fan-out**: Ensuring multiple subscribers are triggered by one event.
- **Topic isolation**: Ensuring events published to Topic A do not trigger handlers for Topic B.
- **Persistence**: Verifying that every event is logged to disk in JSONL format.

To run the tests:
```bash
chmod +x event_test.sh
./event_test.sh
```
