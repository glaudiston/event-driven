#!/usr/bin/env bash

# =================================================================================
# TEST CONFIGURATION & SETUP
# =================================================================================
source ./event.sh

# Colors for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test State
TOTAL_TESTS=0
PASSED_TESTS=0

# Ensure event.sh uses the same tmp path for the log
DATA_PATH=/dev/shm

# Temporary files moved to /dev/shm (Shared Memory)
LOG_FILE="/dev/shm/session_data.jsonl"
OUT_FILE="/dev/shm/test_output.txt"

# Setup trap to clean up temporary files on exit (INT, TERM, EXIT)
trap 'rm -f "$LOG_FILE" "$OUT_FILE"' EXIT

# =================================================================================
# ASSERTION ENGINE
# =================================================================================
assert_equals() {
    local expected="$1"
    local actual="$2"
    local name="$3"
    ((TOTAL_TESTS++))

    if [[ "$expected" == "$actual" ]]; then
        echo -e "  ${GREEN}✅ PASS:${NC} $name"
        ((PASSED_TESTS++))
    else
        echo -e "  ${RED}❌ FAIL:${NC} $name"
        echo -e "     Expected: '$expected' | Actual: '$actual'"
    fi
}

assert_exists() {
    local file="$1"
    local name="$2"
    ((TOTAL_TESTS++))
    if [[ -f "$file" ]]; then
        echo -e "  ${GREEN}✅ PASS:${NC} $name"
        ((PASSED_TESTS++))
    else
        echo -e "  ${RED}❌ FAIL:${NC} $name (File $file not found)"
    fi
}

# =================================================================================
# MOCK HANDLERS
# =================================================================================
mock_console_handler() {
    # Now receives: topic, task, status, msg
    echo "HANDLED|$1|$2|$3|$4" >> "$OUT_FILE"
}

mock_file_handler() {
    # Now receives: topic, task, status, msg
    echo "FILE_LOGGED|$2|$3" >> "$OUT_FILE"
}

# =================================================================================
# TEST CASES
# =================================================================================

test_single_subscriber() {
    echo -e "\n${YELLOW}Running: Single Subscriber Test...${NC}"
    > "$OUT_FILE"
    subscribe "USER_SIGNUP" "mock_console_handler"
    
    publish "USER_SIGNUP" "send_welcome_email" "SUCCESS" "User joined"
    
    local result=$(tail -n 1 "$OUT_FILE")
    assert_equals "HANDLED|USER_SIGNUP|send_welcome_email|SUCCESS|User joined" "$result" "Should trigger single handler with correct 
args"
}

test_fan_out_subscribers() {
    echo -e "\n${YELLOW}Running: Fan-out (Multiple Subscribers) Test...${NC}"
    > "$OUT_FILE"
    subscribe "SYSTEM_CRITICAL" "mock_console_handler"
    subscribe "SYSTEM_CRITICAL" "mock_file_handler"
    
    publish "SYSTEM_CRITICAL" "server_down" "ERROR" "CPU Overheat"
    
    local count=$(wc -l < "$OUT_FILE")
    assert_equals "2" "$count" "Should trigger exactly two handlers"
    
    local contains_console=$(grep -c "HANDLED" "$OUT_FILE")
    local contains_file=$(grep -c "FILE_LOGGED" "$OUT_FILE")
    assert_equals "1" "$contains_console" "Console handler should have executed"
    assert_equals "1" "$contains_file" "File handler should have executed"
}

test_topic_isolation() {
    echo -e "\n${YELLOW}Running: Topic Isolation Test...${NC}"
    > "$OUT_FILE"
    subscribe "MARKETING" "mock_console_handler"
    
    publish "BILLING" "invoice_sent" "SUCCESS" "Inv #123"
    
    local count=$(wc -l < "$OUT_FILE")
    assert_equals "0" "$count" "Handlers for MARKETING should not trigger for BILLING events"
}

test_persistence() {
    echo -e "\n${YELLOW}Running: Persistence Test...${NC}"

    local test_topic="PERSISTENCE_TEST"
    # Dynamically determine the filename based on the implementation in event.sh
    local expected_log="/dev/shm/${test_topic}.session_data.jsonl"

    publish "$test_topic" "write" "OK" "Testing log"

    assert_exists "$expected_log" "Log file should be created for the specific topic"

    local line_count=$(wc -l < "$expected_log" 2>/dev/null || echo 0)
    if [ "$line_count" -gt 0 ]; then
        echo -e "  ${GREEN}✅ PASS:${NC} Events are being persisted (Lines: $line_count)"
        ((PASSED_TESTS++))
        ((TOTAL_TESTS++))
    else
        echo -e "  ${RED}❌ FAIL:${NC} Log file is empty"
        ((TOTAL_TESTS++))
    fi
}

# =================================================================================
# MAIN RUNNER
# =================================================================================
main() {
    # Clean environment
    rm -f "$LOG_FILE" "$OUT_FILE"
    touch "$OUT_FILE"

    echo "======================================================="
    echo "🚀 STARTING EVENT MANAGER TEST SUITE"
    echo "======================================================="

    test_single_subscriber
    test_fan_out_subscribers
    test_topic_isolation
    test_persistence

    echo -e "\n======================================================="
    echo -e "TEST SUMMARY: ${GREEN}$PASSED_TESTS${NC} / ${YELLOW}$TOTAL_TESTS${NC} Passed"
    echo "======================================================="

    [[ $PASSED_TESTS -eq $TOTAL_TESTS ]] || exit 1
}

main
