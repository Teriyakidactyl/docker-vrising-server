# V-Rising Server - Based on docker-steamcmd-server
# This Dockerfile leverages the base image that provides SteamCMD, architecture detection,
# and compatibility layers like Wine, which is required for V-Rising.

# Reference: https://github.com/StunlockStudios/vrising-dedicated-server-instructions/blob/master/1.1.x-pc/INSTRUCTIONS.md
# Wine: https://steamcommunity.com/sharedfiles/filedetails/?id=2880599658

# Follow the shared base's supported Wine-staging alias. Wine version and
# architecture policy belong to docker-steamcmd-server, not this derivative.
ARG BASE_IMAGE=ghcr.io/teriyakidactyl/docker-steamcmd-server
ARG BASE_TAG=trixie_wine-staging
FROM ${BASE_IMAGE}:${BASE_TAG}

ARG BASE_IMAGE
ARG BASE_TAG

# Labels for metadata
LABEL org.opencontainers.image.title="V-Rising Server" \
      org.opencontainers.image.description="V-Rising dedicated server based on docker-steamcmd-server" \
      org.opencontainers.image.vendor="TeriyakiDactyl" \
      org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}"

# --- Switch to ROOT user to install dependencies ---
USER root

# Persistence topology is intentionally established by the pre-start hook, not
# here. /app and /world are commonly runtime mounts, so image-layer symlinks
# beneath them disappear as soon as those volumes are attached.
RUN apt-get update && apt-get install -y --no-install-recommends jq && \
    rm -rf /var/lib/apt/lists/*

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

