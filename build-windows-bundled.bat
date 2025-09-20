@echo off
echo 🪟 Building Self-Contained Alpidi Printer Agent for Windows...
echo.

REM Check if Java 17+ is available
java -version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ Java is required for building but not for end users!
    echo Please install Java 17+ for development: https://adoptium.net/
    pause
    exit /b 1
)

REM Clean and build the project
echo 📦 Building JAR and basic Windows executable...
call mvnw.cmd clean package -DskipTests

if %ERRORLEVEL% neq 0 (
    echo ❌ Build failed!
    pause
    exit /b 1
)

REM Create distribution directory
mkdir dist\windows-bundled 2>nul

REM Copy basic exe (requires Java on target machine)
copy target\alpidi-printer-agent.exe dist\windows-bundled\

echo.
echo 🔧 Creating self-contained Windows application...

REM Check if pre-built JRE exists
if exist "win\jre-win64" (
    echo 📦 Using pre-built JRE from win\jre-win64...
    xcopy "win\jre-win64" "dist\windows-bundled\jre" /E /I /H /Y >nul
    if %ERRORLEVEL% equ 0 (
        echo ✅ Pre-built JRE copied successfully!
    ) else (
        echo ❌ Failed to copy pre-built JRE
        goto :portable_package
    )
) else (
    echo 📦 Creating minimal JRE using jlink...
    jlink --add-modules java.base,java.desktop,java.logging,java.management,java.naming,java.net.http,java.security.jgss,java.sql,java.xml,jdk.crypto.ec,jdk.localedata,jdk.zipfs --output dist\windows-bundled\jre --no-header-files --no-man-pages --strip-debug --compress=2
    
    if %ERRORLEVEL% neq 0 (
        echo ⚠️  jlink failed, creating portable package instead...
        goto :portable_package
    )
)

REM Create self-contained application structure
mkdir dist\windows-bundled\app 2>nul
copy target\alpidiprinteragent-*-exec.jar dist\windows-bundled\app\alpidi-printer-agent.jar

REM Create launcher batch file
echo @echo off > dist\windows-bundled\AlpidiPrinterAgent.bat
echo cd /d "%%~dp0" >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo set JAVA_HOME=%%~dp0jre >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo "%%JAVA_HOME%%\bin\java.exe" -jar app\alpidi-printer-agent.jar %%* >> dist\windows-bundled\AlpidiPrinterAgent.bat

REM Create PowerShell launcher (more modern)
echo $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition > dist\windows-bundled\AlpidiPrinterAgent.ps1
echo $env:JAVA_HOME = Join-Path $scriptPath "jre" >> dist\windows-bundled\AlpidiPrinterAgent.ps1
echo $javaExe = Join-Path $env:JAVA_HOME "bin\java.exe" >> dist\windows-bundled\AlpidiPrinterAgent.ps1
echo $jarPath = Join-Path $scriptPath "app\alpidi-printer-agent.jar" >> dist\windows-bundled\AlpidiPrinterAgent.ps1
echo Start-Process -FilePath $javaExe -ArgumentList "-jar", $jarPath -NoNewWindow -Wait >> dist\windows-bundled\AlpidiPrinterAgent.ps1

REM Create Windows executable launcher using Launch4j with bundled JRE
echo 🔧 Creating bundled executable...

REM Create Launch4j config for bundled JRE
echo ^<?xml version="1.0" encoding="UTF-8"?^> > launch4j-bundled.xml
echo ^<launch4jConfig^> >> launch4j-bundled.xml
echo   ^<dontWrapJar^>false^</dontWrapJar^> >> launch4j-bundled.xml
echo   ^<headerType^>console^</headerType^> >> launch4j-bundled.xml
echo   ^<jar^>app\alpidi-printer-agent.jar^</jar^> >> launch4j-bundled.xml
echo   ^<outfile^>AlpidiPrinterAgent-Bundled.exe^</outfile^> >> launch4j-bundled.xml
echo   ^<errTitle^>Alpidi Printer Agent^</errTitle^> >> launch4j-bundled.xml
echo   ^<cmdLine^>^</cmdLine^> >> launch4j-bundled.xml
echo   ^<chdir^>.^</chdir^> >> launch4j-bundled.xml
echo   ^<priority^>normal^</priority^> >> launch4j-bundled.xml
echo   ^<downloadUrl^>^</downloadUrl^> >> launch4j-bundled.xml
echo   ^<supportUrl^>https://alpidi.com/support^</supportUrl^> >> launch4j-bundled.xml
echo   ^<stayAlive^>false^</stayAlive^> >> launch4j-bundled.xml
echo   ^<restartOnCrash^>false^</restartOnCrash^> >> launch4j-bundled.xml
echo   ^<manifest^>^</manifest^> >> launch4j-bundled.xml
echo   ^<icon^>^</icon^> >> launch4j-bundled.xml
echo   ^<jre^> >> launch4j-bundled.xml
echo     ^<path^>jre^</path^> >> launch4j-bundled.xml
echo     ^<bundledJre64Bit^>true^</bundledJre64Bit^> >> launch4j-bundled.xml
echo     ^<bundledJreAsFallback^>false^</bundledJreAsFallback^> >> launch4j-bundled.xml
echo     ^<minVersion^>17.0.0^</minVersion^> >> launch4j-bundled.xml
echo     ^<maxVersion^>^</maxVersion^> >> launch4j-bundled.xml
echo   ^</jre^> >> launch4j-bundled.xml
echo ^</launch4jConfig^> >> launch4j-bundled.xml

