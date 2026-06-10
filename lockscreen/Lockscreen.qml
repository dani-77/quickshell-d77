// ══════════════════════════════════════════════════════
// Lockscreen.qml
// Componente principal do módulo lockscreen. Encapsula o
// WlSessionLock + o LockContext e expõe uma API pública
// (lock/unlock/toggle) pronta a ser ligada ao IPC.
//
// Uso no shell.qml:
//   import "lockscreen"
//   Lockscreen { id: lockScreen }
//   lockScreen.lock()    // bloqueia o ecrã
//   lockScreen.unlock()  // desbloqueia (sem password)
//
// Ver lockscreen/README.md para detalhes.
// ══════════════════════════════════════════════════════
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    // ══════════════════════════════════════════════════════
    // TEMA (repassado às surfaces — paleta Tokyo Night)
    // ══════════════════════════════════════════════════════
    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colMuted:  "#444b6a"
    property color colBlue:   "#7aa2f7"
    property color colPurple: "#bb9af7"
    property color colRed:    "#f7768e"
    property string font:     "JetBrainsMono Nerd Font"
    property int    fsize:    13

    // ── Estado ────────────────────────────────────────────
    // true enquanto o ecrã está bloqueado.
    readonly property alias locked: lock.locked

    // ── Sinais ────────────────────────────────────────────
    // Emitidos quando o estado de bloqueio muda.
    signal didLock()
    signal didUnlock()

    // ══════════════════════════════════════════════════════
    // API pública (chamável via IPC)
    // ══════════════════════════════════════════════════════
    // Bloqueia o ecrã. A sessão fica trancada até a password
    // ser validada via PAM (ou unlock() ser chamado).
    function lock() {
        if (lock.locked) return
        lockContext.currentText      = ""
        lockContext.showFailure      = false
        lockContext.unlockInProgress = false
        lock.locked = true
        root.didLock()
    }

    // Desbloqueia o ecrã imediatamente, sem pedir password.
    // Útil para automações/IPC a partir de mecanismos já
    // autenticados. Para desbloqueio normal, o utilizador
    // escreve a password no LockSurface.
    function unlock() {
        if (!lock.locked) return
        lock.locked = false
        lockContext.currentText      = ""
        lockContext.showFailure      = false
        lockContext.unlockInProgress = false
        root.didUnlock()
    }

    // Alterna entre bloqueado/desbloqueado.
    function toggle() {
        if (lock.locked) unlock()
        else             lock()
    }

    // ══════════════════════════════════════════════════════
    // CONTEXTO PARTILHADO + AUTENTICAÇÃO
    // ══════════════════════════════════════════════════════
    LockContext {
        id: lockContext

        // Quando o PAM valida a password, desbloqueia a sessão.
        onUnlocked: {
            // É preciso libertar o lock antes de qualquer coisa, senão o
            // compositor mostra um lock de fallback com que não dá para
            // interagir.
            lock.locked = false
            root.didUnlock()
        }
    }

    // ══════════════════════════════════════════════════════
    // SESSÃO BLOQUEADA (uma surface por monitor)
    // ══════════════════════════════════════════════════════
    WlSessionLock {
        id: lock
        // Começa desbloqueado; o shell aciona via lock().
        locked: false

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext

                // Repassa o tema.
                colBg:     root.colBg
                colFg:     root.colFg
                colMuted:  root.colMuted
                colBlue:   root.colBlue
                colPurple: root.colPurple
                colRed:    root.colRed
                font:      root.font
                fsize:     root.fsize
            }
        }
    }
}
