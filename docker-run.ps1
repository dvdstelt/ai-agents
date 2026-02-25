# Central Docker launcher for containerized dev tools.
# Usage: docker-run.ps1 <tool-cmd> [-ExtraVolumes <string[]>] [args...]
#   ToolCmd       Command to run inside the container (e.g. claude, opencode)
#   ExtraVolumes  Additional volume mount args specific to the tool (optional)
#   ExtraArgs     Forwarded to the tool command (e.g. --continue, /bin/bash)

param(
    [Parameter(Mandatory)][string]$ToolCmd,
    [string[]]$ExtraVolumes = @(),
    [Parameter(ValueFromRemainingArguments)][string[]]$ExtraArgs
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Avoid Docker's default detach sequence (Ctrl+P Ctrl+Q) stealing Ctrl+P.
# This makes Ctrl+P usable inside TUIs (OpenCode/Claude Code) when running via docker run/exec.
$detachKeys = "ctrl-],ctrl-q"

# Create a container name from the folder name
$workDir = (Get-Location).Path
$folderName = Split-Path -Leaf $workDir
$containerName = "ai-$($folderName -replace '@', '-')"

# Get the parent directory (mounted as /workspace so worktrees are visible on disk)
$parentDir = Split-Path -Parent $workDir

# Pick a random host port (20000-52767) for container port 1337
$hostPort = Get-Random -Minimum 20000 -Maximum 52768

# Check for .env file in docker-master folder
$envFlag = @()
if (Test-Path "$scriptDir\.env") {
    $envFlag = @("--env-file", "$scriptDir\.env")
    Write-Host "Loading .env file from $scriptDir"
}

Write-Host "Mounting: $parentDir (project: $folderName)"
Write-Host "Container: $containerName"
Write-Host ""

# Handle --continue: reattach to existing container, or start fresh if none exists
if ($ExtraArgs -contains "--continue") {
    $exists = docker container inspect $containerName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Continuing previous session..."
        docker start $containerName
        docker exec -it --detach-keys $detachKeys $containerName $ToolCmd --continue
    } else {
        Write-Host "No previous session found, starting fresh..."
        docker run -it `
            --detach-keys $detachKeys `
            --name $containerName `
            @envFlag `
            -e "AGENT_CMD=$ToolCmd" `
            -e "HOST_WORKSPACE=$workDir" `
            -e "CONTAINER_WORKDIR=/workspace/$folderName" `
            -e "HOST_PORT=$hostPort" `
            -p "${hostPort}:1337" `
            -v "$env:USERPROFILE\.claude:/root/.claude" `
            -v "$env:USERPROFILE\.config:/root/.config" `
            @ExtraVolumes `
            -v "${parentDir}:/workspace" `
            -w "/workspace/$folderName" `
            claude-code
    }
    exit
}

# Handle /bin/bash: only proceed if the container already exists
if ($ExtraArgs -contains "/bin/bash") {
    docker container inspect $containerName 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Container $containerName does not exist."
        exit
    }
    docker start $containerName
    docker exec -it --detach-keys $detachKeys $containerName /bin/bash
    exit
}

# Remove old container for this folder if it exists
docker rm -f $containerName 2>$null | Out-Null

docker run -it `
    --detach-keys $detachKeys `
    --name $containerName `
    @envFlag `
    -e "AGENT_CMD=$ToolCmd" `
    -e "HOST_WORKSPACE=$workDir" `
    -e "CONTAINER_WORKDIR=/workspace/$folderName" `
    -e "HOST_PORT=$hostPort" `
    -p "${hostPort}:1337" `
    -v "$env:USERPROFILE\.claude:/root/.claude" `
    -v "$env:USERPROFILE\.config:/root/.config" `
    @ExtraVolumes `
    -v "${parentDir}:/workspace" `
    -w "/workspace/$folderName" `
    claude-code @ExtraArgs
