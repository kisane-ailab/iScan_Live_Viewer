[Setup]
AppName=iScan Live Viewer
AppVersion=1.0.1
AppPublisher=iScan
DefaultDirName={autopf}\iScan Live Viewer
DefaultGroupName=iScan Live Viewer
OutputDir=installer
OutputBaseFilename=iScan_Live_Viewer_Setup_v1.0.1
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\iScan Live Viewer.exe
SetupIconFile=windows\runner\resources\app_icon.ico
DisableDirPage=no

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Files]
Source: "build\windows\x64\runner\Release\iscan_live_viewer.exe"; DestDir: "{app}"; DestName: "iScan Live Viewer.exe"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\libzmq-v142-mt-4_3_5.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\libzmq-mt-4_3_5.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\turbojpeg.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\jpeg62.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\app_links_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\iScan Live Viewer"; Filename: "{app}\iScan Live Viewer.exe"
Name: "{group}\Uninstall iScan Live Viewer"; Filename: "{uninstallexe}"
Name: "{commondesktop}\iScan Live Viewer"; Filename: "{app}\iScan Live Viewer.exe"

[Run]
Filename: "{app}\iScan Live Viewer.exe"; Description: "Launch iScan Live Viewer"; Flags: nowait postinstall skipifsilent
