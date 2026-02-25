@echo off
REM Start OpenCode in Docker with the current directory mounted as /workspace.
REM Usage:
REM   oc             Start a new session
REM   oc --continue  Continue the previous session for this folder
REM
REM Auth: On first run, OpenCode will prompt you to connect a provider.
REM       The config is persisted so you only need to do this once.
REM
REM If a .env file exists in the docker-master folder, it is automatically loaded.

REM Create a container name from the folder name (replace spaces/special chars)
for %%I in ("%cd%") do set "FOLDER_NAME=%%~nxI"
set "CONTAINER_NAME=opencode-%FOLDER_NAME%"
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
if "%~1"=="--continue" (
    docker container inspect %CONTAINER_NAME% >nul 2>&1
    if not errorlevel 1 (
        echo Continuing previous session...
        docker start %CONTAINER_NAME%
        docker exec -it %CONTAINER_NAME% opencode --continue
    ) else (
        echo No previous session found, starting fresh...
        docker run -it ^
            --name %CONTAINER_NAME% ^
            %ENV_FLAG% ^
            -e AGENT_CMD=opencode ^
            -e HOST_WORKSPACE=%cd% ^
            -e CONTAINER_WORKDIR=/workspace/%FOLDER_NAME% ^
            -e HOST_PORT=%HOST_PORT% ^
            -p %HOST_PORT%:1337 ^
            -v "%USERPROFILE%\.claude:/root/.claude" ^
            -v "%USERPROFILE%\.config:/root/.config" ^
            -v "%PARENT_DIR%:/workspace" ^
            -w "/workspace/%FOLDER_NAME%" ^
            claude-code
    )
    goto :eof
)

REM Handle /bin/bash: only proceed if the container already exists
if "%~1"=="/bin/bash" (
    docker container inspect %CONTAINER_NAME% >nul 2>&1
    if errorlevel 1 (
        echo Container %CONTAINER_NAME% does not exist.
        goto :eof
    )
    docker start %CONTAINER_NAME%
    docker exec -it %CONTAINER_NAME% /bin/bash
    goto :eof
)

REM Remove old container for this folder if it exists
docker rm -f %CONTAINER_NAME% >nul 2>&1

docker run -it ^
    --name %CONTAINER_NAME% ^
    %ENV_FLAG% ^
    -e AGENT_CMD=opencode ^
    -e HOST_WORKSPACE=%cd% ^
    -e CONTAINER_WORKDIR=/workspace/%FOLDER_NAME% ^
    -e HOST_PORT=%HOST_PORT% ^
    -p %HOST_PORT%:1337 ^
    -v "%USERPROFILE%\.claude:/root/.claude" ^
    -v "%USERPROFILE%\.config:/root/.config" ^
    -v "%PARENT_DIR%:/workspace" ^
    -w "/workspace/%FOLDER_NAME%" ^
    claude-code %*
