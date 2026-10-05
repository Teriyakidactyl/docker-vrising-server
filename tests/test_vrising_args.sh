#!/bin/bash

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGS_FILE="$REPO_ROOT/scripts/container/vrising.args"

export WORLD_FILES='/world with spaces'
export APP_EXE='VRisingServer.exe'

mapfile -t args < <(envsubst < "$ARGS_FILE")

expected=(
  -persistentDataPath
  '/world with spaces'
  -logFile
  '/world with spaces/logs/VRisingServer.exe.log'
)

if [ "${#args[@]}" -ne "${#expected[@]}" ]; then
  printf 'expected %d arguments, got %d\n' "${#expected[@]}" "${#args[@]}" >&2
  exit 1
fi

for i in "${!expected[@]}"; do
  if [ "${args[$i]}" != "${expected[$i]}" ]; then
    printf 'argument %d mismatch: expected <%s>, got <%s>\n' "$i" "${expected[$i]}" "${args[$i]}" >&2
    exit 1
  fi
done

echo "V Rising argument contract test passed"
