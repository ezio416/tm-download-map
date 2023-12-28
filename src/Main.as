/*
c 2023-12-03
m 2023-12-27
*/

string downloadedFolder = IO::FromUserGameFolder("Maps/Downloaded").Replace("\\", "/");
Json::Value@ history = Json::Object();
string historyFile = IO::FromStorageFolder("history.json");
string title = "\\$F5F" + Icons::Download + "\\$G Download Map";

[Setting category="General" name="Max history length" min=1 max=50]
uint historyMax = 20;

void Main() {
    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    LoadHistoryFile();

    while (true) {
        if (App.RootMap !is null) {
            CSystemFidFile@ File = GetFidFromNod(App.RootMap);

            if (File !is null)
                AddMap(App.RootMap.MapName, string(File.FullFileName).Replace("\\", "/"));
        }

        yield();
    }
}

void RenderMenu() {
    if (UI::BeginMenu(title)) {
        if (UI::MenuItem(Icons::ExternalLink + " Open \"Downloaded\" Folder"))
            OpenExplorerPath(downloadedFolder);

        for (int i = history.Length - 1; i >= 0; i--) {
            Json::Value@ map = history[tostring(i)];

            string name = ColoredString(string(map["name"]));
            string path = string(map["path"]);

            if (UI::MenuItem(Icons::Download + " Download \"" + name + "\\$G\""))
                CopyMapToDownloaded(name, path);
        }

        UI::EndMenu();
    }
}

void AddMap(const string &in name, const string &in path) {
    Json::Value@ newMap = Json::Object();
    newMap["name"] = name;
    newMap["path"] = path;

    if (history.Length == 0) {
        history["0"] = newMap;
        SaveHistoryFile();
        return;
    }

    if (string(history[tostring(history.Length - 1)]["path"]) == path)
        return;

    int foundIndex = -1;

    for (uint i = 0; i < history.Length - 1; i++) {
        if (string(history[tostring(i)]["path"]) == path) {
            print(name + " found at " + i);
            foundIndex = i;
            break;
        }
    }

    if (foundIndex > -1) {
        for (uint i = foundIndex + 1; i < history.Length; i++) {
            Json::Value@ map = history[tostring(i)];
            print("shifting " + string(map["name"]) + " from index " + i + " to " + tostring(i - 1));
            history[tostring(i - 1)] = map;
        }
        history[tostring(history.Length - 1)] = newMap;
    } else {
        print("adding " + name + " to history");
        history[tostring(history.Length)] = newMap;
    }

    SaveHistoryFile();
}

void CopyMapToDownloaded(const string &in name, const string &in path) {
    trace("reading cached map file at " + path);

    if (!IO::FileExists(path)) {
        warn("cached file for \"" + name + "\" not found!");
        return;
    }

    IO::File oldFile(path);
    oldFile.Open(IO::FileMode::Read);
    MemoryBuffer@ buf = oldFile.Read(oldFile.Size());
    oldFile.Close();

    string newName = downloadedFolder + "/" + StripFormatCodes(name);
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

void LoadHistoryFile() {
    trace("loading history.json...");

    if (!IO::FileExists(historyFile)) {
        trace("history.json not found!");
        history = Json::Object();
        return;
    }

    history = Json::FromFile(historyFile);
}

void SaveHistoryFile() {
    trace("saving history.json...");

    Json::ToFile(historyFile, history);
}