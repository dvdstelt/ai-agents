#!/bin/bash
# Open a bash shell in the running Claude Code container.
exec "$(dirname "$0")/docker-run.sh" claude /bin/bash
