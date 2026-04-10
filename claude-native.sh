#!/bin/bash
# Start a new Claude Code session in Docker.
# Usage: cc.sh [--risk] [args...]
exec "$(dirname "$0")/docker-run.sh" claude "$@"
