import QtQuick
import "../Services" as Services

// Fundo decorativo mostrado apenas enquanto não houver nenhum wallpaper
// definido pelo utilizador (WallpaperState.hasWallpaper === false).
// Assim que um wallpaper é escolhido no picker (Wallpaper.qml), isto
// esconde-se sozinho, de forma reativa, sem reiniciar o Quickshell.
// Inspirado no DankBackdrop do DankMaterialShell.

Item {
    id: root
    clip: true

    // ══════════════════════════════════════════════════════
    // THEME (Tokyo Night) — mirrors Wallpaper.qml / Launcher.qml
    // ══════════════════════════════════════════════════════
    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colPurple: "#bb9af7"

    // Logo mostrado no canto inferior esquerdo. Troca este ficheiro
    // (mantém o nome ou ajusta este caminho) pelo teu logo d77 definitivo.
    property string logoSource: "assets/d77-logo.svg"

    visible: !Services.WallpaperState.hasWallpaper

    Rectangle {
        anchors.fill: parent
        color: root.colBg
    }

    // Chevron 1 (mais escuro, atrás)
    Rectangle {
        x: root.width * 0.68
        y: -root.height * 0.3
        width: root.width * 0.8
        height: root.height * 1.6
        color: Qt.darker(root.colPurple, 2.2)
        rotation: 35
    }

    // Chevron 2 (colPurple, sobreposto à frente)
    Rectangle {
        x: root.width * 0.84
        y: -root.height * 0.2
        width: root.width * 0.4
        height: root.height * 1.3
        color: Qt.darker(root.colPurple, 1.4)
        rotation: 35
    }

    // Logo no canto inferior esquerdo, a ~25% de opacidade.
    Image {
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 48
        width:  180
        height: width
        fillMode:     Image.PreserveAspectFit
        smooth:       true
        mipmap:       true
        asynchronous: true
        source:  Qt.resolvedUrl(root.logoSource)
        opacity: 0.25
        visible: status === Image.Ready
    }
}
