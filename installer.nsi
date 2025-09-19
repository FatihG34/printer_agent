; Alpidi Printer Agent Auto-Install Script
!define APPNAME "Alpidi Printer Agent"
!define COMPANYNAME "Alpidi"
!define DESCRIPTION "Local printer management service for Alpidi applications"
!define VERSIONMAJOR 1
!define VERSIONMINOR 0
!define VERSIONBUILD 0

!define HELPURL "https://alpidi.com/contact-us/"
!define UPDATEURL "https://alpidi.com/download"
!define ABOUTURL "https://alpidi.com"

!define INSTALLSIZE 50000 ; Estimate size in KB

RequestExecutionLevel admin

InstallDir "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"

Name "${APPNAME}"
Icon "icon.ico"
outFile "AlpidiPrinterAgentAutoInstaller.exe"

!include LogicLib.nsh
!include "MUI2.nsh"

; Silent install mode - no user interaction required
SilentInstall silent
AutoCloseWindow true

; No pages for silent install - just progress
!insertmacro MUI_PAGE_INSTFILES

!macro VerifyUserIsAdmin
UserInfo::GetAccountType
pop $0
${If} $0 != "admin"
    messageBox mb_iconstop "Administrator rights required!"
    setErrorLevel 740
    quit
${EndIf}
!macroend

function .onInit
    setShellVarContext all
    !insertmacro VerifyUserIsAdmin
functionEnd

section "install"
    DetailPrint "Installing ${APPNAME}..."
    setOutPath $INSTDIR
    
    ; Copy main executable
    file "target\alpidi-printer-agent.exe"
    
    ; Create uninstaller
    writeUninstaller "$INSTDIR\uninstall.exe"
    
    ; Create start menu shortcut
    createDirectory "$SMPROGRAMS\${COMPANYNAME}"
    createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\alpidi-printer-agent.exe" "" "$INSTDIR\alpidi-printer-agent.exe"
    
    ; Create desktop shortcut
    createShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\alpidi-printer-agent.exe" "" "$INSTDIR\alpidi-printer-agent.exe"
    
    ; Registry information for add/remove programs
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayIcon" "$\"$INSTDIR\alpidi-printer-agent.exe$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Publisher" "${COMPANYNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "HelpLink" "${HELPURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLUpdateInfo" "${UPDATEURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLInfoAbout" "${ABOUTURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMajor" ${VERSIONMAJOR}
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMinor" ${VERSIONMINOR}
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoRepair" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "EstimatedSize" ${INSTALLSIZE}
    
    ; Auto-start with Windows
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "${APPNAME}" "$INSTDIR\alpidi-printer-agent.exe"
    
    DetailPrint "Starting ${APPNAME}..."
    ; Start the application immediately after installation
    Exec "$INSTDIR\alpidi-printer-agent.exe"
    
    DetailPrint "Installation completed successfully!"
sectionEnd

section "uninstall"
    ; Remove registry keys
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
    DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "${APPNAME}"
    
    ; Remove files
    delete "$INSTDIR\alpidi-printer-agent.exe"
    delete "$INSTDIR\uninstall.exe"
    
    ; Remove shortcuts
    delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk"
    delete "$DESKTOP\${APPNAME}.lnk"
    
    ; Remove directories
    rmDir "$SMPROGRAMS\${COMPANYNAME}"
    rmDir "$INSTDIR"
sectionEnd