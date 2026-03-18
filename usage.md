# Usage

## Commands

Navigate to any project folder, then:

| Command | What it does |
|---|---|
| `cc` | Start a new Claude Code session |
| `ccc` | Continue the previous Claude Code session |
| `ccd` | Open a bash shell in the running container |
| `oc` | Start a new OpenCode session |
| `occ` | Continue the previous OpenCode session |

All commands are available as `.bat` (CMD) and `.ps1` (PowerShell) scripts. Pass `--risk` to skip permissions (translates to `--dangerously-skip-permissions`).

## How it works

- **Parent directory is mounted.** Running `cc` from `D:\git\dvdstelt\my-project` mounts `D:\git\dvdstelt` as `/workspace`. Sibling folders and worktrees are visible.
- **File changes persist.** Anything written under `/workspace` goes directly to your host disk.
- **Containers are reusable.** `cc` replaces the old container; `ccc` reattaches to it.
- **Auth, settings, and SSH keys persist.** `%USERPROFILE%\.claude`, `.config`, and `.ssh` are mounted into every container.
- **Environment variables** from `.env` in the `ai-agents` folder are loaded automatically.
- **Multiple projects at once.** Each folder gets its own isolated container.
- **Git identity and plugin paths** are configured automatically by the entrypoint.

## Host setup (one-time, new machine)

### Add ai-agents to your PATH

1. Open **Start > Edit environment variables for your account**
2. Add the `ai-agents` folder path to `Path`
3. Restart your terminal

### Link Claude config to the repo

This creates a directory junction so `global-config/` and `%USERPROFILE%\.claude` are the same folder:

```cmd
xcopy /E /I /Y "D:\git\dvdstelt\ai-agents\global-config" "%USERPROFILE%\.claude"
rmdir "D:\git\dvdstelt\ai-agents\global-config" /s /q
mklink /J "D:\git\dvdstelt\ai-agents\global-config" "%USERPROFILE%\.claude"
```

Git tracks only whitelisted files via `global-config/.gitignore`. The junction only works on Windows; git operations for `global-config/` must use a Windows git client.

### Environment variables (optional)

Create a `.env` file in the `ai-agents` folder for API keys and secrets:

```
MY_CUSTOM_VALUE=1337
SQL_CONNECTIONSTRING="server=(local);"
```

### Windows notifications (optional)

Toast notifications when Claude finishes a response:

```powershell
Install-Module BurntToast -Scope CurrentUser
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\claude-notify-install.ps1"
```

See `%USERPROFILE%\.claude\claude-notify-usage.md` for details.

### PowerShell execution policy

If PowerShell blocks `.ps1` scripts:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Worktrees

Worktrees are created as siblings using `git-wtadd` (included in the image):

```bash
cd /workspace/my-project
git-wtadd /workspace/my-project@feature-x feature-x
```

This creates cross-platform worktrees visible on both Linux and Windows:

```
D:\git\dvdstelt\my-project\
D:\git\dvdstelt\my-project@feature-x\
```

**Limitations inside the container:**
- `git worktree remove` does not work; delete manually: `rm -rf /workspace/my-project@feature-x` and `rm -rf /workspace/my-project/.git/worktrees/my-project@feature-x`
- `git gc` is disabled (`gc.auto=0`) to protect worktree metadata

Merge from the **main checkout**, not from the worktree.

## Port mapping

Each container maps a random host port to container port **1337**. To access a dev server from Windows:

1. Start your server on port 1337, bound to all interfaces (`--host` or `0.0.0.0`):

   ```bash
   # npm/vite/astro
   npm run dev -- --host --port 1337

   # static files
   npx serve . -l 1337

   # .NET
   dotnet run --urls http://0.0.0.0:1337
   ```

2. Run `portnumber` inside the container to find the host port:

   ```bash
   $ portnumber
   Container port 1337 is mapped to host port 34521
   Access from Windows: http://localhost:34521
   ```

The `--host` flag is required because dev servers default to `localhost` only, which is not reachable from outside the container. Multiple containers can run simultaneously since each gets a random port.
