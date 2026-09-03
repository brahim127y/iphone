[Setup]
AppId={{D37B7E20-2E31-4F43-B029-45371A099A2D}
AppName=Tembs Boutique
AppVersion=1.0.0
AppPublisher=Tembs
DefaultDirName={autopf}\Tembs Boutique
DefaultGroupName=Tembs Boutique
UninstallDisplayIcon={app}\boutique_app.exe
OutputDir=build\windows\installer
OutputBaseFilename=Setup_Tembs_Boutique
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Tembs Boutique"; Filename: "{app}\boutique_app.exe"
Name: "{autodesktop}\Tembs Boutique"; Filename: "{app}\boutique_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\boutique_app.exe"; Description: "{cm:LaunchProgram,Tembs Boutique}"; Flags: nowait postinstall skipifsilent
