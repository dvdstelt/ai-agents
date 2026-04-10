# Image Setup

How to build, configure, and rebuild the `claude-code` Docker image.

## Building the image

```cmd
cd D:\git\dvdstelt\ai-agents
docker build -t claude-code .
```

For a full rebuild without cache: `docker build --no-cache -t claude-code .`

## Configuring the image (first time or after rebuild)

After building (or rebuilding) the image, Claude Code's one-time prompts (theme, login, disclaimer) need to be baked in. This only takes a minute.

> [!NOTE]
>
> These commands must be run in CMD, not PowerShell.

**1. Start a setup container:**

```cmd
docker run -it --name ai-setup -v "%USERPROFILE%\.claude:/root/.claude" -v "%USERPROFILE%\.config:/root/.config" -v "D:\temp\claude:/workspace/temp" -e OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true -w "/workspace/temp" --entrypoint /bin/bash claude-code
```

If the container already exists from a previous attempt: `docker start -ai ai-setup`

**2. Restore Claude config and start Claude Code:**

```bash
cp "$(ls -t /root/.claude/backups/.claude.json.backup.* | head -1)" /root/.claude.json 2>/dev/null
claude
```

1. Select **Dark mode** (or your preference)
2. Choose **Claude account with subscription** as login method
3. Open the URL in your browser to authenticate
4. Press Enter after login succeeds
5. Accept the disclaimer
6. Trust the folder

Exit with `Ctrl+C` or `/exit`.

**3. Activate RTK:**

```bash
rtk init --global
```

This writes hook configuration to `~/.claude/`, which is mounted from your host. You only need to run this once; it survives image rebuilds.

**4. Configure OpenCode** (optional):

```bash
opencode
```

1. Run `/connect`, select your provider, sign in
2. Exit with `Ctrl+C` or `/exit`

> [!NOTE]
>
> Using a Claude Code subscription as a provider is against Anthropic's ToS. For OpenAI (ChatGPT), select the **headless** login option, not the browser-based one — browser auth doesn't work inside a container.

**5. Save and clean up:**

Exit the bash shell (`exit`), then:

```cmd
docker commit --change "ENTRYPOINT [\"entrypoint.sh\"]" ai-setup claude-code
docker rm ai-setup
```

> [!IMPORTANT]
>
> The `--change "ENTRYPOINT ..."` flag is required. The setup container was started with `--entrypoint /bin/bash`, so without it `docker commit` would bake `/bin/bash` as the entrypoint and `cc` would open a shell instead of Claude.

Done. Every new container will now start without login prompts.

## What survives a rebuild automatically

You do NOT need to reconfigure these after rebuilding:

- **Auth credentials** stored in `%USERPROFILE%\.claude` on your host (mounted at runtime)
- **RTK hooks** written to `%USERPROFILE%\.claude` by `rtk init --global`
- **Git identity** set automatically by the entrypoint
- **Plugin paths** rewritten from Windows to Linux by the entrypoint
- **Environment variables** loaded from `.env` at runtime

## Adding a tool to the image

For tools you'll always need, add them to the `Dockerfile` and rebuild. This keeps the image reproducible.

For one-off tools, install them in a running container and commit:

```cmd
docker run -it --name my-temp claude-code
REM install whatever you need, then exit
docker commit my-temp claude-code
docker rm my-temp
```
