#!/bin/sh
# Claude Code status line script
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // .model // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Build context usage segment
if [ -n "$used" ]; then
  ctx_segment="ctx: $(printf '%.0f' "$used")%"
else
  ctx_segment="no messages yet"
fi

# Save original cwd for git branch detection (before any path replacement)
original_cwd="$cwd"

# Detect git branch from the original container path
git_branch=$(git -C "$original_cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Replace container workdir with HOST_WORKSPACE if set, then shorten home to ~
if [ -n "$HOST_WORKSPACE" ]; then
  escaped_host_workspace=$(printf '%s' "$HOST_WORKSPACE" | sed 's/\\/\\\\/g')
  container_workdir="${CONTAINER_WORKDIR:-/workspace}"
  cwd=$(printf '%s\n' "$cwd" | sed "s|^$container_workdir|$escaped_host_workspace|")
fi
home="$HOME"
short_cwd=$(printf '%s\n' "$cwd" | sed "s|^$home|~|")

# Append branch name to path if one was found
if [ -n "$git_branch" ]; then
  short_cwd="$short_cwd:$git_branch"
fi

printf '\033[0;36m%s\033[0m  \033[0;33m%s\033[0m  \033[0;32m%s\033[0m' \
  "$model" "$short_cwd" "$ctx_segment"
