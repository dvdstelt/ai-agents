#!/bin/bash
# Container entrypoint: fix cross-platform paths, configure git, then launch Claude.

# Symlink .claude.json into the mounted volume so auth and settings persist
# across containers. Claude Code writes to /root/.claude.json but only
# /root/.claude/ is volume-mounted, so we keep the real file inside the mount.
if [ -f /root/.claude/claude.json ]; then
    ln -sf /root/.claude/claude.json /root/.claude.json
elif [ -d /root/.claude/backups ]; then
    latest=$(ls -t /root/.claude/backups/.claude.json.backup.* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        cp "$latest" /root/.claude/claude.json
        ln -sf /root/.claude/claude.json /root/.claude.json
    fi
fi

# Fix Windows plugin paths for Linux
python3 /usr/local/bin/fix-plugin-paths.py 2>/dev/null

# Set git identity if not already configured
if ! git config --global user.name &>/dev/null; then
    git config --global user.email "dvdstelt@gmail.com"
    git config --global user.name "Dennis van der Stelt"
fi

# Disable automatic git gc inside the container. Worktree gitdir files contain
# Windows host paths which don't resolve on Linux — gc would incorrectly prune
# them. This is safe: the container is ephemeral, gc isn't needed here.
git config --global gc.auto 0

# Allow OpenCode to capture Ctrl+O (WSL/terminal intercepts it by default as
# the "discard output" control character; undefining it frees it for OpenCode).
stty discard undef 2>/dev/null || true

# Suppress the "switched from npm to native installer" warning.
# npm is the correct installation method inside a Docker container.
export DISABLE_INSTALLATION_CHECKS=1

exec "${AGENT_CMD:-claude}" "$@"
