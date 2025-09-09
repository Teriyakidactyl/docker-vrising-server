# V-Rising Server - Based on docker-steamcmd-server
# This Dockerfile leverages the base image that provides SteamCMD, architecture detection,
# and compatibility layers like Wine, which is required for V-Rising.

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
    mkdir -p "$WORLD_FILES/save-data" \
             "$WORLD_FILES/Settings" \
             "$APP_FILES/VRisingServer_Data/StreamingAssets/Settings" && \
    # Link the persistent Settings folder to where the game expects to find it.
    ln -sf "$WORLD_FILES/Settings" "$APP_FILES/VRisingServer_Data/StreamingAssets/Settings" && \
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
    # --- Server configuration (defaults that can be overridden) ---
    SERVER_NAME="My V-Rising Server" \
    SERVER_PASS="MySecretPassword" \
    WORLD_NAME="world1" \
    SERVER_PORT="9876" \
    QUERY_PORT="9877" \
    \
    # --- Path for server settings and save data ---
    # This path is inside the $WORLD_FILES volume mount.
    PERSISTENT_DATA_PATH="$WORLD_FILES/save-data"

# --- Define the command line arguments for the server ---
ENV APP_ARGS='\
-persistentDataPath $PERSISTENT_DATA_PATH \
-serverName "$SERVER_NAME" \
-saveName "$WORLD_NAME" \
-password "$SERVER_PASS" \
-logFile "$LOGS/$APP_EXE.log"'

# Copy game-specific hook scripts into the container
COPY --chown=${CONTAINER_USER}:${CONTAINER_USER} scripts/container/hooks/pre-startup/30_vrising_functions.sh ${HOOK_DIRECTORIES}/pre-startup/

# --- Expose V-Rising ports ---
EXPOSE 9876/udp 9877/udp

