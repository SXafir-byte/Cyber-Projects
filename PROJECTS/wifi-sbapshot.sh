#!/bin/zsh
set -u

REPORT="$HOME/Desktop/public-wifi-snapshot-$(date +%Y%m%d-%H%M%S).txt"

wifi_if=$(
  networksetup -listallhardwareports |
  awk '/Hardware Port: (Wi-Fi|AirPort)/ {found=1} found && /Device:/ {print $2; exit}'
)

{
  echo "PUBLIC WI-FI SAFETY SNAPSHOT"
  echo "Created: $(date)"
  echo

  echo "== Wi-Fi =="
  if [[ -n "${wifi_if:-}" ]]; then
    echo "Interface: $wifi_if"
    networksetup -getairportnetwork "$wifi_if" 2>/dev/null
    echo "Local IP: $(ipconfig getifaddr "$wifi_if" 2>/dev/null || echo 'Not connected')"
  else
    echo "Wi-Fi interface not found."
  fi
  echo

  echo "== VPN =="
  vpn=$(scutil --nc list | awk -F'"' '/Connected/ {print $2}')
  [[ -n "$vpn" ]] && echo "Connected: $vpn" || echo "No built-in VPN connection detected."
  echo

  echo "== DNS servers =="
  scutil --dns | awk '/nameserver\[[0-9]+\]/ {print $3}' | sort -u
  echo

  echo "== macOS Firewall =="
  /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
  echo

  echo "== Web proxy for Wi-Fi =="
  networksetup -getwebproxy "Wi-Fi" 2>/dev/null || echo "Could not read Wi-Fi proxy settings."
  echo

  echo "== Your established TCP connections =="
  lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null || true
  echo

  
} > "$REPORT"

echo "Saved report to: $REPORT"
