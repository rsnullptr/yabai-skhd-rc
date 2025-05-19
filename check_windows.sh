#!/bin/bash

# Get all windows that should be managed but aren't
UNMANAGED_COUNT=$(yabai -m query --windows | jq '[.[] | select(.app != "Pritunl" and .app != "System Preferences" and .app != "System Settings" and .app != "zoom.us" and .app != "Photo Booth" and .app != "Archive Utility" and .title != "Copy" and .title != "Connect" and .title != "Move" and .title != "Info" and .title != "Pref" and .["is-floating"] == true and .["has-focus"] == true)] | length')

# If we found unmanaged windows that should be managed, restart yabai
if [ "$UNMANAGED_COUNT" -gt 0 ]; then
  # Log the restart for debugging
  echo "$(date): Restarting yabai due to $UNMANAGED_COUNT unmanaged windows" >> ~/.yabai_restarts.log

  # Restart the service
  yabai --restart-service
fi
