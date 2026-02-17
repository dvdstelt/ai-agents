@echo off
REM Start Claude Code in Docker with the current directory mounted as /workspace.
REM Usage:
REM   cc             Start a new session
REM   cc --continue  Continue the previous session for this folder
REM
REM Auth: On first run, Claude will prompt you to log in via your claude.ai account.
REM       The config is persisted so you only need to do this once.
REM
REM If a .env file exists in the docker-master folder, it is automatically loaded.

REM Create a container name from the folder name (replace spaces/special chars)
for %%I in ("%cd%") do set "FOLDER_NAME=%%~nxI"
set "CONTAINER_NAME=claude-%FOLDER_NAME%"

REM Check for .env file in docker-master folder
set "ENV_FLAG="
if exist "%~dp0.env" (
    set "ENV_FLAG=--env-file %~dp0.env"
    echo Loading .env file from %~dp0
)

echo Mounting: %cd%
echo Container: %CONTAINER_NAME%
echo.

REM Handle --continue: reattach to existing container, or start fresh if none exists
if "%~1"=="--continue" (
    docker container inspect %CONTAINER_NAME% >nul 2>&1
    if not errorlevel 1 (
        echo Continuing previous session...
        docker start -ai %CONTAINER_NAME%
    ) else (
        echo No previous session found, starting fresh...
        docker run -it ^
            --name %CONTAINER_NAME% ^
            %ENV_FLAG% ^
            -v "%USERPROFILE%\.claude:/root/.claude" ^
            -v "%USERPROFILE%\.config:/root/.config" ^
            -v "%cd%:/workspace" ^
            claude-code
    )
    goto :eof
)

REM Remove old container for this folder if it exists
docker rm %CONTAINER_NAME% >nul 2>&1

docker run -it ^
    --name %CONTAINER_NAME% ^
    %ENV_FLAG% ^
    -v "%USERPROFILE%\.claude:/root/.claude" ^
    -v "%USERPROFILE%\.config:/root/.config" ^
    -v "%cd%:/workspace" ^
    claude-code %*
