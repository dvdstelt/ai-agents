# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Git Workflow

Worktrees are not required here.

**Do not commit automatically.** After completing a change, suggest a commit message but do not stage or commit anything. The user commits manually.

## What This Project Is

A Docker-based wrapper that runs AI coding agents (Claude Code, OpenCode) inside a container with a pre-installed development environment. Designed for Windows users who want consistent tooling across projects.

## Architecture

**`docker-run.bat` / `docker-run.ps1`** contain all shared Docker logic (container naming, volume mounts, port mapping, env file loading). Thin wrapper scripts (`cc`, `oc`, `ccc`, `ccd`, `occ`) are one-liners that call `docker-run` with the right prefix and tool command.

Running `cc` (or `oc`) from a folder:

1. Derives a container name from the prefix and current folder name (e.g. `claude-my-project`)
2. Removes any old container with that name
3. Mounts the **parent directory** as `/workspace` so sibling folders and worktrees are visible
4. Sets the working directory to `/workspace/<folder-name>`
5. Volume mounts:
   - `%USERPROFILE%\.claude` -> `/root/.claude` (auth and settings)
   - `%USERPROFILE%\.config` -> `/root/.config` (app config)
   - Parent of current directory -> `/workspace` (project files and siblings)
6. Maps a random host port (20000-52767) to container port 1337
7. Auto-loads `.env` from this repo's root if it exists

**`ccc` / `occ`** continue the previous session for Claude Code / OpenCode respectively.

**`ccd`** opens a bash shell in a running container.

**`entrypoint.sh`** runs on every container start and handles git identity setup and plugin path fixes (Windows to Linux path rewriting).

**The Docker image** (`Dockerfile`) is based on `node:lts-slim` and includes:
- Core utilities: bash, curl, wget, git, jq, tree, build-essential, etc.
- Just (task runner)
- Python 3 (with pip and venv)
- .NET SDK (LTS, telemetry disabled) with dotnet-outdated-tool
- Ruby + Bundler
- Node-based static site generators: Astro, Hugo Extended, Eleventy
- RTK (token-optimized CLI proxy)
- Claude Code CLI (`@anthropic-ai/claude-code`)
- OpenCode (`opencode-ai`)

**Helper scripts** included in the image:
- `git-wtadd` - creates worktrees with cross-platform path handling
- `portnumber` - shows the mapped host port for container port 1337
- `fix-plugin-paths.py` - rewrites Windows plugin paths to Linux paths
