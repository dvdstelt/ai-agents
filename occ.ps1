& "$PSScriptRoot\docker-run.ps1" opencode -ExtraVolumes @("-v", "$env:USERPROFILE\.local\share\opencode:/root/.local/share/opencode") --continue
