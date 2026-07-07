import QtQuick
import Quickshell
import Quickshell.Wayland

// Uma instância por ecrã (Variants sobre Quickshell.screens). Fica na
// camada "Bottom" do layer-shell — logo ACIMA da camada "Background"
// onde o hyprpaper desenha o wallpaper real. Isto evita dois clientes
// wlr-layer-shell a disputar a mesma camada (o que causaria flicker/
// z-order imprevisível).
//
// Quando não há wallpaper: só se vê isto (o Backdrop).
// Quando há wallpaper: o hyprpaper desenha por baixo, e o Backdrop
// esconde-se (visible: false lá dentro), deixando ver o wallpaper real.

Variants {
    id: root

    // ══════════════════════════════════════════════════════
    // THEME (Tokyo Night) — sobreposto a partir de shell.qml (g.*)
    // ══════════════════════════════════════════════════════
    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colPurple: "#bb9af7"

    model: Quickshell.screens

    PanelWindow {
        id: panel
        required property var modelData
        screen: modelData

        WlrLayershell.layer:         WlrLayer.Bottom
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace:     "quickshell-backdrop"

        anchors {
            top:    true
            bottom: true
            left:   true
            right:  true
        }

        color: "transparent"

        // Não intercetar cliques/foco — isto é só decoração de fundo.
        mask: Region {
            item: Item {}
        }

        Backdrop {
            anchors.fill: parent
            colBg:     root.colBg
            colFg:     root.colFg
            colPurple: root.colPurple
        }
    }
}
