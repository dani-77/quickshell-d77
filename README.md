# quickshell-d77

d77-shell is a simple QT desktop shell built on top of Quickshell.

![sample](sample.png)

To install:

1 - Clone the Repository

```
git clone https://github.com/dani-77/quickshell-d77.git ~/.config/quickshell
```

2 - Execute the shell

```
qs -p ~/.config/quickshell/shell.qml
```

Enjoy

## Native application launcher

The shell ships with a built-in application launcher (Rofi/Fuzzel style),
written entirely in QML — no external dependencies. It is already wired into
`shell.qml`:

- Click the purple launcher button on the left of the bar, **or**
- Bind a global Hyprland shortcut (see below).

Detailed module documentation lives in [`launcher/README.md`](launcher/README.md).

### Hyprland global shortcuts

`shell.qml` registers two Quickshell `GlobalShortcut`s: `launcher` and
`session`. To bind them, add to your `hyprland.conf`:

```
bind = SUPER, D, global, quickshell:launcher      # application launcher
bind = SUPER SHIFT, E, global, quickshell:session # session menu
```

The format is `<appid>:<name>` (default `appid` is `quickshell`), matching the
`GlobalShortcut` declared in `shell.qml`. Reload Hyprland (`hyprctl reload`) and
press the keybind.

> 📖 Full keybind setup — including **Hyprland 0.55 with Lua** configs and how
> to verify the shortcuts are registered (`hyprctl globalshortcuts`) — is in
> [`KEYBINDS.md`](KEYBINDS.md).

### Launcher keybindings

| Key                | Action                          |
|--------------------|---------------------------------|
| Type               | Filter the application list     |
| `↑` / `↓`          | Move the selection              |
| `Tab`              | Next item                       |
| `Enter`            | Launch the selected application |
| `Esc` / click out  | Close the launcher              |
