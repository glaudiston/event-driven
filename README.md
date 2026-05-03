# Bash Event Manager

A lightweight, file-based Publish/Subscribe (Pub/Sub) event manager implemented entirely in Bash. This library allows you to decouple 
components of your shell scripts by implementing an event-driven architecture.

## 🚀 Features

- **Topic-Based Routing**: Subscribe multiple handlers to specific topics.
- **Fan-out Pattern**: A single event can trigger multiple subscriber functions simultaneously.
- **Event Persistence**: Every event is persisted to a `.jsonl` (JSON Lines) file for audit trails and debugging.
- **Concurrency Safe**: Uses `flock` to prevent race conditions during event logging.
- **Asynchronous Execution**: Handlers are triggered in the background, ensuring the main process is not blocked by slow subscribers.
- **Integrity Tracking**: Generates a unique MD5 hash for every event based on the previous event's hash, timestamp, and payload.

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

```bash
# Define a handler
my_handler() {
    local topic=$1
    local task=$2
    local status=$3
    local msg=$4
    echo "Received event: $task on topic $topic with status $status. Message: $msg"
}

# Subscribe the handler to a topic
subscribe "USER_SIGNUP" "my_handler"
```

### 3. Publishing Events
Trigger all subscribers of a topic using `publish`.

```bash
# publish <topic> <task> [status] [message]
publish "USER_SIGNUP" "send_welcome_email" "SUCCESS" "User joined from IP 1.2.3.4"
```

## 🧪 Testing

A comprehensive test suite is provided in `event_test.sh`. It covers:
- Single subscriber execution.
- Fan-out (multiple subscribers) capability.
- Topic isolation (ensuring events don't leak between topics).
- Persistence (verifying JSONL logs are created).

To run the tests:
```bash
chmod +x event_test.sh
./event_test.sh
```

## 📂 Data Storage

Events are stored in:
`${XDG_DATA_HOME:-$HOME/.local/share}/[app_name]/events/[topic].session_data.jsonl`

Each entry contains:
- `hash`: A unique chain-link hash for the event.
- `ts`: Nanosecond timestamp.
- `topic`: The event category.
- `task`: The specific action.
- `status`: Status of the task.
- `msg`: Additional metadata.
