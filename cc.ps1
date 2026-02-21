# Start Claude Code in Docker with the current directory mounted as /workspace.
# Usage:
#   cc              Start a new session
#   cc --continue   Continue the previous session for this folder
#
# Auth: On first run, Claude will prompt you to log in via your claude.ai account.
#       The config is persisted so you only need to do this once.
#
# If a .env file exists in the docker-master folder, it is automatically loaded.

# Create a container name from the folder name
$workDir = (Get-Location).Path
$folderName = Split-Path -Leaf $workDir
$containerName = "claude-$($folderName -replace '@', '-')"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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
if ($args -contains "--continue") {
    $exists = docker container inspect $containerName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Continuing previous session..."
        docker start $containerName
        docker exec -it $containerName claude --continue
    } else {
        Write-Host "No previous session found, starting fresh..."
        docker run -it `
            --name $containerName `
            @envFlag `
            -e "HOST_WORKSPACE=$workDir" `
            -e "CONTAINER_WORKDIR=/workspace/$folderName" `
            -e "HOST_PORT=$hostPort" `
            -p "${hostPort}:1337" `
            -v "$env:USERPROFILE\.claude:/root/.claude" `
            -v "$env:USERPROFILE\.config:/root/.config" `
            -v "${parentDir}:/workspace" `
            -w "/workspace/$folderName" `
            claude-code
    }
    exit
}

# Handle /bin/bash: only proceed if the container already exists
if ($args -contains "/bin/bash") {
    docker container inspect $containerName 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Container $containerName does not exist."
        exit
    }
    docker start $containerName
    docker exec -it $containerName /bin/bash
    exit
}

# Remove old container for this folder if it exists
docker rm -f $containerName 2>$null | Out-Null

docker run -it `
    --name $containerName `
    @envFlag `
    -e "HOST_WORKSPACE=$workDir" `
    -e "CONTAINER_WORKDIR=/workspace/$folderName" `
    -e "HOST_PORT=$hostPort" `
    -p "${hostPort}:1337" `
    -v "$env:USERPROFILE\.claude:/root/.claude" `
    -v "$env:USERPROFILE\.config:/root/.config" `
    -v "${parentDir}:/workspace" `
    -w "/workspace/$folderName" `
    claude-code @args
