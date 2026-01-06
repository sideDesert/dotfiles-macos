#!/bin/bash

# Get WiFi SSID - try multiple interfaces and methods
SSID=""
WIFI_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi\|AirPort" | grep "Device:" | awk '{print $2}')

# Check WiFi connection status via system_profiler (more reliable)
WIFI_STATUS=$(system_profiler SPAirPortDataType 2>/dev/null | grep "Status:" | awk -F': ' '{print $2}' | tr -d ' ')

if [ "$WIFI_STATUS" = "Connected" ]; then
  # WiFi is connected - try to get SSID
  # Method 1: Try networksetup
  SSID=$(/usr/sbin/networksetup -getairportnetwork "$WIFI_INTERFACE" 2>/dev/null | sed 's/Current Wi-Fi Network: //')
  
  # Check if we got an error message
  if [[ "$SSID" == *"not associated"* ]] || [[ "$SSID" == *"AirPort"* ]] || [ -z "$SSID" ]; then
    # Method 2: Check ifconfig status
    WIFI_ACTIVE=$(ifconfig "$WIFI_INTERFACE" 2>/dev/null | grep "status: active")
    if [ -n "$WIFI_ACTIVE" ]; then
      # WiFi is active - show "Connected" if SSID can't be retrieved
      SSID="Connected"
    else
      SSID=""
    fi
  fi
else
  SSID=""
fi

# Update sketchybar
if [ -z "$SSID" ] || [ "$SSID" = "" ]; then
  sketchybar --set $NAME label="Off"
else
  sketchybar --set $NAME label="$SSID"
fi

