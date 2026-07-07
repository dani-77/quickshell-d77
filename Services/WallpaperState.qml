pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Singleton global: expõe o caminho do wallpaper atualmente ativo, lido
// do mesmo ficheiro escrito por Wallpaper.qml (persistProc/_persist) e
// por apply-saved-wallpaper.sh no arranque do Hyprland.
//
// Uso noutros ficheiros QML (import relativo, sem alias qs.*):
//   import "../Services" as Services
//   Services.WallpaperState.hasWallpaper
//
// Não escreve o ficheiro no caminho normal (isso já é feito pelo
// Wallpaper.qml); só reage a mudanças externas via FileView.watchChanges.

Singleton {
    id: root

    // Tem de bater certo com stateFile em wallpaper/Wallpaper.qml e
    // STATE_FILE em wallpaper/apply-saved-wallpaper.sh.
    readonly property string statePath: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper/current"

    property string currentPath: ""
    readonly property bool hasWallpaper: currentPath !== ""

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false

        onLoaded: root.currentPath = text().trim()
        onLoadFailed: error => root.currentPath = ""
        onFileChanged: stateFile.reload()
    }
}
