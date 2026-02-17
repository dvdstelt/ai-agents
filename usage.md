# Claude Code in Docker

## Initial Setup (one-time)

### 1. Build the image

From the `docker-master` folder:

```cmd
cd D:\work\docker-master
docker build -t claude-code .
```

### 2. Add docker-master to your PATH

So you can run `cc` and `ccc` from any folder:

1. Open **Start > Edit environment variables for your account**
2. Edit the `Path` variable
3. Add `D:\work\docker-master`
4. Restart your terminal

### 3. First run and configuration

Start a temporary container to configure Claude (theme, login, disclaimer):

```cmd
docker run -it --name claude-setup -v "%USERPROFILE%\.claude:/root/.claude" claude-code
```

Inside the container:
1. Select **Dark mode** (or your preference)
2. Choose **Claude account with subscription** as login method
3. Open the URL in your browser to authenticate
4. Press Enter after login succeeds
5. Accept the disclaimer
6. Trust the folder

Then exit Claude (`Ctrl+C` or `/exit`) and commit the configured state:

```cmd
docker commit claude-setup claude-code
docker rm claude-setup
```

This bakes your preferences into the image so you won't be asked again.

### 4. Environment variables (optional)

If your projects need environment variables (API keys, secrets, etc.), create a `.env` file in the `docker-master` folder:

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
| `cc` | Start a new Claude session for the current folder |
| `ccc` | Continue the previous session for the current folder |

Both commands are available as `.bat` (CMD) and `.ps1` (PowerShell) scripts.

### PowerShell execution policy

If PowerShell blocks `.ps1` scripts, run this once:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## How it works

- **Files are shared, tools are not.** Only the mounted folder is visible to the container. All runtimes (.NET, Ruby, Node, Python) live inside the container.
- **Changes to your files persist.** Anything Claude writes to `/workspace` is written directly to your host folder.
- **Containers persist for `ccc`.** Each folder gets a named container (e.g. `claude-my-project`). Running `cc` replaces the old container; `ccc` reattaches to it.
- **Auth and settings persist.** Your `%USERPROFILE%\.claude` and `%USERPROFILE%\.config` folders are mounted into every container.
- **Environment variables are shared.** The `.env` file in `docker-master` is loaded into every container automatically.
- **Multiple projects at once.** You can run multiple containers simultaneously, each mounted to a different folder. They are fully isolated from each other.

## Maintenance

### Add a new tool to the image

1. Edit the `Dockerfile` to add the tool (e.g. add `golang` to an `apt-get install` line)
2. Rebuild: `docker build -t claude-code .`

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
