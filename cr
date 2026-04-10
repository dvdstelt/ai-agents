#!/bin/bash
# Continue the previous Claude Code session in Docker.
# Usage: ccc.sh [--risk] [args...]
exec "$(dirname "$0")/docker-run.sh" claude --continue "$@"
