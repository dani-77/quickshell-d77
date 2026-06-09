# Módulo `launcher`

Launcher de aplicativos estilo **Rofi / Fuzzel**, escrito 100% em QML/Quickshell —
sem dependências externas. Ele varre os arquivos `.desktop` do sistema, exibe uma
janela flutuante centralizada com campo de busca e lista navegável por teclado, e
executa o aplicativo selecionado.

![sample](../sample.png)

## Conteúdo do módulo

| Arquivo                  | Responsabilidade |
|--------------------------|------------------|
| `Launcher.qml`           | Componente principal: janela (layer-shell `Overlay`), busca e lista de resultados. |
| `AppLoader.qml`          | Junta o scanner ao parser e expõe a lista de apps + `filter()`. |
| `DesktopDirScanner.qml`  | Varre os diretórios padrão e devolve o conteúdo bruto dos `.desktop`. |
| `desktopParser.js`       | Biblioteca JS que faz o parse dos `.desktop` e a filtragem. |
| `qmldir`                 | Definição do módulo (expõe os componentes acima). |
| `example-integration.qml`| Exemplo de como ativar o launcher a partir do `shell.qml`. |

## Como funciona

```
DesktopDirScanner  ──(texto bruto)──▶  desktopParser.js  ──(array de apps)──▶  AppLoader  ──▶  Launcher
```

1. **DesktopDirScanner** roda um `Process` que percorre, em ordem de prioridade:
   - `~/.local/share/applications`
   - `/usr/local/share/applications`
   - `/usr/share/applications`

   e concatena todos os `*.desktop` separados pelo delimitador `===DESKTOP_FILE_START===`.
2. **desktopParser.js** interpreta a seção `[Desktop Entry]`, limpa os *field codes*
   do `Exec` (`%U`, `%f`, ...), descarta entradas `NoDisplay`/`Hidden` e ordena por nome.
3. **AppLoader** mantém o array `apps` e oferece `reload()` e `filter(query)`.
4. **Launcher** renderiza a UI, faz a filtragem reativa conforme a busca e executa o
   app via `setsid <exec> &` (apps com `Terminal=true` são abertos no terminal configurado).

## Instalação

A pasta `launcher/` deve ficar **ao lado** do seu `shell.qml`
(por padrão em `~/.config/quickshell/`):

```
~/.config/quickshell/
├── shell.qml
└── launcher/
    ├── Launcher.qml
    ├── AppLoader.qml
    ├── DesktopDirScanner.qml
    ├── desktopParser.js
    └── qmldir
```

## Uso

No seu `shell.qml`, importe o módulo pelo caminho relativo e instancie o `Launcher`:

```qml
import "launcher"

ShellRoot {
    Launcher { id: appLauncher }

    // Abrir/fechar de qualquer lugar:
    // appLauncher.toggle()
}
```

### Abrindo via botão da barra

Substitua o clique que chamava o `fuzzel`:

```qml
// Antes:
// onClicked: { launcherProc.command = ["fuzzel"]; launcherProc.running = true }

// Depois:
onClicked: appLauncher.toggle()
```

### Abrindo via atalho global (Hyprland)

```qml
import Quickshell.Hyprland

GlobalShortcut {
    name: "launcher"
    description: "Abre o launcher de aplicativos"
    onPressed: appLauncher.toggle()
}
```

E no `hyprland.conf`:

```
bind = SUPER, D, global, quickshell:launcher
```

Veja `example-integration.qml` para um exemplo completo e executável.

## API pública do `Launcher`

| Membro          | Tipo       | Descrição |
|-----------------|------------|-----------|
| `open()`        | função     | Mostra o launcher, recarrega os apps e foca a busca. |
| `hide()`        | função     | Esconde o launcher. |
| `toggle()`      | função     | Alterna entre aberto/fechado. |
| `terminal`      | `string`   | Terminal usado para apps `Terminal=true` (padrão: `"foot"`). |
| `colBg` … `colPurple` | `color` | Cores do tema (padrão: paleta Tokyo Night, igual ao `shell.qml`). |
| `font`, `fsize` | `string`/`int` | Fonte e tamanho base. |

## Atalhos de teclado

| Tecla              | Ação |
|--------------------|------|
| Digitar            | Filtra a lista de aplicativos |
| `↑` / `↓`          | Move a seleção |
| `Tab`              | Próximo item |
| `Enter`            | Executa o app selecionado |
| `Esc`              | Fecha o launcher |
| Clique fora        | Fecha o launcher |

## Personalização

Todas as propriedades de tema podem ser sobrescritas na instância:

```qml
Launcher {
    id: appLauncher
    colBg:     "#1a1b26"
    colPurple: "#bb9af7"
    terminal:  "kitty"
    fsize:     14
}
```

Para alterar os diretórios pesquisados, ajuste a propriedade `dirs` do
`DesktopDirScanner` (dentro de `AppLoader.qml`).
