/*
c 2023-12-03
m 2023-12-03
*/

string cachePath;
string downloadedFolder = IO::FromUserGameFolder("Maps/Downloaded").Replace("\\", "/");
string mapName;
string title = "\\$F5F" + Icons::Download + "\\$G Download Map";

void Main() {
    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    while (true) {
        cachePath = "";
        mapName = "";

        if (App.RootMap !is null) {
            CSystemFidFile@ File = GetFidFromNod(App.RootMap);

            if (File !is null) {
                cachePath = string(File.FullFileName).Replace("\\", "/");
                mapName = App.RootMap.MapName;
            }
        }

        yield();
    }
}

void RenderMenu() {
    if (UI::BeginMenu(title, mapName != "")) {
        if (UI::MenuItem(Icons::Download + " Download \"" + ColoredString(mapName) + "\\$G\""))
            CopyMapToDownloaded();

        if (UI::MenuItem(Icons::ExternalLink + " Open \"Downloaded\" Folder"))
            OpenExplorerPath(downloadedFolder);

        UI::EndMenu();
    }
}

void CopyMapToDownloaded() {
    trace("reading cached map file at " + cachePath);

    IO::File oldFile(cachePath);
    oldFile.Open(IO::FileMode::Read);
    MemoryBuffer@ buf = oldFile.Read(oldFile.Size());
    oldFile.Close();

    string newName = downloadedFolder + "/" + StripFormatCodes(mapName);
    string newPath;

    uint i = 1;
    while (true) {
        newPath = newName + ".Map.Gbx";

        if (!IO::FileExists(newPath))
            break;

        trace("file exists: " + newPath);
        newName = newName.Replace(" (" + (i - 1) + ")", "") + " (" + i++ + ")";
    }

    trace("saving new map file to " + newPath);

    IO::File newFile(newPath);
    newFile.Open(IO::FileMode::Write);
    newFile.Write(buf);
    newFile.Close();
}