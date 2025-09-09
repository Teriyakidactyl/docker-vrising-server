#!/bin/bash

# This script manages the V-Rising server's JSON configuration files.

log "Applying V-Rising configuration..." "30_vrising_config.sh"

SETTINGS_DIR="$WORLD_FILES/Settings"
DEFAULT_SETTINGS_DIR="$APP_FILES/VRisingServer_Data/StreamingAssets/Settings"
HOST_SETTINGS_FILE="$SETTINGS_DIR/ServerHostSettings.json"
GAME_SETTINGS_FILE="$SETTINGS_DIR/ServerGameSettings.json"

# --- First-Run Initialization ---
# If the host settings file doesn't exist in the persistent volume,
# copy the default configurations over. This simplifies the first-time setup.
if [ ! -f "$HOST_SETTINGS_FILE" ]; then
    log "First run detected. Copying default server settings to persistent volume." "30_vrising_config.sh"
    # Ensure the target directory exists
    mkdir -p "$SETTINGS_DIR"
    # Copy default files if they exist in the source directory
    if [ -f "$DEFAULT_SETTINGS_DIR/ServerHostSettings.json" ]; then
        cp "$DEFAULT_SETTINGS_DIR/ServerHostSettings.json" "$HOST_SETTINGS_FILE"
    else
        log "Warning: Default ServerHostSettings.json not found." "30_vrising_config.sh"
    fi
    if [ -f "$DEFAULT_SETTINGS_DIR/ServerGameSettings.json" ]; then
        cp "$DEFAULT_SETTINGS_DIR/ServerGameSettings.json" "$GAME_SETTINGS_FILE"
    else
        log "Warning: Default ServerGameSettings.json not found." "30_vrising_config.sh"
    fi
fi

# --- Apply Settings from Environment Variables ---
# Use 'jq' to update the JSON configuration files with values from environment variables.
# This is more robust than simple text replacement.

if command -v jq &> /dev/null && [ -f "$HOST_SETTINGS_FILE" ]; then
    log "Updating ServerHostSettings.json from environment variables..." "30_vrising_config.sh"
    
    # Create a temporary file to hold the modified JSON
    TMP_JSON=$(mktemp)

    # Sequentially apply updates using jq
    jq --arg name "$SERVER_NAME" '.Name = $name' "$HOST_SETTINGS_FILE" | \
    jq --arg desc "Running on Teriyakidactyl Base Image" '.Description = $desc' | \
    jq --argjson port "$SERVER_PORT" '.Port = $port' | \
    jq --argjson queryPort "$QUERY_PORT" '.QueryPort = $queryPort' | \
    jq --arg saveName "$WORLD_NAME" '.SaveName = $saveName' | \
    jq --arg password "$SERVER_PASS" '.Password = $password' > "$TMP_JSON"

    # Overwrite the original file with the updated one
    mv "$TMP_JSON" "$HOST_SETTINGS_FILE"
    
    log "ServerHostSettings.json updated successfully." "30_vrising_config.sh"
else
    log "Warning: 'jq' is not installed or ServerHostSettings.json not found. Cannot apply ENV settings." "30_vrising_config.sh"
fi

# You can add similar logic here to modify ServerGameSettings.json if needed.

log "V-Rising configuration applied." "30_vrising_config.sh"
