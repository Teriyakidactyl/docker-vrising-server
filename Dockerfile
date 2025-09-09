# V-Rising Server - Based on docker-steamcmd-server
# This Dockerfile leverages the base image that provides SteamCMD, architecture detection,
# and compatibility layers like Wine, which is required for V-Rising.

# The BASE_TAG and WINE_VERSION arguments allow specifying which versions of the base image and Wine to use.
ARG BASE_TAG=bookworm
ARG WINE_VERSION=9.13
FROM ghcr.io/teriyakidactyl/docker-steamcmd-server:${BASE_TAG}

# Labels for metadata
LABEL org.opencontainers.image.title="V-Rising Server"
LABEL org.opencontainers.image.description="V-Rising dedicated server based on docker-steamcmd-server"
LABEL org.opencontainers.image.vendor="TeriyakiDactyl"
LABEL game.title="V Rising"
LABEL game.developer="Stunlock Studios"
LABEL game.publisher="Stunlock Studios"

# --- Game-specific environment variables ---
ENV \
    # --- Game identification ---
    # The application name
    APP_NAME="vrising" \
    # The server executable file
    APP_EXE="VRisingServer.exe" \
    # The Steam App ID for the dedicated server
    STEAM_SERVER_APPID="1829350" \
    # The platform type for SteamCMD (V-Rising server is Windows)
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
# We use environment variables to build the launch command.
# NOTE: Single quotes are used to delay variable expansion until the container runs.
ENV APP_ARGS='\
-persistentDataPath $PERSISTENT_DATA_PATH \
-serverName "$SERVER_NAME" \
-saveName "$WORLD_NAME" \
-password "$SERVER_PASS" \
-logFile "$LOGS/$APP_EXE.log"'

# --- Expose V-Rising ports ---
# 9876 - Game port
# 9877 - Query port
EXPOSE 9876/udp 9877/udp