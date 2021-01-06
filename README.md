# PaperMC-Docker
A Docker container for the PaperMC Minecraft server. (What's in the name...)

## What does it have?
- Responds properly to SIGTERM/SIGINT. (By default the server does not respond very well to those signals.)
- Control through RCON.
- Minecraft RCON client pre-installed.
- MCStatus pre-installed.
- Docker healthcheck.
- Separate volumes for data and logs.
- Recommended startup flags for Java for theoretically better performance.
- Based on lightweight Alpine

## What shortcomings does it have?
- No direct console as the server runs in the background. (Which is required for correct handling of signals.)
- The server itself is not running as PID 1.

## Cool, how do I use it?
The following configuration options are available through environment variables:
- `JAVA_XMS`: Initial Java heap size. (Default 2G)
- `JAVA_XMX`: Maximum Java heap size. (Default 2G)
- `RCON_PASSWORD`: Password for RCON. *Please change this! Recommended to only use A-Z, a-z and 0-9.* (Default: ChangeMe)

It uses the following volumes:
- `/data` for the server data, like the world.
- `/logs` for server logs.

It exposes the following ports:
- `25565` for the Minecraft server.
- `25575` for RCON.

If you need the server to run on another port than default, please do that within Docker when running the container.
