#!/bin/bash

# This script manages the V-Rising server's JSON configuration files
# using a data-driven approach for maintainability.

log "Applying V-Rising configuration..." "30_vrising_functions.sh"

SETTINGS_DIR="$WORLD_FILES/Settings"
DEFAULT_SETTINGS_DIR="$APP_FILES/VRisingServer_Data/StreamingAssets/Settings"
HOST_SETTINGS_FILE="$SETTINGS_DIR/ServerHostSettings.json"
GAME_SETTINGS_FILE="$SETTINGS_DIR/ServerGameSettings.json"

# --- First-Run Initialization ---
# This remains the same as it's a necessary bootstrapping step.
if [ ! -f "$HOST_SETTINGS_FILE" ]; then
    log "First run detected. Copying default server settings..." "30_vrising_functions.sh"
    mkdir -p "$SETTINGS_DIR"
    if [ -f "$DEFAULT_SETTINGS_DIR/ServerHostSettings.json" ]; then
        cp "$DEFAULT_SETTINGS_DIR/ServerHostSettings.json" "$HOST_SETTINGS_FILE"
    fi
    if [ -f "$DEFAULT_SETTINGS_DIR/ServerGameSettings.json" ]; then
        cp "$DEFAULT_SETTINGS_DIR/ServerGameSettings.json" "$GAME_SETTINGS_FILE"
    fi
fi

# --- Universal Settings Application Function ---
apply_settings() {
    local config_file="$1"
    # The second argument is the name of the associative array map
    local -n settings_map="$2"
    local jq_filter=""
    local jq_args=()

    log "Applying settings to $(basename "$config_file")..." "30_vrising_functions.sh"
    
    # Dynamically build the jq filter and arguments
    for env_var in "${!settings_map[@]}"; do
        # Check if the environment variable is set by the user
        if [ -n "${!env_var}" ]; then
            local mapping="${settings_map[$env_var]}"
            local type="${mapping%%:*}"
            local path="${mapping#*:}"
            local value="${!env_var}"
            # Sanitize variable name for jq
            local jq_var_name="${env_var,,}"

            log "  - Setting ${path} to ${value}" "30_vrising_functions.sh"
            
            # Add the appropriate jq argument type (--arg or --argjson)
            if [ "$type" == "json" ]; then
                jq_args+=(--argjson "$jq_var_name" "$value")
            else
                jq_args+=(--arg "$jq_var_name" "$value")
            fi
            
            # Append the filter to the main jq command string
            jq_filter+=" | ${path} = \$${jq_var_name}"
        fi
    done

    # If we have a filter to apply, run the jq command
    if [ -n "$jq_filter" ]; then
        # Remove the leading " |" from the filter string
        jq_filter="${jq_filter:3}"
        local TMP_JSON
        TMP_JSON=$(mktemp)
        jq "${jq_args[@]}" "$jq_filter" "$config_file" > "$TMP_JSON" && mv "$TMP_JSON" "$config_file"
    else
        log "No custom settings applied to $(basename "$config_file")." "30_vrising_functions.sh"
    fi
}

# --- Define Mappings and Apply Settings ---

# Mappings for ServerHostSettings.json
declare -A host_settings_map=(
    ["SERVER_NAME"]="string:.Name"
    ["SERVER_DESCRIPTION"]="string:.Description"
    ["SERVER_PORT"]="json:.Port"
    ["QUERY_PORT"]="json:.QueryPort"
    ["WORLD_NAME"]="string:.SaveName"
    ["SERVER_PASS"]="string:.Password"
    ["MAX_USERS"]="json:.MaxConnectedUsers"
    ["LIST_ON_STEAM"]="json:.ListOnSteam"
    ["LIST_ON_EOS"]="json:.ListOnEOS"
    ["SERVER_SECURE"]="json:.Secure"
    ["RCON_ENABLED"]="json:.Rcon.Enabled"
    ["RCON_PASS"]="string:.Rcon.Password"
    ["RCON_PORT"]="json:.Rcon.Port"
)
if [ -f "$HOST_SETTINGS_FILE" ]; then
    apply_settings "$HOST_SETTINGS_FILE" host_settings_map
fi

# Mappings for ServerGameSettings.json
declare -A game_settings_map=(
    ["GAME_MODE"]="string:.GameModeType"
    ["CLAN_SIZE"]="json:.ClanSize"
    ["GAME_SETTINGS_PRESET"]="string:.GameSettingsPreset"
    ["LAN_MODE"]="json:.PlayerInteractionSettings.LanMode"
)
if [ -f "$GAME_SETTINGS_FILE" ]; then
    apply_settings "$GAME_SETTINGS_FILE" game_settings_map
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

