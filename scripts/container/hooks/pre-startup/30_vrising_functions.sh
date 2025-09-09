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

# Apply updates to ServerHostSettings.json
if command -v jq &> /dev/null && [ -f "$HOST_SETTINGS_FILE" ]; then
    log "Updating ServerHostSettings.json from environment variables..." "30_vrising_config.sh"
    
    TMP_JSON=$(mktemp)

    # Sequentially apply updates to ServerHostSettings.json
    jq --arg name "$SERVER_NAME" '.Name = $name' "$HOST_SETTINGS_FILE" | \
    jq --arg desc "$SERVER_DESCRIPTION" '.Description = $desc' | \
    jq --argjson port "$SERVER_PORT" '.Port = $port' | \
    jq --argjson queryPort "$QUERY_PORT" '.QueryPort = $queryPort' | \
    jq --arg saveName "$WORLD_NAME" '.SaveName = $saveName' | \
    jq --arg password "$SERVER_PASS" '.Password = $password' | \
    jq --argjson maxUsers "$MAX_USERS" '.MaxConnectedUsers = $maxUsers' | \
    jq --argjson listOnSteam "$LIST_ON_STEAM" '.ListOnSteam = $listOnSteam' | \
    jq --argjson listOnEOS "$LIST_ON_EOS" '.ListOnEOS = $listOnEOS' | \
    jq --argjson secure "$SERVER_SECURE" '.Secure = $secure' | \
    jq --argjson enabled "${RCON_ENABLED:-false}" '.Rcon.Enabled = $enabled' | \
    jq --arg password "${RCON_PASS:-""}" '.Rcon.Password = $password' | \
    jq --argjson port "${RCON_PORT:-25575}" '.Rcon.Port = $port' > "$TMP_JSON"

    mv "$TMP_JSON" "$HOST_SETTINGS_FILE"
    
    log "ServerHostSettings.json updated successfully." "30_vrising_config.sh"
else
    log "Warning: 'jq' is not installed or ServerHostSettings.json not found. Cannot apply ENV settings." "30_vrising_config.sh"
fi

# Apply updates to ServerGameSettings.json
if command -v jq &> /dev/null && [ -f "$GAME_SETTINGS_FILE" ]; then
    log "Updating ServerGameSettings.json from environment variables..." "30_vrising_config.sh"

    TMP_JSON=$(mktemp)

    # Sequentially apply updates to ServerGameSettings.json
    jq --arg gameMode "$GAME_MODE" '.GameModeType = $gameMode' "$GAME_SETTINGS_FILE" | \
    jq --argjson clanSize "$CLAN_SIZE" '.ClanSize = $clanSize' | \
    jq --arg preset "${GAME_SETTINGS_PRESET:-""}" '.GameSettingsPreset = $preset' > "$TMP_JSON"

    mv "$TMP_JSON" "$GAME_SETTINGS_FILE"

    log "ServerGameSettings.json updated successfully." "30_vrising_config.sh"
else
    log "Warning: 'jq' is not installed or ServerGameSettings.json not found. Cannot apply ENV settings." "30_vrising_config.sh"
fi

# --- Log Final Configuration ---
log "V-Rising configuration applied. Final settings:" "30_vrising_config.sh"
log "--- ServerHostSettings.json ---" "30_vrising_config.sh"
cat "$HOST_SETTINGS_FILE" | log_stdout "30_vrising_config.sh"
log "--- ServerGameSettings.json ---" "30_vrising_config.sh"
cat "$GAME_SETTINGS_FILE" | log_stdout "30_vrising_config.sh"
