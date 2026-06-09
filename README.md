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
- Trigger it from a Hyprland keybind via IPC (see below).

Detailed module documentation lives in [`launcher/README.md`](launcher/README.md).

## Controlling the shell via IPC (recommended)

`shell.qml` exposes two Quickshell `IpcHandler` targets so the launcher and the
session menu can be triggered from anywhere while the shell is running:

| Target     | Functions               | What it does                              |
|------------|-------------------------|-------------------------------------------|
| `launcher` | `toggle`, `open`, `close` | Show/hide the application launcher        |
| `session`  | `toggle`, `open`, `close` | Show/hide the session menu (lock/suspend/reboot/shutdown/logout) |

Call them from the command line:

```bash
qs ipc call launcher toggle     # toggle the launcher
qs ipc call launcher open       # open the launcher
qs ipc call launcher close      # close the launcher

qs ipc call session toggle      # toggle the session menu
qs ipc call session open        # open the session menu
qs ipc call session close       # close the session menu

qs ipc show                     # list every target/function exposed
```

### Hyprland keybinds (IPC)

This is the most reliable way to bind the shell — especially with **Lua-generated
Hyprland configs (Hyprland 0.46+)**, where the `global` dispatcher tends to be
fragile. Add to your `hyprland.conf`:

```ini
bind = SUPER, D, exec, qs ipc call launcher toggle      # application launcher
bind = SUPER SHIFT, E, exec, qs ipc call session toggle # session menu
```

Reload Hyprland (`hyprctl reload`) and press the keybind.

> 📖 Full keybind setup — including **Hyprland with Lua** (generating
> `hyprland.conf`, `init.lua`, `hyprctl keyword`, `source`) and how to verify the
> IPC targets (`qs ipc show`) — is in [`KEYBINDS.md`](KEYBINDS.md).

### Global shortcuts (fallback)

`shell.qml` also keeps two Quickshell `GlobalShortcut`s (`launcher` and
`session`) as a fallback. To use them instead of IPC:

```ini
bind = SUPER, D, global, quickshell:launcher      # application launcher
bind = SUPER SHIFT, E, global, quickshell:session # session menu
```

The format is `<appid>:<name>` (default `appid` is `quickshell`). See
[`KEYBINDS.md`](KEYBINDS.md) for details.

### Launcher keybindings

| Key                | Action                          |
|--------------------|---------------------------------|
| Type               | Filter the application list     |
| `↑` / `↓`          | Move the selection              |
| `Tab`              | Next item                       |
| `Enter`            | Launch the selected application |
| `Esc` / click out  | Close the launcher              |
