#!/bin/bash
# Native Linux launcher for Claude Code.
# Usage: cc.sh [--risk] [args...]

CLAUDE_FLAGS=()

for arg in "$@"; do
    case "$arg" in
        --risk) CLAUDE_FLAGS+=("--dangerously-skip-permissions") ;;
        *)      CLAUDE_FLAGS+=("$arg") ;;
    esac
done

exec claude "${CLAUDE_FLAGS[@]}"
