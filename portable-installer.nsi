; Alpidi Printer Agent Portable Auto-Run Installer
!define APPNAME "Alpidi Printer Agent"
!define COMPANYNAME "Alpidi"

Name "${APPNAME} Portable"
OutFile "AlpidiPrinterAgent-Portable.exe"
Icon "icon.ico"

; No admin rights required for portable version
RequestExecutionLevel user

; Silent install - no user interaction
SilentInstall silent
AutoCloseWindow true

; Extract to user's AppData directory for persistence
InstallDir "$APPDATA\${COMPANYNAME}\${APPNAME}"

Section "MainSection" SEC01
    ; Create application directory
    SetOutPath $INSTDIR
    
    ; Extract the main executable
    File "target\alpidi-printer-agent.exe"
    
    ; Create a startup batch file
    FileOpen $0 "$INSTDIR\startup.bat" w
    FileWrite $0 "@echo off$\r$\n"
    FileWrite $0 "title ${APPNAME}$\r$\n"
    FileWrite $0 "cd /d $\"$INSTDIR$\"$\r$\n"
    FileWrite $0 "echo Starting ${APPNAME}...$\r$\n"
    FileWrite $0 "echo Application will be available at: http://localhost:9000$\r$\n"
    FileWrite $0 "echo.$\r$\n"
    FileWrite $0 "echo Press Ctrl+C to stop the application$\r$\n"
    FileWrite $0 "echo.$\r$\n"
    FileWrite $0 "alpidi-printer-agent.exe$\r$\n"
    FileClose $0
    
    ; Create desktop shortcut for easy access
    CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\startup.bat" "" "$INSTDIR\alpidi-printer-agent.exe" 0 SW_SHOWMINIMIZED
    
    ; Add to Windows startup (optional - user can remove if not wanted)
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${APPNAME}" "$INSTDIR\startup.bat"
    
    ; Start the application immediately
    ExecShell "open" "$INSTDIR\startup.bat" "" SW_SHOWMINIMIZED
    
    ; Show success message
    MessageBox MB_ICONINFORMATION|MB_TOPMOST "${APPNAME} has been installed and started!$\n$\nThe application is now running at: http://localhost:9000$\n$\nA desktop shortcut has been created for easy access.$\n$\nThe application will start automatically with Windows." /SD IDOK
SectionEnd