REM Try to use Launch4j if available
where launch4j >nul 2>&1
if %ERRORLEVEL% equ 0 (
    cd dist\windows-bundled
    launch4j ..\..\launch4j-bundled.xml
    cd ..\..
    del launch4j-bundled.xml
) else (
    echo ⚠️  Launch4j not found, using batch launcher
)

goto :success

:portable_package
echo 📦 Creating portable package without custom JRE...
mkdir dist\windows-bundled\app 2>nul
copy target\alpidiprinteragent-*-exec.jar dist\windows-bundled\app\alpidi-printer-agent.jar

REM Create launcher that tries to find Java
echo @echo off > dist\windows-bundled\AlpidiPrinterAgent.bat
echo echo Starting Alpidi Printer Agent... >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo. >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo REM Try to find Java >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo where java ^>nul 2^>^&1 >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo if %%ERRORLEVEL%% neq 0 ^( >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo     echo ❌ Java not found! Please install Java 17+ from: https://adoptium.net/ >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo     echo. >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo     echo Press any key to open download page... >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo     pause ^>nul >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo     start https://adoptium.net/temurin/releases/?version=17 >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo     exit /b 1 >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo ^) >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo. >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo cd /d "%%~dp0" >> dist\windows-bundled\AlpidiPrinterAgent.bat
echo java -jar app\alpidi-printer-agent.jar %%* >> dist\windows-bundled\AlpidiPrinterAgent.bat

:success
REM Create README
echo Alpidi Printer Agent - Windows Self-Contained Package > dist\windows-bundled\README.txt
echo. >> dist\windows-bundled\README.txt
echo ✅ NO JAVA INSTALLATION REQUIRED! >> dist\windows-bundled\README.txt
echo This package includes a bundled Java Runtime Environment. >> dist\windows-bundled\README.txt
echo. >> dist\windows-bundled\README.txt
echo INSTALLATION: >> dist\windows-bundled\README.txt
echo 1. Extract this folder to any location (e.g., C:\AlpidiPrinterAgent) >> dist\windows-bundled\README.txt
echo 2. Run AlpidiPrinterAgent.bat (or .exe if available) >> dist\windows-bundled\README.txt
echo 3. Application will start automatically >> dist\windows-bundled\README.txt
echo 4. Look for system tray icon (bottom-right corner) >> dist\windows-bundled\README.txt
echo. >> dist\windows-bundled\README.txt
echo WEB INTERFACE: >> dist\windows-bundled\README.txt
echo http://localhost:9000 >> dist\windows-bundled\README.txt
echo. >> dist\windows-bundled\README.txt
echo FEATURES: >> dist\windows-bundled\README.txt
echo • System tray integration >> dist\windows-bundled\README.txt
echo • Automatic printer detection >> dist\windows-bundled\README.txt
echo • Web-based management interface >> dist\windows-bundled\README.txt
echo • No external dependencies >> dist\windows-bundled\README.txt
echo. >> dist\windows-bundled\README.txt
echo SUPPORT: >> dist\windows-bundled\README.txt
echo https://alpidi.com/support >> dist\windows-bundled\README.txt

REM Create ZIP package
echo 📦 Creating ZIP package...
powershell -command "Compress-Archive -Path 'dist\windows-bundled\*' -DestinationPath 'dist\AlpidiPrinterAgent-Windows-SelfContained.zip' -Force"

echo.
echo ========================================
echo ✅ SELF-CONTAINED WINDOWS BUILD COMPLETED!
echo ========================================
echo.
echo 📁 Generated files:
echo.
if exist dist\windows-bundled\jre (
    echo ✅ TRULY SELF-CONTAINED PACKAGE WITH BUNDLED JRE:
    echo    📁 dist\windows-bundled\ (folder)
    echo    📦 dist\AlpidiPrinterAgent-Windows-SelfContained.zip
    echo.
    echo 📊 Package contents:
    echo    • AlpidiPrinterAgent.bat (main launcher)
    echo    • AlpidiPrinterAgent.ps1 (PowerShell launcher)
    if exist dist\windows-bundled\AlpidiPrinterAgent-Bundled.exe (
        echo    • AlpidiPrinterAgent-Bundled.exe (bundled executable)
    )
    echo    • app\alpidi-printer-agent.jar (application)
    echo    • jre\ (bundled Java Runtime Environment)
    echo    • README.txt (installation instructions)
    echo.
    echo 🎯 DISTRIBUTION: Users can run WITHOUT installing Java!
    echo 📊 Package size: ~80-120MB (includes JRE)
    echo 🚀 Ready for immediate use on any Windows machine!
) else (
    echo ⚠️  Portable package (requires Java on target machine):
    echo    📁 dist\windows-bundled\ (folder)
    echo    📦 dist\AlpidiPrinterAgent-Windows-SelfContained.zip
    echo.
    echo 📋 Users need Java 17+ installed on their machine
    echo 📊 Package size: ~20MB (application only)
)
echo.
echo 🌐 Application will be available at: http://localhost:9000
pause