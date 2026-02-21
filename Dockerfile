FROM node:lts-slim

# ── Core utilities (Claude's toolbox) ──
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    git \
    jq \
    tree \
    unzip \
    zip \
    tar \
    openssh-client \
    ca-certificates \
    gnupg \
    sudo \
    less \
    vim-tiny \
    build-essential \
    procps \
    findutils \
    diffutils \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Just (task runner, not in Debian repos) ──
RUN curl -fsSL https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# ── Python (scripting, automation, quick tools) ──
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# ── .NET SDK ──
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel LTS --install-dir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet
ENV DOTNET_ROOT=/usr/share/dotnet
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV PATH="$PATH:/root/.dotnet/tools"

# ── .NET global tools ──
RUN dotnet tool install -g dotnet-outdated-tool

# ── Ruby + Jekyll ──
RUN apt-get update && apt-get install -y \
    ruby-full \
    ruby-bundler \
    && rm -rf /var/lib/apt/lists/*

# ── Static site generators (Node-based) ──
RUN npm install -g \
    astro \
    hugo-extended \
    @11ty/eleventy

# ── Helper scripts ──
COPY git-wtadd /usr/local/bin/git-wtadd
COPY portnumber /usr/local/bin/portnumber
COPY fix-plugin-paths.py /usr/local/bin/fix-plugin-paths.py
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/git-wtadd /usr/local/bin/portnumber /usr/local/bin/fix-plugin-paths.py /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/git-wtadd /usr/local/bin/portnumber /usr/local/bin/entrypoint.sh

# ── Claude Code ──
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /workspace
ENTRYPOINT ["entrypoint.sh"]
