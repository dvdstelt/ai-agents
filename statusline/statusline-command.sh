#!/bin/sh
# Claude Code status line script
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Build context usage segment
if [ -n "$used" ] && [ -n "$remaining" ]; then
  ctx_segment="ctx: $(printf '%.0f' "$used")%"
else
  ctx_segment="no messages yet"
fi

# Replace container workdir with HOST_WORKSPACE if set, then shorten home to ~
if [ -n "$HOST_WORKSPACE" ]; then
  # Escape backslashes in HOST_WORKSPACE so sed treats them as literals,
  # not as escape sequences in the replacement string.
  escaped_host_workspace=$(printf '%s' "$HOST_WORKSPACE" | sed 's/\\/\\\\/g')
  container_workdir="${CONTAINER_WORKDIR:-/workspace}"
  cwd=$(printf '%s\n' "$cwd" | sed "s|^$container_workdir|$escaped_host_workspace|")
fi
home="$HOME"
short_cwd=$(printf '%s\n' "$cwd" | sed "s|^$home|~|")

# Get current git branch (empty if not in a repo)
branch=$(git branch --show-current 2>/dev/null)
if [ -n "$branch" ]; then
  branch_segment=" \033[0;35m($branch)\033[0m"
else
  branch_segment=""
fi

printf '\033[0;36m%s\033[0m  \033[0;33m%s\033[0m%b  \033[0;32m%s\033[0m' \
  "$model" "$short_cwd" "$branch_segment" "$ctx_segment"
