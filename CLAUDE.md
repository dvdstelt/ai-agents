# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

A Docker-based wrapper that runs Claude Code (the CLI) inside a container with a pre-installed development environment. Designed for Windows users who want consistent tooling across projects.

## Key Commands

### Build the Docker image

From this repository's root:

```cmd
docker build -t claude-code .
```

### First-time auth setup

```cmd
docker run -it --name claude-setup -v "%USERPROFILE%\.claude:/root/.claude" claude-code
```

After authenticating inside the container, commit and clean up:

```cmd
docker commit claude-setup claude-code
docker rm claude-setup
```

### Save container state back to image

Use this when you've installed something inside a running container and want to keep it:

```cmd
docker commit <container-name> claude-code
docker rm <container-name>
```

For tools you'll always need, add them to the `Dockerfile` and rebuild instead.

## Architecture

**Launcher scripts** (`cc.bat` / `cc.ps1`) are placed on the Windows `PATH` so they can be called from any project folder. Running `cc` from a folder:

1. Derives a container name from the current folder name (e.g. `claude-my-project`)
2. Removes any old container with that name
3. Starts a new `docker run` with three volume mounts:
   - `%USERPROFILE%\.claude` → `/root/.claude` (auth + Claude settings)
   - `%USERPROFILE%\.config` → `/root/.config` (app config)
   - Current working directory → `/workspace` (project files)
4. Auto-loads `.env` from this repo's root if it exists

**`ccc.bat` / `ccc.ps1`** are thin wrappers that call `cc --continue`, which reattaches to the existing named container instead of replacing it.

**The Docker image** (`Dockerfile`) is based on `node:lts-slim` and includes:
- Core utilities: bash, curl, wget, git, jq, tree, build-essential
- Python 3 (with pip and venv)
- .NET SDK (LTS, telemetry disabled)
- Ruby + Bundler
- Node-based static site generators: Astro, Hugo Extended, Eleventy
- Claude Code CLI (`@anthropic-ai/claude-code`)

## Environment Variables

Place a `.env` file in this repo's root. It is automatically passed to every container via `--env-file`. This is the single place to store API keys and secrets needed by all projects.

## SSH Keys for Git

To enable SSH-based Git operations inside containers, add this volume mount to the `docker run` commands in `cc.bat`/`cc.ps1`:

```
-v "%USERPROFILE%\.ssh:/root/.ssh:ro"
```
