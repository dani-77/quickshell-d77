# Módulo `lockscreen`

Lockscreen nativo em Quickshell/QML, baseado no exemplo oficial do
[`quickshell-examples`](https://github.com/quickshell-mirror/quickshell-examples/tree/master/lockscreen),
adaptado ao **quickshell-d77**: estrutura modular, paleta Tokyo Night e uma API
pública (`lock`/`unlock`/`toggle`) pronta a ligar ao **IPC**.

Autenticação por **password via PAM** (`pam_unix`). Usa o protocolo
`ext-session-lock-v1` do Wayland (`WlSessionLock`), por isso bloqueia de forma
segura — o compositor garante que nada fica acessível por baixo.

![sample](../sample.png)

## Conteúdo do módulo

| Arquivo            | Responsabilidade |
|--------------------|------------------|
| `Lockscreen.qml`   | Componente principal: encapsula `WlSessionLock` + `LockContext` e expõe `lock()`, `unlock()`, `toggle()` e a propriedade `locked`. |
| `LockContext.qml`  | Estado partilhado entre monitores + autenticação PAM (`PamContext`). |
| `LockSurface.qml`  | UI de cada monitor: relógio, data e campo de password (estilo Tokyo Night). |
| `pam/password.conf`| Config PAM dedicada (`auth required pam_unix.so`). |
| `qmldir`           | Definição do módulo (expõe os componentes acima). |

## Como funciona

```
Lockscreen ──contém──▶ WlSessionLock ──por monitor──▶ LockSurface
     │                                                     │
     └──────────────── LockContext (PAM) ◀─────────────────┘
```

1. `Lockscreen.lock()` define `WlSessionLock.locked = true`. O compositor tranca
   a sessão e mostra uma `LockSurface` em cada monitor.
2. O utilizador escreve a password; ao pressionar Enter (ou no botão **Unlock**),
   o `LockContext` valida-a através do PAM (`pam/password.conf`).
3. Em caso de sucesso, o `LockContext` emite `unlocked()` e o `Lockscreen`
   liberta o lock (`locked = false`). Em caso de falha, mostra "Incorrect password".

> ⚠️ A config PAM (`pam/password.conf`) é resolvida **relativamente** ao
> `LockContext.qml`. Mantém a pasta `pam/` dentro de `lockscreen/`.

## Instalação

A pasta `lockscreen/` deve ficar **ao lado** do seu `shell.qml`
(por padrão em `~/.config/quickshell/`):

```
~/.config/quickshell/
├── shell.qml
└── lockscreen/
    ├── Lockscreen.qml
    ├── LockContext.qml
    ├── LockSurface.qml
    ├── qmldir
    └── pam/
        └── password.conf
```

## Uso

No seu `shell.qml`, importe o módulo pelo caminho relativo e instancie o
`Lockscreen`:

```qml
import "lockscreen"

ShellRoot {
    Lockscreen { id: lockScreen }

    // Bloquear/desbloquear de qualquer lugar:
    // lockScreen.lock()
    // lockScreen.unlock()
}
```

### Acionar via IPC (recomendado)

O `shell.qml` já expõe um `IpcHandler` com o target `lockscreen`:

```bash
qs ipc call lockscreen lock      # bloqueia o ecrã
qs ipc call lockscreen unlock    # desbloqueia (sem password)
qs ipc call lockscreen toggle    # alterna
```

E no `hyprland.conf`:

```ini
bind = SUPER, L, exec, qs ipc call lockscreen lock
```

Ver [`KEYBINDS.md`](../KEYBINDS.md) para a configuração completa (incl. Lua).

## API pública do `Lockscreen`

| Membro       | Tipo     | Descrição |
|--------------|----------|-----------|
| `lock()`     | função   | Bloqueia o ecrã (pede password via PAM para desbloquear). |
| `unlock()`   | função   | Desbloqueia imediatamente, **sem** pedir password (p./ automações). |
| `toggle()`   | função   | Alterna entre bloqueado/desbloqueado. |
| `locked`     | `bool`   | (Read-only) `true` enquanto o ecrã está bloqueado. |
| `didLock()`  | sinal    | Emitido quando o ecrã é bloqueado. |
| `didUnlock()`| sinal    | Emitido quando o ecrã é desbloqueado. |
| `colBg` … `colRed` | `color` | Cores do tema (padrão: paleta Tokyo Night). |
| `font`, `fsize` | `string`/`int` | Fonte e tamanho base. |

## Personalização

Todas as propriedades de tema podem ser sobrescritas na instância:

```qml
Lockscreen {
    id: lockScreen
    colBg:     "#1a1b26"
    colPurple: "#bb9af7"
    fsize:     14
}
```

## Requisitos

- **Quickshell** com suporte a PAM (`Quickshell.Services.Pam`) e a Wayland
  session lock (`Quickshell.Wayland.WlSessionLock`).
- Um compositor Wayland que implemente `ext-session-lock-v1` (ex.: Hyprland).
- PAM configurado no sistema (o `pam_unix` valida a password do utilizador).
