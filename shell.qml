import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Módulo do launcher nativo (pasta launcher/ ao lado deste shell.qml).
// Expõe o componente Launcher — ver launcher/README.md para detalhes.
import "launcher"

ShellRoot {

    // ══════════════════════════════════════════════════════
    // LAUNCHER DE APLICATIVOS
    // ══════════════════════════════════════════════════════
    // Instância única do launcher nativo. Começa invisível e é
    // mostrado/escondido via appLauncher.toggle(). Reaproveita a
    // mesma paleta Tokyo Night e a fonte definidas em "g".
    Launcher {
        id: appLauncher
        colBg:     g.colBg
        colFg:     g.colFg
        colMuted:  g.colMuted
        colCyan:   g.colCyan
        colBlue:   g.colBlue
        colPurple: g.colPurple
        font:      g.font
        fsize:     g.fsize
        // Terminal usado para apps com Terminal=true (ajuste se necessário).
        terminal:  "foot"
    }

    // ══════════════════════════════════════════════════════
    // IPC (forma recomendada de acionar o launcher/sessão)
    // ══════════════════════════════════════════════════════
    // Expõe métodos chamáveis externamente via:
    //   qs ipc call launcher toggle
    //   qs ipc call launcher open
    //   qs ipc call launcher close
    //   qs ipc call session  toggle | open | close
    //
    // É a forma mais fiável de ligar keybinds do Hyprland (em especial
    // com configs geradas em Lua, onde o dispatcher "global" costuma ser
    // frágil). No Hyprland basta um simples exec, p.ex.:
    //   bind = SUPER, D, exec, qs ipc call launcher toggle
    // Ver KEYBINDS.md para a configuração completa (incl. Lua).
    IpcHandler {
        target: "launcher"

        // Alterna a visibilidade do launcher (abre se fechado, fecha se aberto).
        function toggle(): void { appLauncher.toggle() }
        // Abre o launcher (e foca o campo de busca).
        function open(): void { appLauncher.open() }
        // Fecha o launcher.
        function close(): void { appLauncher.close() }
    }

    IpcHandler {
        target: "session"

        // Alterna a visibilidade do menu de sessão.
        function toggle(): void { g.sessionOpen = !g.sessionOpen }
        // Abre o menu de sessão.
        function open(): void { g.sessionOpen = true }
        // Fecha o menu de sessão.
        function close(): void { g.sessionOpen = false }
    }

    // ── Atalhos globais do Hyprland (fallback) ────────────
    // Mantidos como alternativa ao IPC. Permitem acionar o launcher e o
    // menu de sessão via o dispatcher "global". O prefixo é o appid
    // (default "quickshell"), por isso os binds ficam:
    //   bind = SUPER, D,       global, quickshell:launcher
    //   bind = SUPER SHIFT, E, global, quickshell:session
    // Recomenda-se preferir o IPC (acima); ver KEYBINDS.md.
    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        description: "Abre/fecha o launcher de aplicativos"
        onPressed: appLauncher.toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "session"
        description: "Abre/fecha o menu de sessão (lock/suspend/reboot/...)"
        onPressed: g.sessionOpen = !g.sessionOpen
    }

    // ══════════════════════════════════════════════════════
    // GLOBAL
    // ══════════════════════════════════════════════════════
    QtObject {
        id: g
        property color colBg:     "#1a1b26"
        property color colFg:     "#a9b1d6"
        property color colMuted:  "#444b6a"
        property color colCyan:   "#0db9d7"
        property color colBlue:   "#7aa2f7"
        property color colYellow: "#e0af68"
        property color colGreen:  "#9ece6a"
        property color colRed:    "#f7768e"
        property color colPurple: "#bb9af7"
        property string font:     "JetBrainsMono Nerd Font"
        property int    fsize:    13

        property int    cpuUsage:    0
        property int    memUsage:    0
        property int    batLevel:    100
        property bool   batCharging: false
        property string wifiSSID:    "..."

        property var lastCpuIdle:  0
        property var lastCpuTotal: 0

        property bool sessionOpen: false
    }

    // ══════════════════════════════════════════════════════
    // SYSTEM PROCESSES
    // ══════════════════════════════════════════════════════
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p     = data.trim().split(/\s+/)
                var idle  = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
                if (g.lastCpuTotal > 0) {
                    var dT = total - g.lastCpuTotal
                    var dI = idle  - g.lastCpuIdle
                    g.cpuUsage = dT > 0 ? Math.round(100 * (1 - dI / dT)) : 0
                }
                g.lastCpuTotal = total
                g.lastCpuIdle  = idle
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p = data.trim().split(/\s+/)
                g.memUsage = Math.round(100 * (parseInt(p[2]) || 0) / (parseInt(p[1]) || 1))
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: batProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 100"]
        stdout: SplitParser {
            onRead: data => { if (data.trim()) g.batLevel = parseInt(data.trim()) }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: batStatusProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo Discharging"]
        stdout: SplitParser {
            onRead: data => { g.batCharging = data.trim() === "Charging" }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^sim' | cut -d: -f2 | head -1"]
        stdout: SplitParser {
            onRead: data => { g.wifiSSID = data.trim() !== "" ? data.trim() : "Offline" }
        }
        Component.onCompleted: running = true
    }

    // Workspace Process Switch
    Process {
        id: wsProc
        running: false
    }

    // Session Process
    Process { id: lockProc
                        command: ["loginctl", "lock-session"]
                      running: false }
    Process { id: suspendProc
                     command: ["loginctl", "suspend"]
                          running: false }
    Process { id: rebootProc
                      command: ["loginctl", "reboot"]
                           running: false }
    Process { id: shutdownProc
                    command: ["loginctl", "poweroff"]
                         running: false }
    Process { id: logoutProc
                      command: ["sh", "-c", "kill -9 -1"]
                    running: false }

    Timer {
        interval: 2000
                    running: true
                    repeat: true
        onTriggered: {
            cpuProc.running       = true
            memProc.running       = true
            batProc.running       = true
            batStatusProc.running = true
            wifiProc.running      = true
        }
    }

    // ══════════════════════════════════════════════════════
    // PRINCIPAL BAR
    // ══════════════════════════════════════════════════════
    PanelWindow {
        id: bar
        anchors.top:   true
        anchors.left:  true
        anchors.right: true
        margins.right: 10
        margins.left: 10
        margins.top: 10
        implicitHeight: 40
        color: g.colBg

        RowLayout {
            anchors.fill:    parent
            anchors.margins: 6
            spacing: 6

            // ── Launcher ──────────────────────────────────
            Rectangle {
                width: 26
                    height: 26
                    radius: 6
                color: launchMa.containsMouse ? Qt.lighter(g.colPurple, 1.3) : g.colPurple

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font { family: g.font
                    pixelSize: 10 }
                    color: g.colBg
                }
                MouseArea {
                    id: launchMa
                    anchors.fill: parent
                    hoverEnabled: true
                    // Abre/fecha o launcher nativo (antes chamava o "fuzzel").
                    onClicked: appLauncher.toggle()
                }
            }

            Rectangle { width: 1
                    height: 18
                    color: g.colMuted }

            // ── Workspaces ────────────────────────────────
            Repeater {
                model: 10
                Rectangle {
                    required property int index
                    property int  wsId:     index + 1
                    property var  ws:       Hyprland.workspaces.values.find(w => w.id === wsId)
                    property bool isActive: Hyprland.focusedWorkspace !== null &&
                                            Hyprland.focusedWorkspace.id === wsId

                    width: 22
                    height: 22
                    radius: 4
                    color: isActive
                        ? g.colPurple
                        : (ws ? Qt.rgba(0.48, 0.64, 0.97, 0.25) : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: parent.wsId
                        color: parent.isActive ? g.colBg
                             : (parent.ws      ? g.colBlue : g.colMuted)
                        font { family: g.font
                    pixelSize: g.fsize
                    bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            wsProc.command = ["hyprctl", "dispatch", "workspace", wsId.toString()]
                            wsProc.running = true
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // ── CPU ───────────────────────────────────────
            RowLayout {
                spacing: 3
                Text { text: " "
                    font { family: g.font
                    pixelSize: g.fsize + 1 }
                    color: g.colYellow }
                Text {
                    text: g.cpuUsage + "%"
                    font { family: g.font
                    pixelSize: g.fsize }
                    color: g.cpuUsage > 80 ? g.colRed : g.cpuUsage > 50 ? g.colYellow : g.colGreen
                }
            }

            Rectangle { width: 1
                    height: 18
                    color: g.colMuted }

            // ── RAM ───────────────────────────────────────
            RowLayout {
                spacing: 3
                Text { text: ""
                    font { family: g.font
                    pixelSize: g.fsize + 1 }
                    color: g.colCyan }
                Text {
                    text: g.memUsage + "%"
                    font { family: g.font
                    pixelSize: g.fsize }
                    color: g.memUsage > 80 ? g.colRed : g.memUsage > 60 ? g.colYellow : g.colCyan
                }
            }

            Rectangle { width: 1
                    height: 18
                    color: g.colMuted }

            // ── Wi-Fi ─────────────────────────────────────
            RowLayout {
                spacing: 3
                Text {
                    text: g.wifiSSID === "Offline" ? "󰤭 " : "󰤨 "
                    font { family: g.font
                    pixelSize: g.fsize + 1 }
                    color: g.wifiSSID === "Offline" ? g.colRed : g.colBlue
                }
                Text { text: g.wifiSSID
                    font { family: g.font
                    pixelSize: g.fsize }
                    color: g.colFg }
            }

            Rectangle { width: 1
                    height: 18
                    color: g.colMuted }

            // ── Battery ───────────────────────────────────
            RowLayout {
                spacing: 3
                Text {
                    text: g.batCharging ? "󰂄 "
                        : g.batLevel > 80 ? "󰁹 "
                        : g.batLevel > 60 ? "󰂀 "
                        : g.batLevel > 40 ? "󰁾 "
                        : g.batLevel > 20 ? "󰁼 "
                        : "󰁺 "
                    font { family: g.font
                    pixelSize: g.fsize + 1 }
                    color: g.batLevel < 20 ? g.colRed : g.batLevel < 50 ? g.colYellow : g.colGreen
                }
                Text {
                    text: g.batLevel + "%"
                    font { family: g.font
                    pixelSize: g.fsize }
                    color: g.batLevel < 20 ? g.colRed : g.batLevel < 50 ? g.colYellow : g.colGreen
                }
            }

            Rectangle { width: 1
                    height: 18
                    color: g.colMuted }

            // ── Clock ───────────────────────────────────
            Text {
                id: clock
                color: g.colBlue
                font { family: g.font
                    pixelSize: g.fsize
                    bold: true }
                text: Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm:ss")
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm:ss")
                }
            }

            Rectangle { width: 1
                    height: 18
                    color: g.colMuted }

            // ── Session Button ──────────────────────────────
            Rectangle {
                width: 26
                    height: 26
                    radius: 6
                color: sessBtnMa.containsMouse || g.sessionOpen
                    ? g.colRed
                    : Qt.rgba(0.97, 0.46, 0.56, 0.3)

                Text {
                    anchors.centerIn: parent
                    text: "⏻"
                    font.pixelSize: 14
                    color: g.colRed
                }
                MouseArea {
                    id: sessBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: g.sessionOpen = !g.sessionOpen
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════
    // SESSION POPUP 
    // ══════════════════════════════════════════════════════
    PanelWindow {
        id: sessionPopup
        visible: g.sessionOpen
        color: "transparent"

        // Cobre o ecrã inteiro para centralizar o menu e permitir
        // fechar clicando em qualquer ponto fora da caixa (igual ao launcher).
        anchors.top:    true
        anchors.bottom: true
        anchors.left:   true
        anchors.right:  true

        WlrLayershell.layer:     WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-session"
        // Pede foco de teclado exclusivo ao compositor enquanto o menu
        // está aberto, permitindo a navegação por teclado (setas/Enter/Esc).
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Ao abrir, repõe a seleção no topo e entrega o foco à caixa
        // para que as teclas sejam recebidas de imediato.
        onVisibleChanged: {
            if (visible) {
                sessionBox.currentIndex = 0
                sessionBox.forceActiveFocus()
            }
        }

        // Fundo escurecido / clique fora fecha
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            MouseArea {
                anchors.fill: parent
                onClicked: g.sessionOpen = false
            }
        }

        // ── Caixa central do menu de sessão ───────────────
        Rectangle {
            id: sessionBox
            anchors.centerIn: parent
            width:  220
            height: 232
            radius: 12
            color: Qt.darker(g.colBg, 1.4)
            border.color: g.colRed
            border.width: 2

            // Índice da opção atualmente selecionada (0..4). Usado tanto
            // pela navegação por teclado como para o destaque visual.
            property int currentIndex: 0

            // Processos correspondentes a cada opção, pela mesma ordem
            // em que aparecem no menu (Lock, Suspend, Reboot, Shutdown, Logout).
            readonly property var sessionActions: [
                lockProc, suspendProc, rebootProc, shutdownProc, logoutProc
            ]

            // Executa a opção atualmente selecionada e fecha o menu.
            function activateSelected() {
                g.sessionOpen = false
                sessionActions[currentIndex].running = true
            }

            // ── Navegação por teclado ─────────────────────────
            // Recebe foco para captar as teclas (ver forceActiveFocus
            // disparado no onVisibleChanged do PanelWindow).
            focus: true
            Keys.onUpPressed:     currentIndex = (currentIndex - 1 + sessionActions.length) % sessionActions.length
            Keys.onDownPressed:   currentIndex = (currentIndex + 1) % sessionActions.length
            Keys.onEscapePressed: g.sessionOpen = false
            Keys.onReturnPressed: activateSelected()
            Keys.onEnterPressed:  activateSelected()

            // Impede que o clique dentro da caixa feche o menu
            MouseArea { anchors.fill: parent }

            ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 10
            spacing: 4

            // Lock
            Rectangle {
                Layout.fillWidth: true
                    height: 36
                    radius: 6
                color: (ma0.containsMouse || sessionBox.currentIndex === 0) ? Qt.rgba(0.48, 0.64, 0.97, 0.2) : "transparent"
                RowLayout { anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 8
                    Text { text: "󰌾"
                    font { family: g.font
                    pixelSize: 16 }
                    color: g.colBlue }
                    Text { text: "Lock"
                    font { family: g.font
                    pixelSize: g.fsize }
                    color: g.colFg }
                }
                MouseArea { id: ma0
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: sessionBox.currentIndex = 0
                    onClicked: { g.sessionOpen = false
                    lockProc.running = true } }
            }

            // Suspend
            Rectangle {
                Layout.fillWidth: true
                    height: 36
                    radius: 6
                color: (ma1.containsMouse || sessionBox.currentIndex === 1) ? Qt.rgba(0.88, 0.69, 0.41, 0.2) : "transparent"
                RowLayout { anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 8
                    Text { text: "󰒲"
                    font { family: g.font
                    pixelSize: 16 }
                    color: g.colYellow }
                    Text { text: "Suspend"
                    font { family: g.font
                    pixelSize: g.fsize }
                    color: g.colFg }
                }
                MouseArea { id: ma1
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: sessionBox.currentIndex = 1
                    onClicked: { g.sessionOpen = false
                    suspendProc.running = true } }
            }

            // Reboot
            Rectangle {
                Layout.fillWidth: true
                    height: 36
                    radius: 6
                color: (ma2.containsMouse || sessionBox.currentIndex === 2) ? Qt.rgba(0.88, 0.69, 0.41, 0.2) : "transparent"
                RowLayout { anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 8
                    Text { text: "󰑓"
                    font { family: g.font
                    pixelSize: 16 }
                    color: g.colYellow }
                    Text { text: "Reboot"
                    font { family: g.font
                    pixelSize: g.fsize }
                    color: g.colFg }
                }
                MouseArea { id: ma2
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: sessionBox.currentIndex = 2
                    onClicked: { g.sessionOpen = false
                    rebootProc.running = true } }
            }

            // Shutdown
            Rectangle {
                Layout.fillWidth: true
                    height: 36
                    radius: 6
                color: (ma3.containsMouse || sessionBox.currentIndex === 3) ? Qt.rgba(0.97, 0.46, 0.56, 0.2) : "transparent"
                RowLayout { anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 8
                    Text { text: "󰐥"
                    font { family: g.font
                    pixelSize: 16 }
                    color: g.colRed }
                    Text { text: "Shutdown"
                    font { family: g.font
                    pixelSize: g.fsize }
                    color: g.colFg }
                }
                MouseArea { id: ma3
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: sessionBox.currentIndex = 3
                    onClicked: { g.sessionOpen = false
                    shutdownProc.running = true } }
            }

            // Logout
            Rectangle {
                Layout.fillWidth: true
                    height: 36
                    radius: 6
                color: (ma4.containsMouse || sessionBox.currentIndex === 4) ? Qt.rgba(0.27, 0.29, 0.42, 0.5) : "transparent"
                RowLayout { anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 8
                    Text { text: "󰍃"
                    font { family: g.font
                    pixelSize: 16 }
                    color: g.colMuted }
                    Text { text: "Logout"
                    font { family: g.font
                    pixelSize: g.fsize }
                    color: g.colFg }
                }
                MouseArea { id: ma4
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: sessionBox.currentIndex = 4
                    onClicked: { g.sessionOpen = false
                    logoutProc.running = true } }
            }
            }
        }
    }
}
