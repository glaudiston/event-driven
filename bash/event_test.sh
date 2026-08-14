#!/usr/bin/env bash

# =======================================================================================
# TEST CONFIGURATION & SETUP
# =======================================================================================
source ./event.sh

# Colors for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' 

# Test State
TOTAL_TESTS=0
PASSED_TESTS=0

# Use Shared Memory for speed and to avoid polluting disk
[ -d /dev/shm ] && SHM_DIR=/dev/shm || SHM_DIR=/tmp
DATA_PATH=$SHM_DIR/event-tests
mkdir -p $DATA_PATH
LOG_FILE="${DATA_PATH}/session_data.jsonl"
OUT_FILE="${DATA_PATH}/test_output.txt"

# Cleanup on exit
trap 'rm -rf "$DATA_PATH"/* "$OUT_FILE"' EXIT

# ===========================================================================================
# ASSERTION ENGINE
# ===========================================================================================

# Checks if a string contains a specific substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local name="$3"
    ((TOTAL_TESTS++)) || :

    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "  ${GREEN}✅ PASS:${NC} $name"
        ((PASSED_TESTS++)) || :
    else
        echo -e "  ${RED}❌ FAIL:${NC} $name"
        echo -e "     Expected to find: '$needle' in '$haystack'"
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local name="$3"
    ((TOTAL_TESTS++)) || :

    if [[ "$expected" == "$actual" ]]; then
        echo -e "  ${GREEN}✅ PASS:${NC} $name"
        ((PASSED_TESTS++)) || :
    else
        echo -e "  ${RED}❌ FAIL:${NC} $name"
        echo -e "     Expected: '$expected' | Actual: '$actual'"
    fi
}

assert_exists() {
    local file="$1"
    local name="$2"
    ((TOTAL_TESTS++)) || :
    if [[ -f "$file" ]]; then
        echo -e "  ${GREEN}✅ PASS:${NC} $name"
        ((PASSED_TESTS++)) || :
    else
        echo -e "  ${RED}❌ FAIL:${NC} $name (File $file not found)"
    fi
}

# ===========================================================================================
# MOCK HANDLERS
# ===========================================================================================

# Handlers receive: topic, hash, ts, payload
mock_console_handler() {
    echo "HANDLED|$1|$2|$3|$4" >> "$OUT_FILE"
}

mock_file_handler() {
    echo "FILE_LOGGED|$1|$4" >> "$OUT_FILE"
}

# ===========================================================================================
# TEST CASES
# ===========================================================================================

test_single_subscriber() {
    echo -e "\n${YELLOW}Running: Single Subscriber Test...${NC}"
    > "$OUT_FILE"
 
    subscribe "USER_LOGIN" "mock_console_handler"
    
    # Generic event: Topic "USER_LOGIN", Payload "user_id=123 ip=1.1.1.1"
    publish "USER_LOGIN" "user_id=123 ip=1.1.1.1"
    
    local result=$(tail -n 1 "$OUT_FILE")
    
    # We check if the result contains the topic and the payload. 
    # We ignore Hash and TS because they are dynamic.
    assert_contains "$result" "USER_LOGIN" "Should trigger handler with correct topic"
    assert_contains "$result" "user_id=123 ip=1.1.1.1" "Should trigger handler with correct payload"
}

test_fan_out_subscribers() {
    echo -e "\n${YELLOW}Running: Fan-out (Multiple Subscribers) Test...${NC}"
    > "$OUT_FILE"
    
    subscribe "SYSTEM_ALERT" "mock_console_handler"
    subscribe "SYSTEM_ALERT" "mock_file_handler"
    
    publish "SYSTEM_ALERT" "CPU_USAGE_HIGH 95%"
    
    local count=$(wc -l < "$OUT_FILE")
    assert_equals "2" "$count" "Should trigger exactly two handlers"
    
    assert_contains "$(cat "$OUT_FILE")" "HANDLED" "Console handler should have executed"
    assert_contains "$(cat "$OUT_FILE")" "FILE_LOGGED" "File handler should have executed"
}

test_topic_isolation() {
    echo -e "\n${YELLOW}Running: Topic Isolation Test...${NC}"
    > "$OUT_FILE"
    
    subscribe "APP_UPDATE" "mock_console_handler"
    
    # Publish to a different topic
    publish "DATABASE_BACKUP" "status=complete"
    
    local count=$(wc -l < "$OUT_FILE")
    assert_equals "0" "$count" "Handlers for APP_UPDATE should not trigger for DATABASE_BACKUP events"
}

test_persistence() {
    echo -e "\n${YELLOW}Running: Persistence Test...${NC}"
    
    local test_topic="PERSISTENCE_TEST"
    local expected_log="${DATA_PATH}/${test_topic}.session_data.jsonl"
    
    publish "$test_topic" "some persistence data"
    
    assert_exists "$expected_log" "Log file should be created for the specific topic"
    
    local line_count=$(wc -l < "$expected_log" 2>/dev/null || echo 0)
    if [ "$line_count" -gt 0 ]; then
        echo -e "  ${GREEN}✅ PASS:${NC} Events are being persisted (Lines: $line_count)"
        ((PASSED_TESTS++)) || :
        ((TOTAL_TESTS++)) || :
    else
        echo -e "  ${RED}❌ FAIL:${NC} Log file is empty"
        ((TOTAL_TESTS++)) || :
    fi
}

# ===========================================================================================
# MAIN RUNNER
# ===========================================================================================

main() {
    # Clean environment
    rm -rf "$DATA_PATH"/*
    touch "$OUT_FILE"

    echo "=================================================================="
    echo "🚀 STARTING GENERIC EVENT MANAGER TEST SUITE"
    echo "=================================================================="

    test_single_subscriber
    test_fan_out_subscribers
    test_topic_isolation
    test_persistence

    echo -e "\n=================================================================="
    echo -e "TEST SUMMARY: ${GREEN}$PASSED_TESTS${NC} / ${YELLOW}$TOTAL_TESTS${NC} Passed"
    echo "=================================================================="

    [[ $PASSED_TESTS -eq $TOTAL_TESTS ]] || exit 1
}

main
