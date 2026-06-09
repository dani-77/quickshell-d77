# Atalhos globais (Hyprland) — quickshell-d77

Este documento explica como ligar os **global shortcuts** do Quickshell a
keybinds do Hyprland (testado com **Hyprland 0.55**), tanto no formato nativo
(`hyprland.conf` / hyprlang) como em configurações geradas via **Lua**.

O `shell.qml` regista dois global shortcuts:

| Shortcut (Quickshell) | Ação                                   | Keybind sugerido    |
|-----------------------|----------------------------------------|---------------------|
| `quickshell:launcher` | Abre/fecha o launcher de aplicativos   | `SUPER + D`         |
| `quickshell:session`  | Abre/fecha o menu de sessão            | `SUPER + SHIFT + E` |

---

## 1. Como funcionam os global shortcuts do Quickshell

No `shell.qml`, cada atalho é declarado com um componente `GlobalShortcut`
(do módulo `Quickshell.Hyprland`):

```qml
GlobalShortcut {
    appid: "quickshell"   // prefixo do bind (default: "quickshell")
    name: "launcher"      // identificador do atalho
    description: "Abre/fecha o launcher de aplicativos"
    onPressed: appLauncher.toggle()
}
```

O Quickshell **regista** estes atalhos no Hyprland através do protocolo
`hyprland-global-shortcuts-v1`. Do lado do Hyprland, tu ligas uma tecla ao
atalho usando o **dispatcher `global`** com o argumento `<appid>:<name>`:

```
bind = SUPER, D, global, quickshell:launcher
```

> ⚠️ **Importante:** o atalho só fica disponível **enquanto o Quickshell
> estiver a correr** (`qs -p ~/.config/quickshell/shell.qml`). É o Quickshell
> que regista o `appid:name`; o Hyprland apenas o invoca. Se o Quickshell não
> estiver ativo, o `bind ... global ...` simplesmente não faz nada.

---

## 2. Configuração nativa (`hyprland.conf` / hyprlang)

Esta é a forma canónica e que **funciona sempre**, independentemente de
usares ou não Lua. Adiciona ao teu `~/.config/hypr/hyprland.conf`:

```ini
# ── Atalhos do quickshell-d77 ─────────────────────────────
# Launcher de aplicativos (SUPER + D)
bind = SUPER, D, global, quickshell:launcher

# Menu de sessão: lock / suspend / reboot / shutdown / logout (SUPER + SHIFT + E)
bind = SUPER SHIFT, E, global, quickshell:session
```

Formato geral:

```
bind = <modificadores>, <tecla>, global, <appid>:<name>
```

- `<modificadores>`: `SUPER`, `SUPER SHIFT`, `CTRL ALT`, etc. (separados por espaço)
- `<tecla>`: `D`, `E`, `Return`, ...
- `global`: o **dispatcher** (obrigatório para global shortcuts)
- `<appid>:<name>`: tem de bater certo com o `appid` e `name` do `GlobalShortcut`
  no `shell.qml` → aqui `quickshell:launcher` e `quickshell:session`

Depois de editar, recarrega o Hyprland:

```bash
hyprctl reload
```

---

## 3. Configuração em Lua (Hyprland 0.55)

O Hyprland lê o seu ficheiro em **hyprlang**, não em Lua nativamente. Quando se
fala de "config em Lua" no Hyprland 0.55, normalmente trata-se de um dos casos
abaixo. Em **todos** eles, o objetivo final é produzir a mesma linha
`bind = ..., global, quickshell:...`.

### 3a. Lua que gera/escreve o `hyprland.conf`

Se usas um script Lua que monta o `hyprland.conf` (padrão comum em dotfiles),
basta emitir as linhas de `bind`. Exemplo:

```lua
-- keybinds.lua — gera as linhas de bind do quickshell-d77
local binds = {
  -- { mods,          key, dispatcher, arg }
  { "SUPER",        "D", "global", "quickshell:launcher" },
  { "SUPER SHIFT",  "E", "global", "quickshell:session"  },
}

local lines = {}
for _, b in ipairs(binds) do
  lines[#lines + 1] = string.format(
    "bind = %s, %s, %s, %s", b[1], b[2], b[3], b[4]
  )
end

-- Escreve no final do hyprland.conf
local path = os.getenv("HOME") .. "/.config/hypr/hyprland.conf"
local f = assert(io.open(path, "a"))
f:write("\n# quickshell-d77 global shortcuts\n")
f:write(table.concat(lines, "\n") .. "\n")
f:close()
```

