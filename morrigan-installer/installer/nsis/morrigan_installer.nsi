!include "Morrigan Installer"

OutFile "MorriganInstaller.exe"
InstallDir "$PROGRAMFILES\Morrigan"
RequestExecutionLevel admin

Section "Install"
    SetOutPath "$INSTDIR"
    File /r "..\..\resources\*.*"
    File /r "..\..\installer\*.*"
    CreateShortcut "$DESKTOP\Morrigan.lnk" "$INSTDIR\Morrigan.exe"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\Morrigan.exe"
    RMDir /r "$INSTDIR"
    Delete "$DESKTOP\Morrigan.lnk"
SectionEnd

Function .onInit
    MessageBox MB_OK "Welcome to the Morrigan Installer"
FunctionEnd

Function .onInstSuccess
    MessageBox MB_OK "Installation completed successfully!"
FunctionEnd

Function .onUninstSuccess
    MessageBox MB_OK "Uninstallation completed successfully!"
FunctionEnd