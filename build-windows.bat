@echo off
echo Building Alpidi Printer Agent for Windows...

REM Clean and build the project
call mvnw.cmd clean package -DskipTests

REM Check if build was successful
if %ERRORLEVEL% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

REM Create distribution directory
if not exist "dist" mkdir dist

REM Copy the generated exe file to distribution directory
copy target\alpidi-printer-agent.exe dist\

REM Check if NSIS is available and build installers
where makensis >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo Building auto-installer with NSIS...
    makensis installer.nsi
    if exist AlpidiPrinterAgentAutoInstaller.exe (
        copy AlpidiPrinterAgentAutoInstaller.exe dist\
        echo - AlpidiPrinterAgentAutoInstaller.exe created (Silent install + auto-start)
    )
    
    echo Building portable installer...
    makensis portable-installer.nsi
    if exist AlpidiPrinterAgent-Portable.exe (
        copy AlpidiPrinterAgent-Portable.exe dist\
        echo - AlpidiPrinterAgent-Portable.exe created (No install, runs immediately)
    )
) else (
    echo NSIS not found. Skipping installer creation.
    echo Install NSIS from https://nsis.sourceforge.io/ to create installers.
)

echo.
echo ========================================
echo BUILD COMPLETED SUCCESSFULLY!
echo ========================================
echo.
echo Generated files in 'dist' folder:
echo.
echo 1. alpidi-printer-agent.exe
echo    - Standard executable (requires Java 17+)
echo    - User needs to manually run
echo.
if exist dist\AlpidiPrinterAgentAutoInstaller.exe (
    echo 2. AlpidiPrinterAgentAutoInstaller.exe
    echo    - Silent installer (no user interaction)
    echo    - Automatically installs and starts the application
    echo    - Adds to Windows startup
    echo    - Creates system tray icon
    echo.
)
if exist dist\AlpidiPrinterAgent-Portable.exe (
    echo 3. AlpidiPrinterAgent-Portable.exe
    echo    - Portable version (no installation required)
    echo    - Extracts to temp folder and runs immediately
    echo    - Self-cleaning after execution
    echo.
)
echo RECOMMENDATION FOR DISTRIBUTION:
if exist dist\AlpidiPrinterAgent-Portable.exe (
    echo Use 'AlpidiPrinterAgent-Portable.exe' for easiest user experience
    echo - User just downloads and double-clicks
    echo - No installation process
    echo - Runs immediately
) else (
    echo Use 'alpidi-printer-agent.exe' 
    echo - Requires Java 17+ on user's machine
)
echo.
echo The application will run on: http://localhost:9000
pause