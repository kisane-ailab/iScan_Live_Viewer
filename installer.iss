[Setup]
AppName=iScan Live Viewer
AppVersion=1.0.0
AppPublisher=iScan
DefaultDirName={autopf}\iScan Live Viewer
DefaultGroupName=iScan Live Viewer
OutputDir=installer
OutputBaseFilename=iScan_Live_Viewer_Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Files]
Source: "build\windows\x64\runner\Release\iscan_live_viewer.exe"; DestDir: "{app}"; DestName: "iScan Live Viewer.exe"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\libzmq-v142-mt-4_3_5.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\libzmq-v142-mt-4_3_5.dll"; DestDir: "{app}"; DestName: "libzmq.dll"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\iScan Live Viewer"; Filename: "{app}\iScan Live Viewer.exe"
Name: "{group}\Uninstall iScan Live Viewer"; Filename: "{uninstallexe}"
Name: "{commondesktop}\iScan Live Viewer"; Filename: "{app}\iScan Live Viewer.exe"

[Run]
Filename: "{app}\iScan Live Viewer.exe"; Description: "Launch iScan Live Viewer"; Flags: nowait postinstall skipifsilent
