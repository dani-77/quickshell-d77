// ══════════════════════════════════════════════════════
// MusicPicker.qml
// Searchable Artist/Album popup, scanning musicDir for two-level
// Artist/Album folders and starting playback of the picked album in cmus
// via Services.CmusControl.playAlbum().
//
// Port of music_picker.py from fabric-d77 to native quickshell: mirrors
// Launcher.qml's search+list pattern (TextInput + filtered ListView) the
// same way Launcher itself mirrors AppLoader, swapping desktop apps for
// album folders and launch() for CmusControl.playAlbum().
// Opened from the dashboard's "Browse albums" button (Dashboard.qml).
// ══════════════════════════════════════════════════════
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../Services" as Services

PanelWindow {
    id: picker

    // ══════════════════════════════════════════════════════
    // THEME (Tokyo Night) — mirrors Launcher.qml
    // ══════════════════════════════════════════════════════
    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colMuted:  "#444b6a"
    property color colCyan:   "#0db9d7"
    property color colBlue:   "#7aa2f7"
    property color colPurple: "#bb9af7"
    property string font:     "JetBrainsMono Nerd Font"
    property int    fsize:    13

    // ══════════════════════════════════════════════════════
    // CONFIG
    // ══════════════════════════════════════════════════════
    // Directory to scan for Artist/Album folders. Override in shell.qml if needed.
    property string musicDir: Quickshell.env("HOME") + "/Música"

    // ══════════════════════════════════════════════════════
    // STATE
    // ══════════════════════════════════════════════════════
    property var albums: []
    property bool loading: false
    property string query: ""
    // albums reference forces re-evaluation when the scan updates the list
    // (bindings only auto-track properties read directly here, not ones
    // read inside the called function — same trick as Launcher.results).
    property var results: {
        picker.albums
        return picker._filter(query)
    }
    property int selected: 0

    function _filter(q) {
        if (q === "") return picker.albums
        var needle = q.toLowerCase()
        return picker.albums.filter(a => a.display.toLowerCase().includes(needle))
    }

    onResultsChanged: selected = 0

    // ── Public API ───────────────────────────────────────
    function open() {
        searchField.text = ""
        query    = ""
        selected = 0
        visible  = true
        reload()
        searchField.forceActiveFocus()
    }
    function hide()  { visible = false }
    function close() { hide() }
    function toggle() {
        if (visible) hide()
        else         open()
    }

    function reload() {
        loading = true
        albums  = []
        scanProc.running = true
    }

    // ── Moves selection keeping inside bounds ─────────────
    function moveSelection(delta) {
        if (results.length === 0) {
            selected = 0
            return
        }
        var n = (selected + delta) % results.length
        if (n < 0) n += results.length
        selected = n
    }

    function playSelected() {
        if (results.length === 0)
            return
        play(results[selected])
    }

    function play(album) {
        if (!album)
            return
        Services.CmusControl.playAlbum(album.path)
        hide()
    }

    // Plays an album by path directly, without requiring the picker to be
    // open first — for scripting (e.g. `qs ipc call musicpicker play /path`),
    // mirrors wallpaper's IPC `set(path)`.
    function playPath(path) {
        Services.CmusControl.playAlbum(path)
    }

    // ══════════════════════════════════════════════════════
    // PROCESSES
    // ══════════════════════════════════════════════════════

    // Scans musicDir for two-level Artist/Album directories.
    // %P is the path relative to musicDir, e.g. "Emperor/1994 - ...",
    // split in JS below into artist/album.
    Process {
        id: scanProc
        command: ["sh", "-c",
            "find \"" + picker.musicDir + "\" -mindepth 2 -maxdepth 2 -type d " +
            "-printf \"%P\\t%p\\n\" 2>/dev/null | sort"
        ]
        running: false
        stdout: SplitParser {
            onRead: function (line) {
                if (line.trim() === "")
                    return
                var parts = line.split("\t")
                if (parts.length < 2)
                    return
                var rel   = parts[0]
                var path  = parts[1]
                var slash = rel.indexOf("/")
                if (slash < 0)
                    return
                var artist = rel.slice(0, slash)
                var album  = rel.slice(slash + 1)
                var arr = picker.albums.slice()
                arr.push({ artist: artist, album: album, path: path, display: artist + " — " + album })
                picker.albums = arr
            }
        }
        onExited: function (code) {
            picker.loading = false
        }
    }

    // ══════════════════════════════════════════════════════
    // LAYER SHELL WINDOW
    // ══════════════════════════════════════════════════════
    visible: false
    color: "transparent"

    implicitWidth:  560
    implicitHeight: 420

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace:     "quickshell-musicpicker"

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        MouseArea {
            anchors.fill: parent
            onClicked: picker.hide()
        }
    }

    // ══════════════════════════════════════════════════════
    // PICKER BOX
    // ══════════════════════════════════════════════════════
    Rectangle {
        id: box
        anchors.centerIn: parent
        width:  parent.width
        height: parent.height
        radius: 12
        color: picker.colBg
        border.color: picker.colPurple
        border.width: 2

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 14
            spacing: 10

            // ── Search field ────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 8
                color: Qt.darker(picker.colBg, 1.3)
                border.color: searchField.activeFocus ? picker.colPurple : picker.colMuted
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin:  12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "󰎈"
                        font.family: picker.font
                        font.pixelSize: picker.fsize + 2
                        color: picker.colPurple
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        clip: true
                        color: picker.colFg
                        font.family: picker.font
                        font.pixelSize: picker.fsize + 1
                        selectionColor: picker.colPurple
                        selectByMouse: true
                        focus: true

                        onTextChanged: picker.query = text

                        // ── Keyboard navigation ─────────
                        Keys.onEscapePressed:    picker.hide()
                        Keys.onUpPressed:        picker.moveSelection(-1)
                        Keys.onDownPressed:      picker.moveSelection(1)
                        Keys.onReturnPressed:    picker.playSelected()
                        Keys.onEnterPressed:     picker.playSelected()
                        Keys.onPressed: function (e) {
                            if (e.key === Qt.Key_Tab) {
                                picker.moveSelection(1)
                                e.accepted = true
                            }
                        }

                        // Placeholder
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            visible: searchField.text === ""
                            text: "Search Artist / Album..."
                            font: searchField.font
                            color: picker.colMuted
                        }
                    }
                }
            }

            // ── Result list ───────────────────────
            ListView {
                id: list
                Layout.fillWidth:  true
                Layout.fillHeight: true
                clip: true
                model: picker.results
                currentIndex: picker.selected
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: Rectangle {
                    required property int index
                    required property var modelData

                    width:  list.width
                    height: 48
                    radius: 8
                    color: index === picker.selected
                        ? Qt.rgba(0.73, 0.60, 0.97, 0.22)
                        : (itemMa.containsMouse ? Qt.rgba(0.48, 0.64, 0.97, 0.12)
                                                : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin:  12
                        anchors.rightMargin: 12
                        spacing: 12

                        Rectangle {
                            width: 3
                            height: 26
                            radius: 2
                            color: index === picker.selected ? picker.colPurple : "transparent"
                        }

                        Text {
                            text: "󰎈"
                            font.family: picker.font
                            font.pixelSize: picker.fsize + 4
                            color: picker.colMuted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: modelData.album
                                elide: Text.ElideRight
                                font.family: picker.font
                                font.pixelSize: picker.fsize + 1
                                font.bold: index === picker.selected
                                color: picker.colFg
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.artist
                                elide: Text.ElideRight
                                font.family: picker.font
                                font.pixelSize: picker.fsize - 2
                                color: picker.colMuted
                            }
                        }
                    }

                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered:  picker.selected = index
                        onClicked:  picker.play(modelData)
                    }
                }

                // Empty list message
                Text {
                    anchors.centerIn: parent
                    visible: picker.results.length === 0
                    text: picker.loading ? "Loading albums..."
                                          : "No albums found in\n" + picker.musicDir
                    horizontalAlignment: Text.AlignHCenter
                    font.family: picker.font
                    font.pixelSize: picker.fsize
                    color: picker.colMuted
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: picker.results.length + " / " + picker.albums.length + " albums"
                font.family: picker.font
                font.pixelSize: picker.fsize - 2
                color: picker.colMuted
            }
        }
    }
}
