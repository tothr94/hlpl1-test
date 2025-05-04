@echo off
REM === Check for workspace folder path ===
IF "%~1"=="" (
    echo Usage: %~nx0 ^<workspace-folder-path^>
    exit /b 1
)

REM === CONFIGURATION ===
SET "EXT_IDS=ms-vscode.cpptools ms-vscode.cpptools-extension-pack"
SET "WORKSPACE_DIR=%~1"
SET "CUSTOM_EXT_DIR=%WORKSPACE_DIR%\extensions"
SET "WORKSPACE_FILE=%WORKSPACE_DIR%\cpp-only.code-workspace"
SET "SOLUTION_FILE=%WORKSPACE_DIR%\solution.c"

REM === Ensure workspace folder exists ===
IF NOT EXIST "%WORKSPACE_DIR%" (
    echo Workspace folder "%WORKSPACE_DIR%" does not exist.
    exit /b 1
)

REM === Create empty solution.c if it doesn't exist ===
IF NOT EXIST "%SOLUTION_FILE%" (
    type nul > "%SOLUTION_FILE%"
)

REM === Clean and prepare custom extension dir ===
IF EXIST "%CUSTOM_EXT_DIR%" (
    rd /s /q "%CUSTOM_EXT_DIR%"
)
mkdir "%CUSTOM_EXT_DIR%"

REM === Install and move each extension into the custom dir ===
FOR %%E IN (%EXT_IDS%) DO (
    echo Installing %%E...
    code --install-extension %%E --force
    IF ERRORLEVEL 1 (
        echo Failed to install extension %%E
        exit /b 1
    )
    
    REM === Move the installed extension to the custom directory ===
    CALL :MOVE_EXTENSION %%E
)

REM === Create the .code-workspace file ===
(
    echo {
    echo   "folders": [
    echo     {
    echo       "path": "."
    echo     }
    echo   ],
    echo   "settings": {
    echo     "extensions.ignoreRecommendations": true
    echo   }
    echo }
) > "%WORKSPACE_FILE%"

REM === Launch VS Code ===
pushd "%WORKSPACE_DIR%"
code --extensions-dir "%CUSTOM_EXT_DIR%" "%WORKSPACE_FILE%"
popd
exit /b 0

:MOVE_EXTENSION
SETLOCAL ENABLEDELAYEDEXPANSION
SET "EXT_ID=%1"
SET "EXT_DIR=%USERPROFILE%\.vscode\extensions\!EXT_ID!*"
IF NOT EXIST "!EXT_DIR!" (
    echo Extension directory for !EXT_ID! not found.
    ENDLOCAL
    exit /b 1
)

REM === Move the extension to the custom directory ===
xcopy /E /I /Y "!EXT_DIR!" "%CUSTOM_EXT_DIR%\!EXT_ID!" >nul
rd /s /q "!EXT_DIR!" >nul
ENDLOCAL
GOTO :EOF