Resultado escrito no `hyprland.conf`:

```ini
bind = SUPER, D, global, quickshell:launcher
bind = SUPER SHIFT, E, global, quickshell:session
```

### 3b. `hyprctl keyword` a partir de Lua (em runtime)

Também podes registar os binds em tempo de execução, sem editar ficheiros,
chamando `hyprctl keyword` a partir do Lua:

```lua
-- aplica os binds imediatamente na sessão atual
local cmds = {
  'hyprctl keyword bind "SUPER, D, global, quickshell:launcher"',
  'hyprctl keyword bind "SUPER SHIFT, E, global, quickshell:session"',
}
for _, c in ipairs(cmds) do
  os.execute(c)
end
```

> Nota: binds aplicados via `hyprctl keyword` valem só para a sessão atual.
> Para serem permanentes, gera-os no `hyprland.conf` (secção 3a) ou usa
> `source = ` para incluir um ficheiro gerado.

### 3c. `source` de um ficheiro gerado pelo Lua

Mantém o `hyprland.conf` limpo e deixa o Lua gerar um ficheiro separado:

No `hyprland.conf`:
```ini
source = ~/.config/hypr/generated/quickshell-binds.conf
```

E o teu script Lua escreve `~/.config/hypr/generated/quickshell-binds.conf`
com as linhas de `bind` da secção 3a.

---

## 4. Como testar se os shortcuts estão registados

### Passo 1 — Confirmar que o Quickshell está a correr

```bash
qs -p ~/.config/quickshell/shell.qml &
# ou, se já tiveres um serviço/launch a tratar disso, confirma o processo:
pgrep -af quickshell
```

### Passo 2 — Listar os global shortcuts registados

```bash
hyprctl globalshortcuts
```

Deves ver algo como:

```
quickshell:launcher -> Abre/fecha o launcher de aplicativos
quickshell:session -> Abre/fecha o menu de sessão (lock/suspend/reboot/...)
```

- Se **aparecem** → o Quickshell registou os atalhos corretamente. ✅
- Se **não aparecem** → o Quickshell não está a correr, ou o `shell.qml` em
  uso não é o deste repositório (ou os `GlobalShortcut` não foram carregados).

### Passo 3 — Confirmar que os binds existem no Hyprland

```bash
hyprctl binds | grep -A4 global
```

Procura entradas cujo `dispatcher: global` e `arg: quickshell:launcher` /
`quickshell:session`.

### Passo 4 — Testar na prática

- Pressiona `SUPER + D` → o launcher deve abrir/fechar.
- Pressiona `SUPER + SHIFT + E` → o menu de sessão deve abrir/fechar.

---

## 5. Resolução de problemas (o `SUPER+D` não funciona)

| Sintoma | Causa provável | Solução |
|---------|----------------|---------|
| `hyprctl globalshortcuts` está vazio | Quickshell não está a correr | Inicia `qs -p ~/.config/quickshell/shell.qml` |
| Aparece em `globalshortcuts` mas a tecla não faz nada | Falta o `bind ... global ...` no Hyprland | Adiciona o bind (secção 2) e faz `hyprctl reload` |
| A tecla faz **outra** coisa | `SUPER+D` já está atribuído a outro bind | Remove/altera o bind conflituoso, ou usa outra tecla |
| Deixou de funcionar após reiniciar | Bind aplicado só via `hyprctl keyword` | Torna-o permanente no `hyprland.conf` (secção 3a/3c) |
| Erro de "duplicate appid+name" / crash | Dois `GlobalShortcut` com o mesmo `appid`+`name` (ex.: 2 instâncias do Quickshell) | Garante uma só instância; cada atalho tem `name` único |

Verifica também conflitos de keybind:

```bash
hyprctl binds | grep -i "D$"          # binds ligados à tecla D
```

E confirma a versão do Hyprland:

```bash
hyprctl version
```

---

## 6. Resumo rápido

1. Garante o Quickshell a correr: `qs -p ~/.config/quickshell/shell.qml`
2. Adiciona ao `hyprland.conf` (ou gera via Lua):
   ```ini
   bind = SUPER, D, global, quickshell:launcher
   bind = SUPER SHIFT, E, global, quickshell:session
   ```
3. `hyprctl reload`
4. Verifica: `hyprctl globalshortcuts`
5. Testa `SUPER+D` e `SUPER+SHIFT+E`.
