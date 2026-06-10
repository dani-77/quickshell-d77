// ══════════════════════════════════════════════════════
// LockContext.qml
// Estado partilhado + autenticação PAM do lockscreen.
// Baseado no exemplo oficial do quickshell-examples, adaptado
// ao quickshell-d77 (ver lockscreen/README.md).
//
// Mantém o estado num único sítio para que todas as "lock
// surfaces" (uma por monitor) partilhem o mesmo texto/estado.
// ══════════════════════════════════════════════════════
import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    // Emitido quando a autenticação PAM tem sucesso.
    signal unlocked()
    // Emitido quando a autenticação PAM falha.
    signal failed()

    // ── Estado partilhado entre as surfaces ───────────────
    property string currentText: ""
    property bool   unlockInProgress: false
    property bool   showFailure: false

    // Limpa a mensagem de falha assim que o utilizador volta a escrever.
    onCurrentTextChanged: showFailure = false

    // ── Tenta desbloquear validando a password via PAM ────
    function tryUnlock() {
        if (currentText === "") return
        root.unlockInProgress = true
        pam.start()
    }

    PamContext {
        id: pam

        // É recomendável ter uma config PAM própria para o quickshell,
        // pois a do sistema pode não corresponder ao que a interface
        // espera. Este exemplo só suporta passwords.
        configDirectory: "pam"
        config: "password.conf"

        // O pam_unix pede uma resposta para o prompt da password.
        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText)
            }
        }

        // O pam_unix não envia mensagens importantes — basta-nos o estado final.
        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked()
            } else {
                root.currentText = ""
                root.showFailure = true
                root.failed()
            }
            root.unlockInProgress = false
        }
    }
}
