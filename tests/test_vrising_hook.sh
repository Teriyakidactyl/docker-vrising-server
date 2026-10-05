#!/bin/bash

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO_ROOT/scripts/container/hooks/pre-startup/30_vrising_functions.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

export APP_FILES="$TMP_ROOT/app"
export WORLD_FILES="$TMP_ROOT/world"
export LOGS="$TMP_ROOT/container-logs"
export SERVER_NAME='CI V Rising'
export SERVER_DESCRIPTION='contract test'
export SERVER_PASS='player-secret-value'
export WORLD_NAME='ci-world'
export SERVER_PORT='9876'
export QUERY_PORT='9877'
export MAX_USERS='20'
export LIST_ON_STEAM='true'
export LIST_ON_EOS='false'
export SERVER_SECURE='true'
export RCON_ENABLED='true'
export RCON_PASS='rcon-secret-value'
export RCON_PORT='25575'
export GAME_MODE='PvE'
export CLAN_SIZE='4'
export GAME_SETTINGS_PRESET=''
export LAN_MODE='false'

TEST_LOG="$TMP_ROOT/hook.log"
log() {
  printf '%s\n' "$*" >> "$TEST_LOG"
}
log_stdout() {
  cat >> "$TEST_LOG"
}

DEFAULT_SETTINGS_DIR="$APP_FILES/VRisingServer_Data/StreamingAssets/Settings"
mkdir -p "$DEFAULT_SETTINGS_DIR"

cat > "$DEFAULT_SETTINGS_DIR/ServerHostSettings.json" <<'JSON'
{
  "Name": "Default",
  "Description": "",
  "Port": 9876,
  "QueryPort": 9877,
  "SaveName": "world1",
  "Password": "",
  "MaxConnectedUsers": 40,
  "ListOnSteam": true,
  "ListOnEOS": true,
  "Secure": true,
  "Rcon": {
    "Enabled": false,
    "Password": "",
    "Port": 25575
  }
}
JSON

cat > "$DEFAULT_SETTINGS_DIR/ServerGameSettings.json" <<'JSON'
{
  "GameModeType": "PvP",
  "ClanSize": 4,
  "GameSettingsPreset": "",
  "PlayerInteractionSettings": {
    "LanMode": true
  }
}
JSON

source "$HOOK"

HOST="$WORLD_FILES/Settings/ServerHostSettings.json"
GAME="$WORLD_FILES/Settings/ServerGameSettings.json"

test -L "$APP_FILES/VRisingServer_Data/StreamingAssets/Settings"
test -L "$APP_FILES/logs"
test -L "$LOGS/vrising"

jq -e '
  .Name == "CI V Rising"
  and .Description == "contract test"
  and .Password == "player-secret-value"
  and .MaxConnectedUsers == 20
  and .ListOnSteam == true
  and .ListOnEOS == false
  and .Rcon.Enabled == true
  and .Rcon.Password == "rcon-secret-value"
' "$HOST" >/dev/null

jq -e '
  .GameModeType == "PvE"
  and .ClanSize == 4
  and .PlayerInteractionSettings.LanMode == false
' "$GAME" >/dev/null

if grep -Fq 'player-secret-value' "$TEST_LOG"; then
  echo 'player password leaked to hook logs' >&2
  exit 1
fi
if grep -Fq 'rcon-secret-value' "$TEST_LOG"; then
  echo 'RCON password leaked to hook logs' >&2
  exit 1
fi

inode_before="$(stat -c '%i' "$HOST")"
source "$HOOK"
inode_after="$(stat -c '%i' "$HOST")"
test "$inode_before" != "" && test "$inode_after" != ""

echo "V Rising hook contract test passed"
