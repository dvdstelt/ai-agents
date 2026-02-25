& "$PSScriptRoot\docker-run.ps1" opencode opencode -ExtraVolumes @("-v", "$env:USERPROFILE\.local\share\opencode:/root/.local/share/opencode") --continue
