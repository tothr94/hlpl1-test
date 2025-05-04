@echo off

REM === CONFIGURATION ===
SET "EXT_ID=ms-vscode.cpptools"
SET "ORIG_EXT_DIR=%USERPROFILE%\.vscode\extensions"
SET "HOME_DIR=%~1"
SET "WORKSPACE_NAME=%~2"
SET "GCC_PATH=%~3"
SET "WORKSPACE_DIR=%HOME_DIR%\%WORKSPACE_NAME%"
SET "CUSTOM_EXT_DIR=%WORKSPACE_DIR%\extensions"
SET "WORKSPACE_FILE=%WORKSPACE_DIR%\%WORKSPACE_NAME%.code-workspace"
SET "SETTINGS_FILE=%WORKSPACE_DIR%\%WORKSPACE_NAME%\.vscode\settings.json"
SET "SOLUTION_FILE=%WORKSPACE_DIR%\solution.c"

REM === Check if the extension exists ===
SET "FOUND_EXT="
FOR /D %%D IN ("%ORIG_EXT_DIR%\%EXT_ID%-*") DO (
    SET "FOUND_EXT=%%D"
)

IF NOT DEFINED FOUND_EXT (
    echo Extension "%EXT_ID%" not found in %ORIG_EXT_DIR%
    exit /b 1
)

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

REM === Copy the extension ===
xcopy "%FOUND_EXT%" "%CUSTOM_EXT_DIR%\%EXT_ID%" /E /I /Y >nul

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

REM === Create the .settings file ===
(
    echo   {
    echo     "C_Cpp.default.compilerPath": "%GCC_PATH%",
    echo     "C_Cpp.intelliSenseEngine": "default"
    echo   }
) > "%SETTINGS_FILE%"

REM === Launch VS Code ===
pushd "%WORKSPACE_DIR%"
code --extensions-dir "%CUSTOM_EXT_DIR%" "%WORKSPACE_FILE%"
popd
