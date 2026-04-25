[Setup]
AppName=QSOLog
AppVersion=1.0.0
AppPublisher=Your Name
AppPublisherURL=https://yourwebsite.com
DefaultDirName={autopf}\QSOLog
DefaultGroupName=QSOLog
OutputDir=.\installer
OutputBaseFilename=QSOLogSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=windows\runner\resources\app_icon.ico
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "build\windows\x64\runner\Release\qsolog.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "redist\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "redist\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "redist\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\QSOLog"; Filename: "{app}\qsolog.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall QSOLog"; Filename: "{uninstallexe}"
Name: "{commondesktop}\QSOLog"; Filename: "{app}\qsolog.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\qsolog.exe"; WorkingDir: "{app}"; Description: "Launch QSOLog"; Flags: nowait postinstall skipifsilent