@echo off
set "EXTRA_VOLUMES=-v "%USERPROFILE%\.local\share\opencode:/root/.local/share/opencode""
call "%~dp0docker-run.bat" opencode opencode --continue
