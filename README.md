# AI Coding Agents in Docker

Run [Claude Code](https://claude.ai/code) and [OpenCode](https://opencode.ai) inside a Docker container on Windows, with full access to your projects on disk.

## Why

AI coding agents work best with a consistent, pre-configured environment: the right language runtimes, tools, and git identity already in place. This repo provides a Docker image and a set of thin launcher scripts so you can start an agent session in any project folder with a single command, without installing anything into your Windows environment.

## Quick Start

See **[usage.md](usage.md)** for full setup and usage instructions, including:

- Building the Docker image
- First-time authentication for Claude Code and OpenCode
- The `cc`, `ccc`, `oc`, `occ`, and `ccd` commands
- Worktree support
- Port mapping for dev servers
- Maintenance (rebuilding, committing changes back to the image)

## Blog Series

This repo is the companion to a blog series on running AI coding agents in Docker:

[AI Coding Agents in Docker - BloggingAbout.NET](https://bloggingabout.net/2026/02/25/ai-coding-agents-in-docker/)
