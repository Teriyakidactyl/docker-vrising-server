#!/bin/bash

set -Eeo pipefail

# This script manages the V-Rising server's JSON configuration files
# using a data-driven approach for maintainability.

log "Applying V-Rising configuration..." "30_vrising_functions.sh"

SETTINGS_DIR="$WORLD_FILES/Settings"
DEFAULT_SETTINGS_DIR="$APP_FILES/VRisingServer_Data/StreamingAssets/Settings"
HOST_SETTINGS_FILE="$SETTINGS_DIR/ServerHostSettings.json"
GAME_SETTINGS_FILE="$SETTINGS_DIR/ServerGameSettings.json"

# SteamCMD updates the application before derivative hooks run. That means a
# game update may recreate a real directory where we previously had a symlink.
# Reconcile the topology on every start so named volumes, bind mounts, and game
# updates all converge on the same persistent paths.
#
# Existing files are migrated without clobbering already-persistent operator
# state. An unexpected symlink is treated as an ownership conflict instead of
# being silently replaced.
persist_directory() {
    local source_path="$1"
    local target_path="$2"
    local current_target
    local current_target_path

    mkdir -p "$(dirname "$source_path")" "$target_path"

    if [ -L "$source_path" ]; then
        current_target="$(readlink "$source_path")"
        if [[ "$current_target" = /* ]]; then
            current_target_path="$(realpath -m "$current_target")"
        else
            current_target_path="$(realpath -m "$(dirname "$source_path")/$current_target")"
        fi

        if [ "$current_target_path" != "$(realpath -m "$target_path")" ]; then
            log "ERROR: $source_path points to $current_target; expected $target_path" "30_vrising_functions.sh"
            return 1
        fi
        return 0
    fi

    if [ -e "$source_path" ]; then
        if [ ! -d "$source_path" ]; then
            log "ERROR: $source_path exists but is not a directory" "30_vrising_functions.sh"
            return 1
        fi
        cp -a -n "$source_path/." "$target_path/"
        rm -rf "$source_path"
    fi

    ln -s "$target_path" "$source_path"
}

persist_directory "$DEFAULT_SETTINGS_DIR" "$SETTINGS_DIR"
persist_directory "$APP_FILES/logs" "$WORLD_FILES/logs"
persist_directory "$LOGS/vrising" "$WORLD_FILES/logs"

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

            if [[ "$env_var" == "SERVER_PASS" || "$env_var" == "RCON_PASS" ]]; then
                log "  - Setting ${path} to <redacted>" "30_vrising_functions.sh"
            else
                log "  - Setting ${path} to ${value}" "30_vrising_functions.sh"
            fi
            
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
    jq '
        if has("Password") then .Password = "<redacted>" else . end
        | if (.Rcon? | type) == "object" and (.Rcon | has("Password")) then .Rcon.Password = "<redacted>" else . end
    ' "$HOST_SETTINGS_FILE" | log_stdout "30_vrising_functions.sh"
fi
if [ -f "$GAME_SETTINGS_FILE" ]; then
    log "--- ServerGameSettings.json ---" "30_vrising_functions.sh"
    jq . "$GAME_SETTINGS_FILE" | log_stdout "30_vrising_functions.sh"
fi

