@echo off

REM === configuration ===
SET "EXT_ID=ms-vscode.cpptools"
SET "ORIG_EXT_DIR=%USERPROFILE%\.vscode\extensions"

REM === get paths ===
set "SCRIPT_PATH=%~dp0"
set "SCRIPT_PATH=%SCRIPT_PATH:~0,-1%"
for %%A in ("%SCRIPT_PATH%") do (
    for %%B in ("%%~dpA") do set "HOME_DIR=%%~fB"
)
for %%A in ("%SCRIPT_PATH%") do set "WORKSPACE_NAME=%%~nxA"

SET "WORKSPACE_DIR=%HOME_DIR%\%WORKSPACE_NAME%"
SET "CUSTOM_EXT_DIR=%WORKSPACE_DIR%\extensions"
SET "WORKSPACE_FILE=%WORKSPACE_DIR%\%WORKSPACE_NAME%.code-workspace"
SET "VS_CODE_FOLDER=%WORKSPACE_DIR%\.vscode"

echo Home directory: "%HOME_DIR%"
echo Workspace: "%WORKSPACE_NAME%"

for /f "usebackq delims=" %%A in (`where gcc`) do (
    set "GCC_FULL_PATH=%%A"
    goto afterWhere
)

:afterWhere
rem Extract part before \bin
for /f "delims=\ tokens=1,2" %%A in ("%gccPath%") do (
    SET "GCC_PATH=%%A\%%B"
)


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

REM === Ensure .vscode folder exists ===
IF NOT EXIST "%VS_CODE_FOLDER%" (
    echo .vscode folder "%VS_CODE_FOLDER%" does not exist.
    exit /b 1
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
    echo     "C_Cpp.default.compilerPath": "%GCC_PATH%/bin/gcc.exe",
    echo     "C_Cpp.intelliSenseEngine": "default"
    echo   }
) > "%VS_CODE_FOLDER%\settings.json"


REM === Create the c_cpp_properties.json file ===
(
    echo   {
    echo     "configurations": [
    echo       {
    echo         "name": "Win32",
    echo         "includePath": [
    echo           "${workspaceFolder}/**",
    echo           "%GCC_PATH%/include"
    echo         ],
    echo         "defines": [],
    echo         "compilerPath": "%GCC_PATH%/bin/gcc.exe",
    echo         "cStandard": "c99",
    echo         "intelliSenseMode": "gcc-x86",
    echo         "browse": {
    echo           "path": [
    echo             "%GCC_PATH%/include",
    echo             "${workspaceFolder}"
    echo           ],
    echo           "limitSymbolsToIncludedHeaders": true
    echo         }
    echo       }
    echo     ],
    echo     "version": 4
    echo   }
) > "%VS_CODE_FOLDER%\c_cpp_properties.json"

REM === Launch VS Code ===
pushd "%WORKSPACE_DIR%"
code --extensions-dir "%CUSTOM_EXT_DIR%" "%WORKSPACE_FILE%"
popd
