@echo off
REM === Check for workspace folder path ===
IF "%~1"=="" (
    echo Usage: %~nx0 ^<workspace-folder-path^>
    exit /b 1
)

REM === CONFIGURATION ===
SET "EXT_IDS=ms-vscode.cpptools ms-vscode.cpptools-extension-pack"
SET "ORIG_EXT_DIR=%USERPROFILE%\.vscode\extensions"
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

REM === Copy each extension ===
FOR %%E IN (%EXT_IDS%) DO (
    SET "EXT_ID=%%E"
    CALL :COPY_EXTENSION
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

:COPY_EXTENSION
SETLOCAL ENABLEDELAYEDEXPANSION
SET "FOUND_EXT="
FOR /D %%D IN ("%ORIG_EXT_DIR%\!EXT_ID!-*") DO (
    SET "FOUND_EXT=%%D"
)

IF NOT DEFINED FOUND_EXT (
    echo Extension "!EXT_ID!" not found in %ORIG_EXT_DIR%
    ENDLOCAL
    exit /b 1
)

REM Copy the extension into the custom extensions folder
xcopy "!FOUND_EXT!" "%CUSTOM_EXT_DIR%\!EXT_ID!" /E /I /Y >nul
ENDLOCAL
GOTO :EOF
