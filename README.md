# Docker V-Rising Server Images

This Docker image provides a V-Rising dedicated server, supporting both `amd64` and `arm64` architectures.

![Teriyakidactyl Delivers!™](images/teriyakidactyl_vrising.png)

**_Teriyakidactyl Delivers!™_**

## Features

-   Supports `amd64` and `arm64` architectures.
-   Runs the Windows-based V-Rising server using **Wine** for full compatibility.
-   Runs under a non-root user for enhanced security.
-   Automatic server updates via [SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD) on container start.
-   Cross-platform compatibility for `arm64` systems using [Box86](https://github.com/ptitSeb/box86)/[Box64](https://github.com/ptitSeb/box64).
-   Lightweight, running only the minimal packages required for stability.
-   Organized, colored logs for easy monitoring.

## Environment Variables

Configure your server by setting the following environment variables in your `docker-compose.yml` file:

| Variable      | Description                                           | Default                     |
| :------------ | :---------------------------------------------------- | :-------------------------- |
| `SERVER_NAME` | The name that appears in the in-game server list.     | `"My V-Rising Server"`      |
| `WORLD_NAME`  | The name of the save file/directory for the world.    | `"world1"`                  |
| `SERVER_PASS` | The password required to connect to the server.       | `"MySecretPassword"`        |
| `SERVER_PORT` | The UDP port for game traffic.                        | `"9876"`                    |
| `QUERY_PORT`  | The UDP port for Steam server queries.                | `"9877"`                    |

## Usage

The recommended way to run this server is using `docker-compose`, which makes configuration and volume management straightforward.

1.  **Create `docker-compose.yml`**: Save the `docker-compose.yml` file provided in this repository to a directory on your server.

2.  **Customize the Environment**: Edit the `environment` section in `docker-compose.yml` to set your desired server name, world name, and password.

3.  **Start the Server**: Run the following command in the same directory as your `docker-compose.yml` file:

    ```bash
    docker-compose up -d
    ```

    This command will build the image if it doesn't exist locally, create the necessary volumes for persistent data, and start the server in the background.

## Building the Image

If you prefer to build the image manually, you can do so with the following command from the root of the repository:

```bash
docker build -t ghcr.io/teriyakidactyl/docker-vrising-server:latest .
```

## Docker Image Tags

Our Docker images are tagged using a comprehensive scheme to ensure proper versioning and traceability, managed by the GitHub Actions workflows.

-   **Branch-based tags**: `main`, `dev`
-   **Pull Request tags**: `pr-<PR-number>`
-   **Semantic Version tags**: `1.2.3`, `1.2`
-   **Commit SHA tags**: `sha-<full-commit-hash>`

The latest build from the `main` branch is always available with the `latest` tag.