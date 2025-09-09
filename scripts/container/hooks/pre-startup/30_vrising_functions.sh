#!/bin/bash

# This script manages the V-Rising server's JSON configuration files.

log "Applying V-Rising configuration..." "30_vrising_functions.sh"

SETTINGS_DIR="$WORLD_FILES/Settings"
DEFAULT_SETTINGS_DIR="$APP_FILES/VRisingServer_Data/StreamingAssets/Settings"
HOST_SETTINGS_FILE="$SETTINGS_DIR/ServerHostSettings.json"
GAME_SETTINGS_FILE="$SETTINGS_DIR/ServerGameSettings.json"

# --- First-Run Initialization ---
if [ ! -f "$HOST_SETTINGS_FILE" ]; then
    log "First run detected. Copying default server settings to persistent volume." "30_vrising_functions.sh"
    mkdir -p "$SETTINGS_DIR"
    if [ -f "$DEFAULT_SETTINGS_DIR/ServerHostSettings.json" ]; then
        cp "$DEFAULT_SETTINGS_DIR/ServerHostSettings.json" "$HOST_SETTINGS_FILE"
    else
        log "Warning: Default ServerHostSettings.json not found." "30_vrising_functions.sh"
    fi
    if [ -f "$DEFAULT_SETTINGS_DIR/ServerGameSettings.json" ]; then
        cp "$DEFAULT_SETTINGS_DIR/ServerGameSettings.json" "$GAME_SETTINGS_FILE"
    else
        log "Warning: Default ServerGameSettings.json not found." "30_vrising_functions.sh"
    fi
fi

# --- Apply Settings from Environment Variables ---

# Apply updates to ServerHostSettings.json
if command -v jq &> /dev/null && [ -f "$HOST_SETTINGS_FILE" ]; then
    log "Updating ServerHostSettings.json from environment variables..." "30_vrising_functions.sh"
    TMP_JSON=$(mktemp)
    jq \
        --arg name "${SERVER_NAME:-"V-Rising Docker Server"}" \
        --arg desc "${SERVER_DESCRIPTION:-"Powered by Teriyakidactyl"}" \
        --argjson port "${SERVER_PORT:-9876}" \
        --argjson queryPort "${QUERY_PORT:-9877}" \
        --arg saveName "${WORLD_NAME:-"world1"}" \
        --arg password "${SERVER_PASS:-""}" \
        --argjson maxUsers "${MAX_USERS:-40}" \
        --argjson listOnSteam "${LIST_ON_STEAM:-true}" \
        --argjson listOnEOS "${LIST_ON_EOS:-true}" \
        --argjson secure "${SERVER_SECURE:-true}" \
        --argjson rconEnabled "${RCON_ENABLED:-false}" \
        --arg rconPassword "${RCON_PASS:-""}" \
        --argjson rconPort "${RCON_PORT:-25575}" \
        '.Name = $name |
         .Description = $desc |
         .Port = $port |
         .QueryPort = $queryPort |
         .SaveName = $saveName |
         .Password = $password |
         .MaxConnectedUsers = $maxUsers |
         .ListOnSteam = $listOnSteam |
         .ListOnEOS = $listOnEOS |
         .Secure = $secure |
         .Rcon.Enabled = $rconEnabled |
         .Rcon.Password = $rconPassword |
         .Rcon.Port = $rconPort' \
        "$HOST_SETTINGS_FILE" > "$TMP_JSON" && mv "$TMP_JSON" "$HOST_SETTINGS_FILE"
fi

# Apply updates to ServerGameSettings.json
if command -v jq &> /dev/null && [ -f "$GAME_SETTINGS_FILE" ]; then
    log "Updating ServerGameSettings.json from environment variables..." "30_vrising_functions.sh"
    TMP_JSON=$(mktemp)
    jq \
        --arg gameMode "${GAME_MODE:-"PvP"}" \
        --argjson clanSize "${CLAN_SIZE:-4}" \
        --arg preset "${GAME_SETTINGS_PRESET:-""}" \
        '.GameModeType = $gameMode |
         .ClanSize = $clanSize |
         .GameSettingsPreset = $preset' \
        "$GAME_SETTINGS_FILE" > "$TMP_JSON" && mv "$TMP_JSON" "$GAME_SETTINGS_FILE"
fi

# --- Log Final Configuration ---
log "V-Rising configuration applied. Final settings:" "30_vrising_functions.sh"
if [ -f "$HOST_SETTINGS_FILE" ]; then
    log "--- ServerHostSettings.json ---" "30_vrising_functions.sh"
    jq . "$HOST_SETTINGS_FILE" | log_stdout "30_vrising_functions.sh"
fi
if [ -f "$GAME_SETTINGS_FILE" ]; then
    log "--- ServerGameSettings.json ---" "30_vrising_functions.sh"
    jq . "$GAME_SETTINGS_FILE" | log_stdout "30_vrising_functions.sh"
fi
