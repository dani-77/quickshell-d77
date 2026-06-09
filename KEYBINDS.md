# Atalhos (Hyprland) — quickshell-d77

Este documento explica como acionar o **launcher** e o **menu de sessão** do
quickshell-d77 a partir de keybinds do Hyprland (testado com **Hyprland 0.46+**),
tanto no formato nativo (`hyprland.conf` / hyprlang) como em configurações
geradas/escritas via **Lua**.

Existem **duas** formas de o fazer:

1. **IPC (recomendado)** — o Hyprland chama `qs ipc call <target> <função>` com um
   simples `exec`. É a forma mais fiável, em especial com configs em Lua, e a que
   este repositório passa a usar por omissão.
2. **Global shortcuts (fallback)** — o Quickshell regista atalhos via o protocolo
   `hyprland-global-shortcuts-v1` e o Hyprland liga-os com o dispatcher `global`.
   Mantido como alternativa, mas é mais frágil.

| Ação                                 | Target / Função IPC          | Keybind sugerido    |
|--------------------------------------|------------------------------|---------------------|
| Abre/fecha o launcher de aplicativos | `launcher` → `toggle`        | `SUPER + D`         |
| Abre/fecha o menu de sessão          | `session`  → `toggle`        | `SUPER + SHIFT + E` |

Cada target expõe três funções: `toggle`, `open` e `close`.

---

## 1. IPC — a forma recomendada

### 1.1. Como funciona

No `shell.qml` estão declarados dois `IpcHandler` (do módulo `Quickshell.Io`):

```qml
import Quickshell.Io

IpcHandler {
    target: "launcher"
    function toggle(): void { appLauncher.toggle() }
    function open():   void { appLauncher.open() }
    function close():  void { appLauncher.close() }
}

IpcHandler {
    target: "session"
    function toggle(): void { g.sessionOpen = !g.sessionOpen }
    function open():   void { g.sessionOpen = true }
    function close():  void { g.sessionOpen = false }
}
```

Enquanto o Quickshell estiver a correr, qualquer processo pode invocar estas
funções a partir da linha de comandos:

```bash
qs ipc call launcher toggle     # alterna o launcher
qs ipc call launcher open       # abre o launcher
qs ipc call launcher close      # fecha o launcher

qs ipc call session toggle      # alterna o menu de sessão
qs ipc call session open        # abre o menu de sessão
qs ipc call session close       # fecha o menu de sessão
```

> 💡 Se correres o Quickshell com mais do que uma instância/config, podes
> direcionar o IPC com `qs -c <config> ipc call ...` ou via `--pid`. Para o caso
> normal (uma instância), `qs ipc call ...` basta.

Para inspecionar o que está exposto:

```bash
qs ipc show          # lista todos os targets e funções disponíveis
```

### 1.2. hyprland.conf (hyprlang)

Adiciona ao teu `~/.config/hypr/hyprland.conf`:

```ini
# ── quickshell-d77 (via IPC) ──────────────────────────────
# Launcher de aplicativos (SUPER + D)
bind = SUPER, D, exec, qs ipc call launcher toggle

# Menu de sessão: lock / suspend / reboot / shutdown / logout (SUPER + SHIFT + E)
bind = SUPER SHIFT, E, exec, qs ipc call session toggle
```

Formato geral:

```
bind = <modificadores>, <tecla>, exec, qs ipc call <target> <função>
```

Depois de editar, recarrega o Hyprland:

```bash
hyprctl reload
```

### 1.3. Configuração em Lua (Hyprland 0.46+)

O Hyprland lê a sua config em **hyprlang**. Quando se fala de "config em Lua",
trata-se normalmente de um script Lua que **gera** o `hyprland.conf` (ou um
ficheiro incluído via `source`), ou que aplica binds em runtime. Em todos os
casos o objetivo é produzir linhas `bind = ..., exec, qs ipc call ...`.

#### 3a. Lua que gera/escreve o `hyprland.conf`

```lua
-- keybinds.lua — gera as linhas de bind do quickshell-d77 (via IPC)
local binds = {
  -- { mods,         key, "qs ipc call <target> <função>" }
  { "SUPER",       "D", "qs ipc call launcher toggle" },
  { "SUPER SHIFT", "E", "qs ipc call session toggle"  },
}

local lines = {}
for _, b in ipairs(binds) do
  lines[#lines + 1] = string.format("bind = %s, %s, exec, %s", b[1], b[2], b[3])
end

-- Escreve no final do hyprland.conf
local path = os.getenv("HOME") .. "/.config/hypr/hyprland.conf"
local f = assert(io.open(path, "a"))
f:write("\n# quickshell-d77 (IPC)\n")
f:write(table.concat(lines, "\n") .. "\n")
f:close()
```

Resultado escrito no `hyprland.conf`:

```ini
bind = SUPER, D, exec, qs ipc call launcher toggle
bind = SUPER SHIFT, E, exec, qs ipc call session toggle
```

#### 3b. `init.lua` (frameworks de dotfiles em Lua)

Se usas um wrapper/framework cujo `init.lua` define keybinds através de uma
tabela (padrão comum em dotfiles), o `exec` mapeia diretamente para o comando IPC.
O exemplo abaixo é genérico — adapta os nomes dos campos ao teu framework:

```lua
-- ~/.config/hypr/init.lua
local hypr = require("hypr")   -- depende do teu framework

hypr.bind({
  { mods = "SUPER",       key = "D", dispatcher = "exec", arg = "qs ipc call launcher toggle" },
  { mods = "SUPER SHIFT", key = "E", dispatcher = "exec", arg = "qs ipc call session toggle"  },
})
```

