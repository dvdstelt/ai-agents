#!/usr/bin/env python3
"""Rewrite Windows paths in Claude plugin config files to Linux paths.

The .claude directory is shared between the Windows host and the Docker
container.  Plugin JSON files store absolute paths — Windows-style on the
host, but the container needs Linux-style /root/.claude/… paths.

Runs on every container start (via entrypoint.sh) and is idempotent:
paths that are already Linux-style are left untouched.
"""

import json
import os
import re
import sys


def fix_paths(filepath):
    if not os.path.exists(filepath):
        return

    with open(filepath) as f:
        content = f.read()

    original = content

    # Match Windows .claude paths (JSON-escaped backslashes: \\)
    # e.g. C:\\Users\\dvdst\\.claude\\plugins\\cache\\...
    # Capture everything after .claude\\ up to the closing quote.
    def replace_path(m):
        rest = m.group(1).replace("\\\\", "/")
        return "/root/.claude/" + rest

    content = re.sub(
        r'C:\\\\Users\\\\[^"\\]+\\\\.claude\\\\([^"]*)',
        replace_path,
        content,
    )

    if content != original:
        with open(filepath, "w") as f:
            f.write(content)
        print(f"fix-plugin-paths: updated {filepath}")


fix_paths("/root/.claude/plugins/installed_plugins.json")
fix_paths("/root/.claude/plugins/known_marketplaces.json")
