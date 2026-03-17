# Claude Code in Docker

## Initial Setup (one-time)

### 1. Build the image

From the `ai-agents` folder:

```cmd
cd D:\git\dvdstelt\ai-agents
docker build -t claude-code .
```

### 2. Link Claude config to the repo (one-time)

The `global-config/` folder in this repo tracks your Claude Code configuration files (`CLAUDE.md`, `settings.json`, commands, etc.) under version control. On Windows, this is done using a directory junction so that `%USERPROFILE%\.claude` and `global-config/` are the same folder; edits in one are immediately reflected in the other.

**On a fresh machine (first time):**

Copy the committed config files into your Claude config folder first:

```cmd
xcopy /E /I /Y "D:\git\dvdstelt\ai-agents\global-config" "%USERPROFILE%\.claude"
```

Then replace the real `global-config` folder with a junction pointing back to `%USERPROFILE%\.claude`:

```cmd
rmdir "D:\git\dvdstelt\ai-agents\global-config" /s /q
mklink /J "D:\git\dvdstelt\ai-agents\global-config" "%USERPROFILE%\.claude"
```

After this, `global-config/` is a live view of your Claude config. Git tracks only the whitelisted files (defined in `global-config/.gitignore`), so volatile files like `history.jsonl`, `.credentials.json`, and `projects/` are never committed.

> [!NOTE]
>
> The junction only works on Windows. Inside the Docker container, Linux cannot follow it; git operations for `global-config/` must be done from a Windows git client (e.g. VS Code, GitKraken, or a Windows terminal).

### 3. Add ai-agents to your PATH

So you can run `cc` and `ccc` from any folder:

1. Open **Start > Edit environment variables for your account**
2. Edit the `Path` variable
3. Add the path to your `ai-agents` folder
4. Restart your terminal

### 4. First run and configuration

> [!NOTE]
>
> This doesn't work in PowerShell

Start a temporary container with a bash shell to configure both tools:

```cmd
docker run -it --name ai-setup -v "%USERPROFILE%\.claude:/root/.claude" -v "%USERPROFILE%\.config:/root/.config" -v "D:\temp\claude:/workspace/temp" -e OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true -w "/workspace/temp" --entrypoint /bin/bash claude-code
```

> [!TIP]
>
> The `-e OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true` flag is needed because the OpenCode TUI tries to copy text to the clipboard whenever you select it. In a Windows Terminal to Docker to bash chain, this breaks the terminal and prevents you from pasting the authentication URL or API key. The env var disables that behavior so copy-paste works normally during setup.

If the container already exists:

```
docker start -ai ai-setup
```

#### Configure Claude Code

From the bash shell, start Claude:

```bash
claude
```

Inside Claude:

1. Select **Dark mode** (or your preference)
2. Choose **Claude account with subscription** as login method
3. Open the URL in your browser to authenticate
4. Press Enter after login succeeds
5. Accept the disclaimer
6. Trust the folder

Then exit Claude (`Ctrl+C` or `/exit`).

#### Configure OpenCode

Still in the bash shell, start OpenCode:

```bash
opencode
```

Inside the OpenCode TUI:

1. Run the `/connect` command
2. Select your provider (e.g. **Anthropic** to use your Claude subscription)
3. Follow the prompts to sign in and paste your API key

Then exit OpenCode (`Ctrl+C` or `/exit`).

#### Save the configured state

Exit the bash shell (`exit`), then commit the container:

```cmd
docker commit --change "ENTRYPOINT [\"entrypoint.sh\"]" ai-setup claude-code
docker rm ai-setup
```

> [!IMPORTANT]
>
> The `--change "ENTRYPOINT ..."` flag is required because the setup container was started with `--entrypoint /bin/bash`. Without it, `docker commit` bakes `/bin/bash` as the entrypoint into the image, and `cc` would drop you into a bash shell instead of starting Claude.

This bakes both tools' preferences into the image so you won't be asked again.

### 5. Windows notifications (optional)

