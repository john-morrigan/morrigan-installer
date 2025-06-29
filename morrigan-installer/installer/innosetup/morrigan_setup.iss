[Setup]
AppName=Morrigan Client
AppVersion=0.1.0
DefaultDirName={pf}\Morrigan
DefaultGroupName=Morrigan
OutputDir=.
OutputBaseFilename=morrigan_installer
SetupIcon=..\resources\icons\morrigan.ico
UninstallIcon=..\resources\icons\uninstall.ico
Compression=lzma
SolidCompression=yes

[Files]
Source: "..\dist\morrigan.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\resources\license\LICENSE.rtf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\resources\images\banner.bmp"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\resources\images\dialog.bmp"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\templates\service_install.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\templates\service_uninstall.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\templates\post_install.py"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Morrigan Client"; Filename: "{app}\morrigan.exe"
Name: "{group}\Uninstall Morrigan Client"; Filename: "{un}\uninstall.exe"

[Run]
Filename: "{app}\morrigan.exe"; Description: "{cm:LaunchProgram,Morrigan Client}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{app}\uninstall.exe"; Description: "{cm:UninstallProgram,Morrigan Client}"; Flags: nowait postinstall skipifsilent