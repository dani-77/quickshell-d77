// ══════════════════════════════════════════════════════
// AppLoader.qml
// Junta o DesktopDirScanner com o desktopParser.js para
// produzir uma lista de aplicativos pronta para uso.
// ══════════════════════════════════════════════════════
import QtQuick
import Quickshell
import "desktopParser.js" as Parser

Item {
    id: loader

    // ── Lista completa de apps (array de objetos JS) ──────
    // Cada item: { name, exec, icon, comment, categories,
    //              terminal, noDisplay, hidden, isApp }
    property var apps: []

    // Quantidade de apps carregados
    readonly property int count: apps.length

    // Indica se já houve ao menos um carregamento
    property bool ready: false

    // ── Sinais ────────────────────────────────────────────
    signal loaded()

    // ── Recarrega a lista de aplicativos ──────────────────
    function reload() {
        scanner.scan()
    }

    // ── Filtra os apps por uma query (delega ao parser) ───
    function filter(query) {
        return Parser.filterApps(loader.apps, query)
    }

    // ── Scanner que alimenta o parser ─────────────────────
    DesktopDirScanner {
        id: scanner
        onScanned: function (raw) {
            loader.apps  = Parser.parseEntries(raw)
            loader.ready = true
            loader.loaded()
        }
    }

    // Carrega assim que o componente fica pronto
    Component.onCompleted: reload()
}
