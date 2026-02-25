@echo off
REM Central Docker launcher for containerized dev tools.
REM Usage: docker-run.bat <prefix> <tool-cmd> [args...]
REM   prefix    Container name prefix (e.g. claude, opencode)
REM   tool-cmd  Command to run inside the container (e.g. claude, opencode)
REM   args      Forwarded to the tool command (e.g. --continue, /bin/bash)
REM
REM Callers may set EXTRA_VOLUMES before calling this script to inject
REM additional -v mount flags, e.g.:
REM   set "EXTRA_VOLUMES=-v "%USERPROFILE%\.claude:/root/.claude""

set "PREFIX=%~1"
set "TOOL_CMD=%~2"
shift & shift

REM Avoid Docker's default detach sequence (Ctrl+P Ctrl+Q) stealing Ctrl+P.
set "DETACH_KEYS=ctrl-],ctrl-q"

REM Collect remaining args
set "EXTRA_ARGS="
:argloop
if "%~1"=="" goto argsdone
set "EXTRA_ARGS=%EXTRA_ARGS% %1"
shift
goto argloop
:argsdone

REM Create a container name from the folder name (replace @)
for %%I in ("%cd%") do set "FOLDER_NAME=%%~nxI"
set "CONTAINER_NAME=%PREFIX%-%FOLDER_NAME%"
set "CONTAINER_NAME=%CONTAINER_NAME:@=-%"

REM Get the parent directory (mounted as /workspace so worktrees are visible on disk)
for %%I in ("%cd%\..") do set "PARENT_DIR=%%~fI"

REM Pick a random host port (20000-52767) for container port 1337
set /a "HOST_PORT=(%random% %% 10000) + 20000"

REM Check for .env file in docker-master folder
set "ENV_FLAG="
if exist "%~dp0.env" (
    set "ENV_FLAG=--env-file %~dp0.env"
    echo Loading .env file from %~dp0
)

echo Mounting: %PARENT_DIR% (project: %FOLDER_NAME%)
echo Container: %CONTAINER_NAME%
echo.

REM Handle --continue: reattach to existing container, or start fresh if none exists
if "%EXTRA_ARGS%"==" --continue" (
    docker container inspect %CONTAINER_NAME% >nul 2>&1
    if not errorlevel 1 (
        echo Continuing previous session...
        docker start %CONTAINER_NAME%
        docker exec -it --detach-keys="%DETACH_KEYS%" %CONTAINER_NAME% %TOOL_CMD% --continue
    ) else (
        echo No previous session found, starting fresh...
        docker run -it ^
            --detach-keys="%DETACH_KEYS%" ^
            --name %CONTAINER_NAME% ^
            %ENV_FLAG% ^
            -e AGENT_CMD=%TOOL_CMD% ^
            -e HOST_WORKSPACE=%cd% ^
            -e CONTAINER_WORKDIR=/workspace/%FOLDER_NAME% ^
            -e HOST_PORT=%HOST_PORT% ^
            -e OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true ^
            -p %HOST_PORT%:1337 ^
            -v "%USERPROFILE%\.claude:/root/.claude" ^
            -v "%USERPROFILE%\.config:/root/.config" ^
            %EXTRA_VOLUMES% ^
            -v "%PARENT_DIR%:/workspace" ^
            -w "/workspace/%FOLDER_NAME%" ^
            claude-code
    )
    goto :eof
)

REM Handle /bin/bash: only proceed if the container already exists
if "%EXTRA_ARGS%"==" /bin/bash" (
    docker container inspect %CONTAINER_NAME% >nul 2>&1
    if errorlevel 1 (
        echo Container %CONTAINER_NAME% does not exist.
        goto :eof
    )
    docker start %CONTAINER_NAME%
    docker exec -it --detach-keys="%DETACH_KEYS%" %CONTAINER_NAME% /bin/bash
    goto :eof
)

REM Remove old container for this folder if it exists
docker rm -f %CONTAINER_NAME% >nul 2>&1

docker run -it ^
    --detach-keys="%DETACH_KEYS%" ^
    --name %CONTAINER_NAME% ^
    %ENV_FLAG% ^
    -e AGENT_CMD=%TOOL_CMD% ^
    -e HOST_WORKSPACE=%cd% ^
    -e CONTAINER_WORKDIR=/workspace/%FOLDER_NAME% ^
    -e OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT=true ^
    -e HOST_PORT=%HOST_PORT% ^
    -p %HOST_PORT%:1337 ^
    -v "%USERPROFILE%\.claude:/root/.claude" ^
    -v "%USERPROFILE%\.config:/root/.config" ^
    %EXTRA_VOLUMES% ^
    -v "%PARENT_DIR%:/workspace" ^
    -w "/workspace/%FOLDER_NAME%" ^
    claude-code%EXTRA_ARGS%