Se o teu `init.lua` apenas emite strings de config, usa a abordagem 3a. Se aplica
binds em runtime, vê 3c.

#### 3c. `hyprctl keyword` a partir de Lua (runtime)

```lua
-- aplica os binds imediatamente na sessão atual (não persiste)
local cmds = {
  'hyprctl keyword bind "SUPER, D, exec, qs ipc call launcher toggle"',
  'hyprctl keyword bind "SUPER SHIFT, E, exec, qs ipc call session toggle"',
}
for _, c in ipairs(cmds) do
  os.execute(c)
end
```

> Nota: binds aplicados via `hyprctl keyword` valem só para a sessão atual.
> Para serem permanentes, gera-os no `hyprland.conf` (3a) ou usa `source =`.

#### 3d. `source` de um ficheiro gerado pelo Lua

Mantém o `hyprland.conf` limpo e deixa o Lua gerar um ficheiro separado:

No `hyprland.conf`:
```ini
source = ~/.config/hypr/generated/quickshell-binds.conf
```

E o script Lua escreve `~/.config/hypr/generated/quickshell-binds.conf` com as
linhas de `bind` da secção 3a.

---

## 2. Global shortcuts (fallback)

O `shell.qml` continua a registar dois `GlobalShortcut` (módulo
`Quickshell.Hyprland`), como alternativa ao IPC:

```qml
GlobalShortcut {
    appid: "quickshell"   // prefixo do bind (default: "quickshell")
    name: "launcher"      // identificador do atalho
    description: "Abre/fecha o launcher de aplicativos"
    onPressed: appLauncher.toggle()
}
```

Do lado do Hyprland, liga-se uma tecla ao atalho com o **dispatcher `global`** e o
argumento `<appid>:<name>`:

```ini
# ── quickshell-d77 (via global shortcuts) ─────────────────
bind = SUPER, D, global, quickshell:launcher
bind = SUPER SHIFT, E, global, quickshell:session
```

Formato geral:

```
bind = <modificadores>, <tecla>, global, <appid>:<name>
```

> ⚠️ **Importante:** o atalho só fica disponível **enquanto o Quickshell
> estiver a correr**. É o Quickshell que regista o `appid:name`; o Hyprland
> apenas o invoca. Em configs geradas em Lua, este caminho costuma ser mais
> frágil que o IPC — por isso a recomendação é a secção 1.

---

## 3. Como testar

### Passo 1 — Confirmar que o Quickshell está a correr

```bash
qs -p ~/.config/quickshell/shell.qml &
# ou confirma o processo:
pgrep -af quickshell
```

### Passo 2 (IPC) — Listar e testar os targets expostos

```bash
qs ipc show                       # deve listar os targets "launcher" e "session"
qs ipc call launcher toggle       # o launcher deve abrir/fechar
qs ipc call session toggle        # o menu de sessão deve abrir/fechar
```

### Passo 2 (global shortcuts) — Listar os atalhos registados

```bash
hyprctl globalshortcuts
```

Deves ver algo como:

```
quickshell:launcher -> Abre/fecha o launcher de aplicativos
quickshell:session -> Abre/fecha o menu de sessão (lock/suspend/reboot/...)
```

### Passo 3 — Confirmar os binds no Hyprland

```bash
hyprctl binds | grep -A4 -E "qs ipc call|global"
```

### Passo 4 — Testar na prática

- Pressiona `SUPER + D` → o launcher deve abrir/fechar.
- Pressiona `SUPER + SHIFT + E` → o menu de sessão deve abrir/fechar.

---

## 4. Resolução de problemas

| Sintoma | Causa provável | Solução |
|---------|----------------|---------|
| `qs ipc call ...` diz que não encontra o target | Quickshell não está a correr, ou usa outro `shell.qml` | Inicia `qs -p ~/.config/quickshell/shell.qml` e confirma com `qs ipc show` |
| `qs ipc show` não lista `launcher`/`session` | O `shell.qml` em uso não tem os `IpcHandler` | Garante que estás a usar o `shell.qml` deste repositório |
| A tecla não faz nada | Falta o `bind ... exec, qs ipc call ...` (ou `global ...`) | Adiciona o bind (secção 1.2 ou 2) e faz `hyprctl reload` |
| A tecla faz **outra** coisa | `SUPER+D` já está atribuído a outro bind | Remove/altera o bind conflituoso, ou usa outra tecla |
| Deixou de funcionar após reiniciar | Bind aplicado só via `hyprctl keyword` | Torna-o permanente no `hyprland.conf` (1.2 / 3a / 3d) |
| `hyprctl globalshortcuts` vazio (modo fallback) | Quickshell não está a correr | Inicia o Quickshell |

Verifica conflitos de keybind e a versão do Hyprland:

```bash
hyprctl binds | grep -i "D$"   # binds ligados à tecla D
hyprctl version
```

---

## 5. Resumo rápido (IPC)

1. Garante o Quickshell a correr: `qs -p ~/.config/quickshell/shell.qml`
2. Adiciona ao `hyprland.conf` (ou gera via Lua):
   ```ini
   bind = SUPER, D, exec, qs ipc call launcher toggle
   bind = SUPER SHIFT, E, exec, qs ipc call session toggle
   ```
3. `hyprctl reload`
4. Verifica: `qs ipc show`
5. Testa `SUPER+D` e `SUPER+SHIFT+E`.
