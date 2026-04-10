#!/bin/bash
# Central Docker launcher for containerized dev tools (Linux).
# Usage: docker-run.sh <tool-cmd> [args...]
#   tool-cmd  Command to run inside the container (e.g. claude, opencode)
#   args      Forwarded to the tool command (e.g. --continue, /bin/bash)

set -euo pipefail

DOCKER=podman

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_CMD="${1:?Usage: docker-run.sh <tool-cmd> [args...]}"
shift

# Avoid Docker's default detach sequence (Ctrl+P Ctrl+Q) stealing Ctrl+P.
DETACH_KEYS="ctrl-],ctrl-q"

# Parse args: detect special flags, translate --risk, collect tool flags
HAS_CONTINUE=""
HAS_BASH=""
CLAUDE_FLAGS=()
for arg in "$@"; do
    case "$arg" in
        --continue) HAS_CONTINUE=1 ;;
        /bin/bash)  HAS_BASH=1 ;;
        --risk)     CLAUDE_FLAGS+=("--dangerously-skip-permissions") ;;
        *)          CLAUDE_FLAGS+=("$arg") ;;
    esac
done

# Create a container name from the folder name (replace @ with -)
WORK_DIR="$(pwd)"
FOLDER_NAME="$(basename "$WORK_DIR")"
CONTAINER_NAME="ai-${FOLDER_NAME//@/-}"

# Get the parent directory (mounted as /workspace so worktrees are visible)
PARENT_DIR="$(dirname "$WORK_DIR")"

# Pick a random host port (20000-52767) for container port 1337
HOST_PORT=$(( RANDOM % 10000 + 20000 ))

# Check for .env file in ai-agents folder
ENV_FLAG=()
if [ -f "$SCRIPT_DIR/.env" ]; then
    ENV_FLAG=(--env-file "$SCRIPT_DIR/.env")
    echo "Loading .env file from $SCRIPT_DIR"
fi

# Ensure mount targets exist
mkdir -p "$HOME/.config/rtk" "$HOME/.config/opencode" "$HOME/.ssh"

echo "Mounting: $PARENT_DIR (project: $FOLDER_NAME)"
echo "Container: $CONTAINER_NAME"
echo ""

# Handle --continue: reattach to existing container, or start fresh if none exists
if [ -n "$HAS_CONTINUE" ]; then
    if $DOCKER container inspect "$CONTAINER_NAME" &>/dev/null; then
        echo "Continuing previous session..."
        $DOCKER start "$CONTAINER_NAME"
        $DOCKER exec -it --detach-keys="$DETACH_KEYS" -e CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1 "$CONTAINER_NAME" "$TOOL_CMD" --continue "${CLAUDE_FLAGS[@]}"
    else
        echo "No previous session found, starting fresh..."
        $DOCKER run -it \
            --detach-keys="$DETACH_KEYS" \
            --name "$CONTAINER_NAME" \
            "${ENV_FLAG[@]}" \
            -e "AGENT_CMD=$TOOL_CMD" \
            -e "HOST_PORT=$HOST_PORT" \
            -e "OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true" \
            -e "IS_SANDBOX=1" \
            -e "COLORTERM=truecolor" \
            -e "CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1" \
            -p "${HOST_PORT}:1337" \
            -v "$HOME/.claude:/root/.claude:Z" \
            -v "$HOME/.config/rtk:/root/.config/rtk:Z" \
            -v "$HOME/.config/opencode:/root/.config/opencode:Z" \
            -v "$HOME/.ssh:/root/.ssh:Z" \
            -v "$PARENT_DIR:/workspace:z" \
            -w "/workspace/$FOLDER_NAME" \
            claude-code "${CLAUDE_FLAGS[@]}"
    fi
    exit
fi

# Handle /bin/bash: only proceed if the container already exists
if [ -n "$HAS_BASH" ]; then
    if ! $DOCKER container inspect "$CONTAINER_NAME" &>/dev/null; then
        echo "Container $CONTAINER_NAME does not exist."
        exit 1
    fi
    $DOCKER start "$CONTAINER_NAME"
    $DOCKER exec -it --detach-keys="$DETACH_KEYS" "$CONTAINER_NAME" /bin/bash
    exit
fi

# Remove old container for this folder if it exists
$DOCKER rm -f "$CONTAINER_NAME" &>/dev/null || true

$DOCKER run -it \
    --detach-keys="$DETACH_KEYS" \
    --name "$CONTAINER_NAME" \
    "${ENV_FLAG[@]}" \
    -e "AGENT_CMD=$TOOL_CMD" \
    -e "HOST_PORT=$HOST_PORT" \
    -e "OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true" \
    -e "IS_SANDBOX=1" \
    -e "COLORTERM=truecolor" \
    -e "CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1" \
    -p "${HOST_PORT}:1337" \
    -v "$HOME/.claude:/root/.claude:Z" \
    -v "$HOME/.config/rtk:/root/.config/rtk:Z" \
    -v "$HOME/.config/opencode:/root/.config/opencode:Z" \
    -v "$HOME/.ssh:/root/.ssh:Z" \
    -v "$PARENT_DIR:/workspace:z" \
    -w "/workspace/$FOLDER_NAME" \
    claude-code "${CLAUDE_FLAGS[@]}"
