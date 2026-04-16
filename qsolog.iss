[Setup]
AppId={{5763CB51-C77B-4A55-BBBF-57089D69D7D3}
AppName=QSOLog
AppVersion=1.0.0
AppPublisher=Francisco Iacobelli
DefaultDirName={autopf}\QSOLog
DefaultGroupName=QSOLog
OutputDir=.\installer
OutputBaseFilename=QSOLogSetup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile=windows\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "redist\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "redist\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "redist\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\QSOLog"; Filename: "{app}\qsolog.exe"; WorkingDir: "{app}"
Name: "{commondesktop}\QSOLog"; Filename: "{app}\qsolog.exe"; WorkingDir: "{app}"; Tasks: desktopicon
WorkingDir: "{app}"

[Run]
Filename: "{app}\qsolog.exe"; Description: "Launch QSOLog"; Flags: nowait postinstall skipifsilent