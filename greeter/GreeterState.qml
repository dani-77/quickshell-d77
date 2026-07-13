pragma Singleton
import QtQuick
import Quickshell

// Global singleton: shared login state, read/written by Greeter.qml
// (the Greetd IPC + session scanner) and rendered by every per-monitor
// GreeterSurface instance.
//
// Usage (relative import, no qs.* alias):
//   import "../Services" as Services   // pattern used elsewhere in the repo
//   GreeterState.username

Singleton {
    id: root

    property string username: ""
    property string password: ""
    property string pamState: ""   // "" | "authenticating" | "fail" | "error"
    property bool   unlocking: false

    // One entry per discovered *.desktop session, same index across all
    // four arrays. sessionTypes[i] is "wayland" or "x11" depending on
    // whether the entry came from a wayland-sessions or xsessions dir —
    // this drives the startx wrapping done in Greeter.qml on launch.
    property var sessionList:  []
    property var sessionExecs: []
    property var sessionPaths: []
    property var sessionTypes: []
    property int currentSessionIndex: 0

    function reset() {
        password = "";
        pamState = "";
        unlocking = false;
    }
}
