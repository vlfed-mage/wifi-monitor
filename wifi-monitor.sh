#!/bin/bash

# ===========================================
# WiFi Auto-Reconnect Monitor for macOS
# Automatically restarts WiFi on connection loss
# ===========================================

# Settings
TIMEOUT_THRESHOLD=3
BASE_PING_INTERVAL=2
COOLDOWN_AFTER_RESTART=10
LOG_FILE="$HOME/.wifi-monitor.log"
MAX_LOG_SIZE=1048576
MAX_CONSECUTIVE_RESTARTS=3
LONG_WAIT_MINUTES=5

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

timeout_count=0
total_restart_count=0
consecutive_restart_count=0
current_ping_interval=$BASE_PING_INTERVAL

log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "$message" | tee -a "$LOG_FILE"

    if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        log "Log rotated"
    fi
}

get_gateway_ip() {
    route -n get default 2>/dev/null | grep 'gateway' | awk '{print $2}'
}

restart_wifi() {
    log "${YELLOW}⚠️  Restarting WiFi...${NC}"

    networksetup -setairportpower en0 off
    sleep 2

    networksetup -setairportpower en0 on
    sleep $COOLDOWN_AFTER_RESTART

    ((total_restart_count++))
    ((consecutive_restart_count++))
    log "${GREEN}✅ WiFi restarted (total: $total_restart_count, consecutive: $consecutive_restart_count)${NC}"
}

is_wifi_on() {
    local status=$(networksetup -getairportpower en0 | grep -c "On")
    [ "$status" -eq 1 ]
}

get_current_network() {
    networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //'
}

check_already_running() {
    local pid_file="/tmp/wifi-monitor.pid"

    if [ -f "$pid_file" ]; then
        local old_pid=$(cat "$pid_file")
        if ps -p "$old_pid" > /dev/null 2>&1; then
            echo "WiFi monitor is already running (PID: $old_pid)"
            echo "To stop it: kill $old_pid"
            exit 1
        fi
    fi

    echo $$ > "$pid_file"
}

cleanup() {
    log "WiFi monitor stopped"
    rm -f /tmp/wifi-monitor.pid
    exit 0
}

reset_backoff() {
    consecutive_restart_count=0
    current_ping_interval=$BASE_PING_INTERVAL
}

apply_exponential_backoff() {
    current_ping_interval=$((current_ping_interval * 2))
    if [ $current_ping_interval -gt 60 ]; then
        current_ping_interval=60
    fi
    log "${YELLOW}Backoff: ping interval increased to ${current_ping_interval}s${NC}"
}

enter_long_wait() {
    local wait_seconds=$((LONG_WAIT_MINUTES * 60))
    log "${YELLOW}⏸️  Too many consecutive restarts ($consecutive_restart_count). Waiting ${LONG_WAIT_MINUTES} minutes...${NC}"
    sleep $wait_seconds
    reset_backoff
    log "${GREEN}▶️  Resuming monitoring after long wait${NC}"
}

trap cleanup SIGINT SIGTERM

main() {
    check_already_running

    log "=========================================="
    log "${GREEN}🚀 WiFi Monitor Started${NC}"
    log "Mode: Auto-detect gateway"
    log "Timeout threshold: $TIMEOUT_THRESHOLD"
    log "Base ping interval: ${BASE_PING_INTERVAL}s"
    log "Max consecutive restarts: $MAX_CONSECUTIVE_RESTARTS"
    log "Long wait period: ${LONG_WAIT_MINUTES} minutes"
    log "=========================================="

    while true; do
        if ! is_wifi_on; then
            log "${YELLOW}WiFi is off, waiting...${NC}"
            sleep 5
            continue
        fi

        local gateway_ip=$(get_gateway_ip)

        if [ -z "$gateway_ip" ]; then
            log "${YELLOW}No gateway found, waiting...${NC}"
            sleep 5
            continue
        fi

        if ping -c 1 -W 2 "$gateway_ip" &> /dev/null; then
            if [ $timeout_count -gt 0 ]; then
                log "${GREEN}✅ Connection restored after $timeout_count timeouts (gateway: $gateway_ip)${NC}"
            fi
            timeout_count=0
            reset_backoff
        else
            ((timeout_count++))
            local network=$(get_current_network)
            log "${RED}❌ Timeout #$timeout_count (network: $network, gateway: $gateway_ip)${NC}"

            if [ $timeout_count -ge $TIMEOUT_THRESHOLD ]; then
                if [ $consecutive_restart_count -ge $MAX_CONSECUTIVE_RESTARTS ]; then
                    enter_long_wait
                else
                    restart_wifi
                    apply_exponential_backoff
                fi
                timeout_count=0
            fi
        fi

        sleep $current_ping_interval
    done
}

main
