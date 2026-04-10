# AI Coding Agents in Docker

Run [Claude Code](https://claude.ai/code) and [OpenCode](https://opencode.ai) inside a Docker container on Windows, with full access to your projects on disk.

## Why

AI coding agents work best with a consistent, pre-configured environment: the right language runtimes, tools, and git identity already in place. This repo provides a Docker image and a set of thin launcher scripts so you can start an agent session in any project folder with a single command, without installing anything into your Windows environment.

## Documentation

- **[image-setup-windows.md](image-setup-windows.md)** - Building and configuring the image (Windows / Docker)
- **[image-setup-linux.md](image-setup-linux.md)** - Building and configuring the image (Linux / Podman)
- **[usage.md](usage.md)** - Commands, host setup, worktrees, and port mapping

## Blog Series

This repo is the companion to a blog series on running AI coding agents in Docker:

[AI Coding Agents in Docker - BloggingAbout.NET](https://bloggingabout.net/2026/02/25/ai-coding-agents-in-docker/)
