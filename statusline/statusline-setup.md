# Claude Code Statusline Setup

Displays three pieces of info in the Claude Code status bar:
1. **Model & version** (e.g. `Claude Sonnet 4.6`)
2. **Working folder** — uses `HOST_WORKSPACE` env var if set (supports backslashes for Windows paths), otherwise falls back to the local path
3. **Context used** (e.g. `ctx: 12%`)

---

## Files

- `statusline-command.sh` — the script that produces the status line output
- `statusline-settings-snippet.json` — the settings fragment to add to `~/.claude/settings.json`

---

## Setup Steps

### 1. Copy the script to your Claude config folder

```sh
cp /workspace/statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

### 2. Add the statusLine config to `~/.claude/settings.json`

Open `~/.claude/settings.json` (create it if it doesn't exist) and add the `statusLine` block:

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh /root/.claude/statusline-command.sh"
  }
}
```

If the file already has other settings, merge the `statusLine` key in — don't replace the whole file.

### 3. (Optional) Set HOST_WORKSPACE for Windows path display

If you're running Claude Code inside WSL and want the status bar to show the real Windows path instead of `/workspace`, set this in your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```sh
export HOST_WORKSPACE='C:\Users\YourName\your-project'
```

The backslash will be preserved in the display.

---

## Notes

- The script requires `jq` to be installed (`apt install jq`)
- If `HOST_WORKSPACE` is not set, the current local directory is shown, with `$HOME` shortened to `~`
- Context percentage reflects tokens used — no "available" count is shown by design
