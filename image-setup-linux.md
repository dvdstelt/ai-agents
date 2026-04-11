# Image Setup (Linux / Podman)

How to build, configure, and rebuild the `claude-code` container image.

## Building the image

```bash
cd ~/src/dvdstelt/ai-agents
podman build -t claude-code .
```

For a full rebuild without cache: `podman build --no-cache -t claude-code .`

## Host `~/.claude` symlink

On the host, `~/.claude` is a symlink into this repo:

```bash
~/.claude -> /path/to/ai-agents/global-config
```

This keeps Claude Code's global config (`settings.json`, `CLAUDE.md`, `statusline-command.sh`, `commands/*.md`) under version control. Changes made through Claude Code on the host, such as installing a plugin, land directly in the repo working tree.

A fresh clone needs this symlink set up once:

```bash
cd /path/to/ai-agents

# If ~/.claude already exists as a real directory, back it up first
[ -e "$HOME/.claude" ] && [ ! -L "$HOME/.claude" ] && mv "$HOME/.claude" "$HOME/.claude.backup"

ln -s "$(pwd)/global-config" "$HOME/.claude"
```

Podman follows the symlink transparently when bind-mounting `~/.claude`, so the setup commands below work unchanged. A whitelist `.gitignore` inside `global-config/` keeps plugins, caches, backups, and credentials out of git.

## Configuring the image (first time or after rebuild)

After building (or rebuilding) the image, Claude Code's one-time prompts (theme, login, disclaimer) need to be baked in. This only takes a minute.

**1. Start a setup container:**

```bash
mkdir -p /tmp/claude-setup "$HOME/.config/rtk" "$HOME/.config/opencode"
podman run -it --name ai-setup -v "$HOME/.claude:/root/.claude:z" -v "$HOME/.config/rtk:/root/.config/rtk:z" -v "$HOME/.config/opencode:/root/.config/opencode:z" -v "/tmp/claude-setup:/workspace/temp:z" -e OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true -w "/workspace/temp" --entrypoint /bin/bash claude-code
```

If the container doesn't attach after `podman run`, or already exists from a previous attempt: `podman start -ai ai-setup`

**2. Start Claude Code:**

```bash
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

After RTK init, update the paths in `~/.claude/settings.json` to use `$HOME` instead of `/root` so they work both natively and inside containers:

```bash
sed -i 's|/root/.claude/|$HOME/.claude/|g' /root/.claude/settings.json
```

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

```bash
podman commit --change 'ENTRYPOINT ["entrypoint.sh"]' ai-setup claude-code
podman rm ai-setup
```

> [!IMPORTANT]
>
> The `--change "ENTRYPOINT ..."` flag is required. The setup container was started with `--entrypoint /bin/bash`, so without it `podman commit` would bake `/bin/bash` as the entrypoint and `c` would open a shell instead of Claude.

Done. Every new container will now start without login prompts.

## What survives a rebuild automatically

You do NOT need to reconfigure these after rebuilding:

- **Auth credentials** stored in `~/.claude` on your host (mounted at runtime)
- **RTK hooks** written to `~/.claude` by `rtk init --global`
- **Git identity** set automatically by the entrypoint
- **Environment variables** loaded from `.env` at runtime

## Adding a tool to the image

For tools you'll always need, add them to the `Dockerfile` and rebuild. This keeps the image reproducible.

For one-off tools, install them in a running container and commit:

```bash
podman run -it --name my-temp claude-code
# install whatever you need, then exit
podman commit my-temp claude-code
podman rm my-temp
```
