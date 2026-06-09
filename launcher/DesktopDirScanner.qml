// ══════════════════════════════════════════════════════
// DesktopDirScanner.qml
// Varre os diretórios padrão de aplicativos e devolve o
// conteúdo concatenado de todos os arquivos .desktop.
// ══════════════════════════════════════════════════════
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: scanner

    // ── Sinal emitido quando a varredura termina ──────────
    // raw: texto bruto com todos os .desktop concatenados,
    //      separados pelo delimitador ===DESKTOP_FILE_START===
    signal scanned(string raw)

    // ── Diretórios pesquisados (ordem de prioridade) ──────
    property var dirs: [
        Quickshell.env("HOME") + "/.local/share/applications",
        "/usr/local/share/applications",
        "/usr/share/applications"
    ]

    // Indica se uma varredura está em andamento
    readonly property bool scanning: proc.running

    // ── Dispara a varredura ───────────────────────────────
    function scan() {
        if (proc.running)
            return
        proc.command = ["sh", "-c", buildCommand()]
        proc.running = true
    }

    // ── Monta o comando shell de varredura ────────────────
    // Para cada diretório existente, percorre os *.desktop e
    // imprime um delimitador seguido do conteúdo do arquivo.
    function buildCommand() {
        var quoted = []
        for (var i = 0; i < dirs.length; i++)
            quoted.push("'" + String(dirs[i]).replace(/'/g, "'\\''") + "'")

        return "for d in " + quoted.join(" ") + "; do " +
               "[ -d \"$d\" ] || continue; " +
               "for f in \"$d\"/*.desktop; do " +
               "[ -f \"$f\" ] || continue; " +
               "printf '===DESKTOP_FILE_START===\\n'; " +
               "cat \"$f\"; printf '\\n'; " +
               "done; done"
    }

    // ── Processo que executa a varredura ──────────────────
    Process {
        id: proc
        running: false
        stdout: StdioCollector {
            onStreamFinished: scanner.scanned(text)
        }
    }
}
