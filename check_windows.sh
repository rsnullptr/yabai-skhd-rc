#!/bin/bash

# Default unmanaged apps and titles if no arguments provided
DEFAULT_APPS=("Pritunl" "System Preferences" "System Settings" "zoom.us" "Photo Booth" "Archive Utility")
DEFAULT_TITLES=("Copy" "Connect" "Move" "Info" "Pref")

# Parse arguments
UNMANAGED_APPS=()
UNMANAGED_TITLES=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --apps)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        UNMANAGED_APPS+=("$1")
        shift
      done
      ;;
    --titles)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        UNMANAGED_TITLES+=("$1")
        shift
      done
      ;;
    *)
      echo "Usage: $0 [--apps app1 app2 ...] [--titles title1 title2 ...]"
      exit 1
      ;;
  esac
done

# Use defaults if no arguments provided
if [ ${#UNMANAGED_APPS[@]} -eq 0 ]; then
  UNMANAGED_APPS=("${DEFAULT_APPS[@]}")
fi

if [ ${#UNMANAGED_TITLES[@]} -eq 0 ]; then
  UNMANAGED_TITLES=("${DEFAULT_TITLES[@]}")
fi

# Build jq filter for apps
APP_FILTER=""
for app in "${UNMANAGED_APPS[@]}"; do
  if [ -n "$APP_FILTER" ]; then
    APP_FILTER="$APP_FILTER and "
  fi
  APP_FILTER="$APP_FILTER.app != \"$app\""
done

# Build jq filter for titles
TITLE_FILTER=""
for title in "${UNMANAGED_TITLES[@]}"; do
  if [ -n "$TITLE_FILTER" ]; then
    TITLE_FILTER="$TITLE_FILTER and "
  fi
  TITLE_FILTER="$TITLE_FILTER.title != \"$title\""
done

# Combine filters
FULL_FILTER="[$APP_FILTER and $TITLE_FILTER and .[\"is-floating\"] == true and .[\"has-focus\"] == true]"

# Get all windows that should be managed but aren't
UNMANAGED_COUNT=$(yabai -m query --windows | jq "$FULL_FILTER | length")

# If we found unmanaged windows that should be managed, restart yabai
if [ "$UNMANAGED_COUNT" -gt 0 ]; then
  # Log the restart for debugging
  echo "$(date): Restarting yabai due to $UNMANAGED_COUNT unmanaged windows" >> ~/.yabai_restarts.log
  echo "Apps filter: ${UNMANAGED_APPS[*]}" >> ~/.yabai_restarts.log
  echo "Titles filter: ${UNMANAGED_TITLES[*]}" >> ~/.yabai_restarts.log

  # Restart the service
  yabai --restart-service
fi

yabai -m window --focus recent