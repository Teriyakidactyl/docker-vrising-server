# V-Rising Server - Based on docker-steamcmd-server
# This Dockerfile leverages the base image that provides SteamCMD, architecture detection,
# and compatibility layers like Wine, which is required for V-Rising.

# Reference: https://github.com/StunlockStudios/vrising-dedicated-server-instructions/blob/master/1.1.x-pc/INSTRUCTIONS.md
# Wine: https://steamcommunity.com/sharedfiles/filedetails/?id=2880599658

# The BASE_TAG argument allows specifying which version of the base image to use.
ARG BASE_TAG=trixie-20250407-slim_wine-staging-10.5
FROM ghcr.io/teriyakidactyl/docker-steamcmd-server:${BASE_TAG}

# Labels for metadata
LABEL org.opencontainers.image.title="V-Rising Server" \
      org.opencontainers.image.description="V-Rising dedicated server based on docker-steamcmd-server" \
      org.opencontainers.image.vendor="TeriyakiDactyl"

# --- Switch to ROOT user to install dependencies ---
USER root

# --- Install jq and create directories/links for persistence ---
RUN apt-get update && apt-get install -y --no-install-recommends jq && \
    # Clean up apt cache to keep image size down
    rm -rf /var/lib/apt/lists/* && \
    # Create persistent directories for settings, logs, and the Wine prefix
    mkdir -p "$WORLD_FILES/Settings" \
             "$WORLD_FILES/logs" \
             "$WORLD_FILES/wineprefix" \
             "$APP_FILES/VRisingServer_Data/StreamingAssets/Settings" && \
    # Link the persistent Settings folder to where the game expects it
    ln -sf "$WORLD_FILES/Settings" "$APP_FILES/VRisingServer_Data/StreamingAssets/Settings" && \
    \
    # --- LOGGING SETUP (Conan-Style) ---
    # 1. Link the app's default log directory to our persistent logs folder.
    ln -sf "$WORLD_FILES/logs" "$APP_FILES/logs" && \
    # 2. Link the entire persistent logs directory into the main container log directory.
    ln -sf "$WORLD_FILES/logs" "$LOGS/vrising" && \
    \
    # Ensure the container user owns all relevant directories.
    chown -R ${CONTAINER_USER}:${CONTAINER_USER} "$WORLD_FILES" "$APP_FILES" "$LOGS"

# --- Switch back to the non-root user for security ---
USER ${CONTAINER_USER}

# --- Game-specific environment variables ---
ENV \
    # --- Game identification ---
    APP_NAME="vrising" \
    APP_EXE="VRisingServer.exe" \
    STEAM_SERVER_APPID="1829350" \
    STEAM_PLATFORM_TYPE="windows" \
    \
    # --- Server Host Settings Defaults ---
    SERVER_NAME="My V-Rising Server" \
    SERVER_DESCRIPTION="A V-Rising Server powered by Teriyakidactyl" \
    SERVER_PASS="MySecretPassword" \
    WORLD_NAME="world1" \
    \
    SERVER_PORT="9876" \
    QUERY_PORT="9877" \
    \
    MAX_USERS="40" \
    LIST_ON_STEAM="true" \
    LIST_ON_EOS="true" \
    SERVER_SECURE="true" \
    \
    # --- RCON Defaults ---
    RCON_ENABLED="false" \
    RCON_PASS="" \
    RCON_PORT="25575" \
    \
    # --- Server Game Settings Defaults ---
    GAME_MODE="PvP" \
    CLAN_SIZE="4" \
    GAME_SETTINGS_PRESET="" \
    LAN_MODE="true"


# --- Define the command line arguments for the server ---
ENV APP_ARGS='\
-persistentDataPath $WORLD_FILES \
-logFile "$WORLD_FILES/logs/$APP_EXE.log"'

# -saveName "$WORLD_NAME" \
# -password "$SERVER_PASS" \
# -serverName "$SERVER_NAME" \

# Copy game-specific hook scripts into the container
COPY --chown=${CONTAINER_USER}:${CONTAINER_USER} scripts/container/hooks/pre-startup/30_vrising_functions.sh ${HOOK_DIRECTORIES}/pre-startup/

# --- Expose V-Rising ports ---
EXPOSE $SERVER_PORT/udp $QUERY_PORT/udp

