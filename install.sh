#!/bin/bash

# WiFi Monitor Installer

echo "🔧 WiFi Monitor Installer"
echo "========================="
echo ""

# Copy the script
echo "1. Installing wifi-monitor.sh..."
cp wifi-monitor.sh ~/wifi-monitor.sh
chmod +x ~/wifi-monitor.sh

# Copy LaunchAgent
echo "2. Installing LaunchAgent..."
mkdir -p ~/Library/LaunchAgents
cp com.user.wifi-monitor.plist ~/Library/LaunchAgents/

# Load the agent
echo "3. Loading LaunchAgent..."
launchctl unload ~/Library/LaunchAgents/com.user.wifi-monitor.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.user.wifi-monitor.plist

echo ""
echo "✅ Installation complete!"
echo ""
echo "Commands:"
echo "  Start:   launchctl load ~/Library/LaunchAgents/com.user.wifi-monitor.plist"
echo "  Stop:    launchctl unload ~/Library/LaunchAgents/com.user.wifi-monitor.plist"
echo "  Status:  ps aux | grep wifi-monitor"
echo "  Logs:    tail -f ~/.wifi-monitor.log"
echo ""
echo "Config: Edit ~/wifi-monitor.sh to change settings"