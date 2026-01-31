# WiFi Auto-Reconnect Monitor for macOS

A simple tool that watches your WiFi connection and automatically restarts it when problems occur.

## Why this exists

I encountered a problem using **ASUS BE58U** router with **MacBook M3 Pro**. WiFi drops under heavy network load (large downloads, video calls, etc.). The connection just dies and you have to manually toggle WiFi off and on.

The root cause is most likely a bug in **macOS Tahoe + M3 WiFi driver**. Until Apple fixes it, this script is a workaround that automatically restarts WiFi when it detects connection loss.

If you have a similar setup and experience random WiFi drops, this tool might help you too.

## What does this do?

Sometimes WiFi stops working even though your router is fine. You have to manually turn WiFi off and on again. This tool does that automatically for you.

**How it works:**
1. Every 2 seconds, it checks three levels of connectivity
2. If your router is unreachable 3 times in a row, it restarts WiFi
3. Your Mac reconnects to the network automatically

**Multi-level diagnostics:**

| Level | Target | What it checks |
|-------|--------|----------------|
| 1 | Router gateway | WiFi connection (auto-detected) |
| 2 | ISP gateway | Router/WAN connection (auto-detected via traceroute) |
| 3 | Google DNS (8.8.8.8) | Internet connection |

This helps distinguish between WiFi problems (restart helps) and internet problems (restart won't help).

**Smart features:**
- Works with any WiFi network (home, hotspot, office, cafe)
- Automatically detects gateway and ISP when you switch networks
- If there's no internet for a long time (like power outage), it waits 5 minutes between attempts instead of constantly restarting
- Starts automatically when you turn on your Mac

## Installation

### Step 1: Open Terminal

Press `Cmd + Space`, type `Terminal`, press Enter.

You will see a window with text. This is where you type commands.

### Step 2: Go to the folder with files

Type this command and press Enter:

```bash
cd ~/path-to-directory/wifi-monitor
```

### Step 3: Run the installer

Type these two commands (press Enter after each one):

```bash
chmod +x install.sh
```

```bash
./install.sh
```

You should see:
```
✅ Installation complete!
```

**Done!** The tool is now running and will start automatically every time you log in.

## How to check if it's working

### See current status

Open Terminal and type:

```bash
ps aux | grep wifi-monitor
```

If you see a line with `/Users/yourname/wifi-monitor.sh`, it's running.

### Watch the log in real time

Open Terminal and type:

```bash
tail -f ~/.wifi-monitor.log
```

You will see messages like:
```
2025-01-30 12:30:45 - 🚀 WiFi Monitor Started
2025-01-30 12:30:45 - 🔄 Gateway changed:  → 192.168.50.1
2025-01-30 12:30:45 - 🏢 ISP gateway detected: 172.27.4.254
```

To stop watching, press `Ctrl + C`.

## How to stop the tool

If you need to stop the monitoring (for example, for troubleshooting):

Open Terminal and type:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.wifi-monitor.plist
```

## How to start again

Open Terminal and type:

```bash
launchctl load ~/Library/LaunchAgents/com.user.wifi-monitor.plist
```

## How to restart (after changing settings)

Open Terminal and type both commands:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.wifi-monitor.plist
```

```bash
launchctl load ~/Library/LaunchAgents/com.user.wifi-monitor.plist
```

## Settings

You can change the settings by editing the file `~/wifi-monitor.sh`.

To open it, type in Terminal:

```bash
open -e ~/wifi-monitor.sh
```

Look for these lines at the top:

| Setting | What it means | Default |
|---------|---------------|---------|
| `TIMEOUT_THRESHOLD=3` | How many failed checks before restart | 3 |
| `BASE_PING_INTERVAL=2` | How often to check (seconds) | 2 |
| `COOLDOWN_AFTER_RESTART=10` | Wait time after restart (seconds) | 10 |
| `MAX_CONSECUTIVE_RESTARTS=3` | Restarts before long pause | 3 |
| `LONG_WAIT_MINUTES=5` | Long pause duration (minutes) | 5 |
| `EXTERNAL_DNS` | DNS server to check internet | 8.8.8.8 |

After changing, save the file and restart the tool (see above).

## Complete removal

If you want to remove the tool completely:

Open Terminal and type these commands one by one:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.wifi-monitor.plist
```

```bash
rm ~/Library/LaunchAgents/com.user.wifi-monitor.plist
```

```bash
rm ~/wifi-monitor.sh
```

```bash
rm ~/.wifi-monitor.log
```

## Troubleshooting

### "Permission denied" error

Run this command and try again:

```bash
chmod +x ~/wifi-monitor.sh
```

### Tool is not starting

Check if the file exists:

```bash
ls -la ~/wifi-monitor.sh
```

If you see "No such file", run the installer again.

### WiFi keeps restarting even when internet works

This can happen if your router blocks ping. Contact your internet provider or try a different router.

## Log file

All activity is saved to `~/.wifi-monitor.log`

The file automatically rotates when it reaches 1MB (old logs are saved as `.wifi-monitor.log.old`).

**Example log (startup):**
```
🚀 WiFi Monitor Started
Mode: Multi-level diagnostics
Targets: Gateway (auto) → ISP (auto) → DNS (8.8.8.8)
🔄 Gateway changed:  → 192.168.50.1
🏢 ISP gateway detected: 172.27.4.254
```

**Example log (WiFi problem fixed):**
```
❌ Gateway timeout #1 (network: MyWiFi, gateway: 192.168.50.1)
❌ Gateway timeout #2 (network: MyWiFi, gateway: 192.168.50.1)
❌ Gateway timeout #3 (network: MyWiFi, gateway: 192.168.50.1)
⚠️  Restarting WiFi...
✅ WiFi restarted (total: 1, consecutive: 1)
Backoff: ping interval increased to 4s
✅ All connections restored (gateway: 192.168.50.1)
```

**Example log (ISP/WAN problem - no restart needed):**
```
🏢 ISP unreachable (172.27.4.254) - WAN/Router issue, not WiFi
```

**Example log (Internet problem - no restart needed):**
```
🌐 DNS unreachable (8.8.8.8) - Internet issue, not WiFi
```

**Example log (switching to hotspot):**
```
🔄 Gateway changed: 192.168.50.1 → 172.20.10.1
🏢 ISP gateway detected: 10.49.0.1
```

**Example log (power outage - too many restarts):**
```
⚠️  Restarting WiFi...
✅ WiFi restarted (total: 3, consecutive: 3)
⏸️  Too many consecutive restarts (3). Waiting 5 minutes...
▶️  Resuming monitoring after long wait
```

## Questions?

If something doesn't work, check the log file first — it usually shows what went wrong.
