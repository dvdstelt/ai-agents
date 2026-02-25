# Claude Code in Docker

## Initial Setup (one-time)

### 1. Build the image

From the `claude-master` folder:

```cmd
cd D:\git\dvdstelt\claude-master
docker build -t claude-code .
```

or for a full rebuild without cache use:

```
docker build --no-cache -t claude-code .
```

### 2. Add claude-master to your PATH

So you can run `cc` and `ccc` from any folder:

1. Open **Start > Edit environment variables for your account**
2. Edit the `Path` variable
3. Add the path to your `claude-master` folder
4. Restart your terminal

### 3. First run and configuration

> [!NOTE]
>
> This doesn't work in PowerShell

Start a temporary container with a bash shell to configure both tools:

```cmd
docker run -it --name ai-setup -v "%USERPROFILE%\.claude:/root/.claude" -v "%USERPROFILE%\.config:/root/.config" -v "D:\temp\claude:/workspace/temp" -w "/workspace/temp" --entrypoint /bin/bash claude-code
```

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
docker commit ai-setup claude-code
docker rm ai-setup
```

This bakes both tools' preferences into the image so you won't be asked again.

### 4. Environment variables (optional)

If your projects need environment variables (API keys, secrets, etc.), create a `.env` file in the `claude-master` folder:

```
BITVAVO_API_KEY=...
BITVAVO_API_SECRET=...
GOOGLE_CLIENT_ID=...
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

## How it works

- **Parent directory is mounted.** Running `cc` from `D:\git\dvdstelt\my-project` mounts `D:\git\dvdstelt` as `/workspace` inside the container. Claude starts in `/workspace/my-project`. This means sibling folders (including worktrees) are also visible.
- **Changes to your files persist.** Anything Claude writes under `/workspace` is written directly to your host disk.
- **Containers persist for `ccc`.** Each folder gets a named container (e.g. `claude-my-project`). Running `cc` replaces the old container; `ccc` reattaches to it.
- **Auth and settings persist.** Your `%USERPROFILE%\.claude` and `%USERPROFILE%\.config` folders are mounted into every container.
- **Environment variables are shared.** The `.env` file in `claude-master` is loaded into every container automatically.
- **Multiple projects at once.** You can run multiple containers simultaneously, each mounted to a different folder. They are fully isolated from each other.
- **Git identity is set automatically.** The entrypoint configures `user.name` and `user.email` on every container start, so you never need to set it manually.
- **Plugin paths are fixed automatically.** Plugins installed on Windows store Windows paths. The entrypoint rewrites these to Linux paths on container start.

## After Rebuilding the Image

When you rebuild with `docker build -t claude-code .`, the image is recreated from the Dockerfile. Any state that was baked in via `docker commit` (login, theme, disclaimer) is lost.

To restore it, follow the [First run and configuration](#3-first-run-and-configuration) steps again for both Claude Code and OpenCode, then commit the container.

**Things you do NOT need to redo after a rebuild:**
- Git identity — set automatically by the entrypoint
- Plugin path fixes — handled automatically by the entrypoint
- Environment variables — loaded from `.env` at runtime
- Auth credentials — stored in `%USERPROFILE%\.claude` on your host

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

## Maintenance

### Add a new tool to the image

1. Edit the `Dockerfile` to add the tool (e.g. add `golang` to an `apt-get install` line)
2. Rebuild: `docker build -t claude-code .`
3. Follow the [After Rebuilding the Image](#after-rebuilding-the-image) steps

### Save changes to the image (docker commit)

Anything installed or configured inside a container is lost when the container is removed — unless you commit it back to the image. This is how we baked in the Claude settings during initial setup, and you can use the same pattern anytime.

The general workflow:

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

**Examples of when to use this:**
- Claude installed a tool (e.g. Ruby gem, pip package) you want to keep
- You changed a system config inside the container
- You want to update Claude Code itself (`npm update -g @anthropic-ai/claude-code` inside the container, then commit)

**When NOT to use this** — if the tool is something you'll always need, add it to the `Dockerfile` instead and rebuild. That way the image is reproducible from scratch.

### Git SSH keys

If you need Git over SSH inside the container, add this volume mount to the `docker run` commands in `cc.bat`/`cc.ps1`:

```
-v "%USERPROFILE%\.ssh:/root/.ssh:ro"
```