Get a toast notification whenever Claude finishes a response, showing the project folder and branch (e.g. `ai-agents:main`).

**Prerequisites:** install the [BurntToast](https://github.com/Windos/BurntToast) PowerShell module:

```powershell
Install-Module BurntToast -Scope CurrentUser
```

**Setup:** run once from an elevated PowerShell window:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\claude-notify-install.ps1"
```

This registers a logon task that runs the notification listener silently in the background. See `%USERPROFILE%\.claude\claude-notify-usage.md` for troubleshooting and management commands.

### 6. Environment variables (optional)

If your projects need environment variables (API keys, secrets, etc.), create a `.env` file in the `ai-agents` folder:

```
MY_CUSTOM_VALUE=1337
SQL_CONNECTIONSTRING="server=(local);"
AZURE_SERVICE_BUS_CONNECTIONSTRING=""
```

This file is automatically loaded into every container.

## Usage

Navigate to any project folder, then:

| Command | What it does |
|---|---|
| `cc` | Start a new Claude Code session for the current folder |
| `ccc` | Continue the previous Claude Code session for the current folder |
| `ccd` | Open a bash shell in the running Claude Code container |
| `oc` | Start a new OpenCode session for the current folder |
| `occ` | Continue the previous OpenCode session for the current folder |

All commands are available as `.bat` (CMD) and `.ps1` (PowerShell) scripts.

### PowerShell execution policy

If PowerShell blocks `.ps1` scripts, run this once:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## How It Works

- **Parent directory is mounted.** Running `cc` from `D:\git\dvdstelt\my-project` mounts `D:\git\dvdstelt` as `/workspace` inside the container. Claude starts in `/workspace/my-project`. This means sibling folders (including worktrees) are also visible.
- **Changes to your files persist.** Anything Claude writes under `/workspace` is written directly to your host disk.
- **Containers persist for `ccc`.** Each folder gets a named container (e.g. `claude-my-project`). Running `cc` replaces the old container; `ccc` reattaches to it.
- **Auth and settings persist.** Your `%USERPROFILE%\.claude` and `%USERPROFILE%\.config` folders are mounted into every container.
- **SSH keys are available.** Your `%USERPROFILE%\.ssh` folder is mounted, so Git over SSH and remote access work inside the container.
- **Environment variables are shared.** The `.env` file in `ai-agents` is loaded into every container automatically.
- **Multiple projects at once.** You can run multiple containers simultaneously, each mounted to a different folder. They are fully isolated from each other.
- **Git identity is set automatically.** The entrypoint configures `user.name` and `user.email` on every container start, so you never need to set it manually.
- **Plugin paths are fixed automatically.** Plugins installed on Windows store Windows paths. The entrypoint rewrites these to Linux paths on container start.

## Managing the Image

There are two ways to update what's in the image: **rebuilding** from the Dockerfile, or **committing** changes from a running container. Use whichever fits the situation.

### Rebuilding the image

Rebuild when the Dockerfile itself changes (new base image, new system packages, updated tool versions). This creates a clean image from scratch.

```cmd
cd D:\git\dvdstelt\ai-agents
docker build -t claude-code .
```

For a full rebuild without cache:

```cmd
docker build --no-cache -t claude-code .
```

After rebuilding, any state that was previously baked in via `docker commit` (login prompts, theme preferences, disclaimer acceptance) is lost. To restore it, follow the [First run and configuration](#4-first-run-and-configuration) steps again, then [save the configured state](#save-the-configured-state).

**Things you do NOT need to redo after a rebuild:**
- Git identity, set automatically by the entrypoint
- Plugin path fixes, handled automatically by the entrypoint
- Environment variables, loaded from `.env` at runtime
- Auth credentials, stored in `%USERPROFILE%\.claude` on your host

### Adding a new tool to the image

If the tool is something you'll always need, add it to the Dockerfile so the image is reproducible from scratch:

1. Edit the `Dockerfile` to add the tool (e.g. add `golang` to an `apt-get install` line)
2. Rebuild: `docker build -t claude-code .`
3. Follow the [rebuild steps above](#rebuilding-the-image) to reconfigure

### Saving ad-hoc changes with docker commit

Anything installed or configured inside a container is lost when the container is removed, unless you commit it back to the image. Use this for quick, one-off changes that don't belong in the Dockerfile.

```cmd
REM 1. Start a named container (without --rm so it sticks around)
docker run -it --name my-temp-container claude-code

REM 2. Do whatever you need inside (install tools, change config, etc.)
REM    Then exit the container.

REM 3. Save the container's state back into the image
docker commit my-temp-container claude-code

REM 4. Clean up the temporary container
docker rm my-temp-container
```

After committing, every new container started from `claude-code` will have those changes.

**Examples:**
- Claude installed a tool (e.g. Ruby gem, pip package) you want to keep
- You changed a system config inside the container
- You want to update Claude Code itself (`npm update -g @anthropic-ai/claude-code` inside the container, then commit)

## Worktrees

Git worktrees are created as siblings of the project inside `/workspace`:

```
/workspace/my-project/             # main checkout
/workspace/my-project@feature-x/   # worktree for feature-x branch
```

Because the parent directory is mounted, worktrees are visible on your Windows disk:

```
D:\git\dvdstelt\my-project\
D:\git\dvdstelt\my-project@feature-x\
```

Always use `git-wtadd` (included in the image) instead of `git worktree add`:

```bash
cd /workspace/my-project
git-wtadd /workspace/my-project@feature-x feature-x
```

`git-wtadd` does two things to make worktrees work cross-platform:

1. **Relative `.git` file** - the `.git` file in the worktree root uses a relative path, so basic git operations (`status`, `commit`, `log`, `push`, etc.) work on both Linux and Windows.
2. **Windows host path in `gitdir`** - the `gitdir` file inside `.git/worktrees/<name>/` is rewritten to the Windows host path. This makes `git worktree list`, GitKraken, and other Windows tools recognize the worktree natively.

### Container-side limitations

Because the `gitdir` file contains a Windows path, some worktree management commands don't work **inside the container**:

- `git worktree list` - shows Windows paths (cosmetic, harmless)
- `git worktree remove` - fails because it can't resolve the Windows path; use manual cleanup instead:
  ```bash
  rm -rf /workspace/my-project@feature-x
  rm -rf /workspace/my-project/.git/worktrees/my-project@feature-x
  git branch -D feature-x   # if you also want to delete the branch
  ```
- `git gc` - automatic gc is disabled inside the container (`gc.auto=0`) to prevent it from incorrectly pruning worktree metadata

Regular git operations inside the worktree (`status`, `commit`, `build`, `test`, etc.) work normally.

### Merging a worktree branch

Merge from the **main checkout**, not from the worktree. Git doesn't allow the same branch to be checked out in two places:

```bash
# From the main checkout (on main)
git merge feature-x
```

## Port Mapping

Each container maps a random host port (20000-52767) to container port **1337**. This lets you run a web server inside the container and access it from Windows.

Inside the container, always bind your server to port 1337:

```bash
# Example: start a dev server on port 1337
dotnet run --urls http://0.0.0.0:1337
```

To find the host port, run `portnumber` inside the container:

```bash
$ portnumber
Container port 1337 is mapped to host port 34521
Access from Windows: http://localhost:34521
```

Because each container gets a random port, multiple containers can run simultaneously without port conflicts.

## Troubleshooting

### Ctrl+P doesn't work inside the container

Docker reserves `Ctrl+P Ctrl+Q` as the default detach sequence for interactive sessions. This can cause apps inside the container (e.g. OpenCode) to require pressing `Ctrl+P` twice.

This repo sets Docker's detach keys per-run in `docker-run.bat` and `docker-run.ps1` to `ctrl-],ctrl-q`, so this should not normally be an issue. If you're seeing the problem, make sure you're using the launcher scripts (`cc`, `oc`, etc.) rather than running `docker run` directly.
