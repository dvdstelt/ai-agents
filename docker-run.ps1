# Central Docker launcher for containerized dev tools.
# Usage: docker-run.ps1 <prefix> <tool-cmd> [args...]
#   prefix    Container name prefix (e.g. claude, opencode)
#   tool-cmd  Command to run inside the container (e.g. claude, opencode)
#   args      Forwarded to the tool command (e.g. --continue, /bin/bash)

param(
    [Parameter(Mandatory)][string]$Prefix,
    [Parameter(Mandatory)][string]$ToolCmd,
    [Parameter(ValueFromRemainingArguments)][string[]]$ExtraArgs
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create a container name from the folder name
$workDir = (Get-Location).Path
$folderName = Split-Path -Leaf $workDir
$containerName = "$Prefix-$($folderName -replace '@', '-')"

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
        docker exec -it $containerName $ToolCmd --continue
    } else {
        Write-Host "No previous session found, starting fresh..."
        docker run -it `
            --name $containerName `
            @envFlag `
            -e "AGENT_CMD=$ToolCmd" `
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
if ($ExtraArgs -contains "/bin/bash") {
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
    -e "AGENT_CMD=$ToolCmd" `
    -e "HOST_WORKSPACE=$workDir" `
    -e "CONTAINER_WORKDIR=/workspace/$folderName" `
    -e "HOST_PORT=$hostPort" `
    -p "${hostPort}:1337" `
    -v "$env:USERPROFILE\.claude:/root/.claude" `
    -v "$env:USERPROFILE\.config:/root/.config" `
    -v "${parentDir}:/workspace" `
    -w "/workspace/$folderName" `
    claude-code @ExtraArgs
