# Claude Code in Docker

## Build the image

Run this once from the `docker-master` folder:

```bash
docker build -t claude-code .
```

Rebuild anytime you change the Dockerfile to pick up new tools.

## Set your API key

Set the `ANTHROPIC_API_KEY` environment variable so the container can authenticate.

**Powershell (current session):**

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."
```

**Powershell (permanent, user-level):**

```powershell
[Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", "sk-ant-...", "User")
```

**CMD (permanent):**

```cmd
setx ANTHROPIC_API_KEY "sk-ant-..."
```

After using `setx` or the permanent Powershell method, restart your terminal.

## Start Claude Code

Navigate to the project folder you want Claude to work on, then run:

**Using the .bat file:**

```cmd
D:\work\docker-master\claude-code.bat
```

**Directly with docker (from any shell):**

```bash
docker run -it --rm -e ANTHROPIC_API_KEY=%ANTHROPIC_API_KEY% -v "%cd%:/workspace" claude-code
```

**From Powershell:**

```powershell
docker run -it --rm -e ANTHROPIC_API_KEY=$env:ANTHROPIC_API_KEY -v "${PWD}:/workspace" claude-code
```

## Add the .bat to your PATH

To run `claude-code` from anywhere without typing the full path:

1. Open **Start > Edit environment variables for your account**
2. Edit the `Path` variable
3. Add `D:\work\docker-master`
4. Restart your terminal

Now you can just type `claude-code` from any project folder.

## Tips

- **Files are shared, tools are not.** Only the mounted folder is visible to the container. All runtimes (.NET, Ruby, Node, Python) live inside the container.
- **Changes to your files persist.** Anything Claude writes to `/workspace` is written directly to your host folder.
- **Installed packages are lost on exit.** The `--rm` flag deletes the container when you exit. If Claude installs something useful (e.g. a new gem or pip package), add it to the Dockerfile and rebuild.
- **Save a modified container.** If you want to keep what Claude installed without editing the Dockerfile, skip `--rm` and commit afterward:
  ```bash
  docker run -it -e ANTHROPIC_API_KEY=%ANTHROPIC_API_KEY% -v "%cd%:/workspace" --name claude-session claude-code
  # after exiting:
  docker commit claude-session claude-code
  docker rm claude-session
  ```
- **Multiple projects at once.** You can run multiple containers simultaneously, each mounted to a different folder. They are fully isolated from each other.
- **Git SSH keys.** If you need Git over SSH inside the container, mount your SSH directory:
  ```bash
  docker run -it --rm -v "%USERPROFILE%\.ssh:/root/.ssh:ro" -v "%cd%:/workspace" claude-code
  ```
- **Persist Claude config.** To keep Claude's settings and auth across sessions:
  ```bash
  docker run -it --rm -v "%USERPROFILE%\.claude:/root/.claude" -v "%cd%:/workspace" claude-code
  ```
