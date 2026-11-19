import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.WindowManager

// Generic widget for any compositor implementing ext-workspace-v1 (niri, wasp,
// spitfire, ...), which Quickshell.WindowManager wraps directly — no IPC
// polling needed, workspace state stays reactive for free.
//
// Unlike the sway/Hyprland widgets, this shows only the workspaces the
// compositor advertises rather than a static 1-9 grid, since some compositors
// (niri) create them dynamically.
RowLayout {
    id: root
    spacing: 6
    property var globalState
    property var screen

    // Compositors such as wasp advertise one workspace group per monitor, so
    // the full list would repeat every workspace once per monitor. Show only
    // this bar's monitor, keeping the full list if no group claims that screen.
    readonly property var available: {
        const onScreen = screen ? WindowManager.screenProjection(screen)?.windowsets ?? [] : [];
        return onScreen.length > 0 ? onScreen : WindowManager.windowsets;
    }

    readonly property var sorted: {
        const ws = root.available.filter(w => w.shouldDisplay);
        ws.sort((a, b) => {
            const ac = a.coordinates, bc = b.coordinates;
            for (let i = 0; i < Math.max(ac.length, bc.length); i++) {
                const av = ac[i] ?? 0, bv = bc[i] ?? 0;
                if (av !== bv) return av - bv;
            }
            return 0;
        });
        return ws;
    }

    // ext-workspace has no "occupied" state, so the d77 compositors (whiplash,
    // wasp, spitfire) write one line per workspace, "<ext-workspace id>
    // <window count>", to $XDG_RUNTIME_DIR/d77-workspaces-$WAYLAND_DISPLAY.
    // Without that file windowCounts stays null and nothing is dimmed.
    property var windowCounts: null

    FileView {
        id: countsFile
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/d77-workspaces-" + Quickshell.env("WAYLAND_DISPLAY")
        watchChanges: true
        printErrors: false

        onLoaded: {
            const counts = {};
            for (const line of text().split("\n")) {
                const parts = line.trim().split(/\s+/);
                if (parts.length === 2) counts[parts[0]] = parseInt(parts[1]);
            }
            root.windowCounts = counts;
        }
        onLoadFailed: error => root.windowCounts = null
        onFileChanged: countsFile.reload()
    }

    function isEmpty(ws) {
        return root.windowCounts !== null && root.windowCounts[ws.id] === 0;
    }

    Repeater {
        model: root.sorted

        delegate: Rectangle {
            required property var modelData

            width: 22
            height: 22
            radius: 4
            color: modelData.active ? globalState.colPurple
                 : modelData.urgent ? globalState.colRed
                 : Qt.alpha(globalState.colBlue, 0.25)
            // Empty workspaces fade back; the active one never does.
            opacity: !modelData.active && !modelData.urgent && root.isEmpty(modelData) ? 0.4 : 1

            Text {
                anchors.centerIn: parent
                text: modelData.name
                color: modelData.active || modelData.urgent ? globalState.colBg : globalState.colBlue
                font { family: globalState.font; pixelSize: globalState.fsize; bold: true }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (modelData.canActivate) modelData.activate();
                }
            }
        }
    }
}
