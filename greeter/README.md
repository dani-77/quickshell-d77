# `greeter` Module

Native login greeter for [greetd](https://github.com/kennylevinsen/greetd), written entirely
in QML for quickshell-d77, styled to match the rest of the shell (Tokyo Night) and reusing the
same QML-drawn background as [`backdrop/Backdrop.qml`](../backdrop/Backdrop.qml) — no raster
wallpaper needed, no theme-sync system to keep alive.

`greeter/GreeterBackdrop.qml` is that same chevrons + d77 logo drawing, vendored as a local
copy rather than imported across directories: greetd points `qs -p` straight at this `greeter/`
folder, making it its own self-contained config root, and Quickshell doesn't resolve relative
imports that climb back out of that root at runtime (confirmed by actually running `qs -p
greeter/` — `import "../backdrop"` fails to load even though the file is right there on disk).
Since this folder is meant to be copied out to `/etc/greetd/...` standalone anyway (see
Installation below), keeping the artwork local avoids depending on the rest of the repo being
deployed alongside it. If you tweak the chevrons/logo in `backdrop/Backdrop.qml`, mirror the
change here too.

Authentication goes through **greetd's own IPC** (`Quickshell.Services.Greetd`), so PAM is
handled entirely by the `greetd` daemon (via `/etc/pam.d/greetd`) — this module never touches
passwords itself beyond forwarding what greetd asks for.

![sample](../sample.png)

## Features

- **Reads both X11 and Wayland sessions**: scans `/usr/share/wayland-sessions` and
  `/usr/share/xsessions` (plus `/usr/local/share/...`, every `XDG_DATA_DIRS` entry, and
  `~/.local/share/...`), parsing `Name=`/`Exec=` from each `.desktop` file.
- **Correct X11 launch**: greetd never starts an Xorg server on its own — it only execs the
  session command directly on the VT. Sessions found under an `xsessions` directory are
  therefore launched wrapped as `startx /usr/bin/env <Exec>` (the same default
  [tuigreet](https://github.com/apognu/tuigreet) uses for `--xsession-wrapper`), while sessions
  from `wayland-sessions` are exec'd as-is. `XDG_SESSION_TYPE` is set accordingly (`x11` vs
  `wayland`) instead of being hardcoded.
- **Same visual identity as the rest of the shell**: the background is `GreeterBackdrop`
  (chevrons + d77 logo, drawn in QML — the same artwork as `backdrop/Backdrop.qml`), and the
  login card follows the same Tokyo Night styling as `lockscreen/LockSurface.qml`.
- **Multi-monitor**: one surface per screen; only the primary screen is interactive/keyboard
  focused, the rest mirror the same background + state, same approach as the lockscreen.

## Module Contents

| File | Responsibility |
|------|-----------------|
| `Greeter.qml` | Session-directory scanner (X11 + Wayland), greetd IPC (`Quickshell.Services.Greetd`), per-screen `PanelWindow` variants. |
| `GreeterState.qml` | Shared singleton state: username, password, PAM feedback, discovered sessions. |
| `GreeterBackdrop.qml` | Vendored copy of the chevrons + d77 logo background (see note above). |
| `GreeterSurface.qml` | Per-monitor UI: `GreeterBackdrop`, clock, login card (username/password/session picker). |
| `shell.qml` | Standalone entry point — this is what greetd points `qs -p` at. |
| `assets/greet-hyprland.sh` | Wrapper greetd runs: starts a disposable Hyprland instance hosting the greeter, quits it once quickshell exits. |
| `assets/greet-niri.sh` | Same idea, for niri instead of Hyprland. |
| `assets/greet-sway.sh` | Same idea, for Sway instead of Hyprland. |
| `assets/greet-mango.sh` | Same idea, for mangowc instead of Hyprland. Pick whichever compositor you have installed — all four run the identical greeter. |
| `greetd-config.toml.example` | Example `/etc/greetd/config.toml` (Hyprland by default, niri/Sway/mangowc commented out). |

## How It Works

```text
greetd (VT) ──runs──▶ greet-{hyprland,niri,sway,mango}.sh ──▶ disposable compositor ──▶ qs -p greeter/
                                                                                        │
                                                                          Greeter.qml ─┼─ scans xsessions/wayland-sessions
                                                                                        ├─ Quickshell.Services.Greetd (PAM via greetd)
                                                                                        └─ GreeterSurface (one per monitor)
```

1. `greetd` starts whichever `greet-*.sh` wrapper `config.toml` points at, which launches a
   throwaway compositor instance whose only job is to host the greeter (`qs -p greeter/`).
2. `Greeter.qml` scans the session directories and populates `GreeterState` with every
   discovered session (name, exec command, and whether it's `x11` or `wayland`).
3. The user types a username/password and picks a session in the login card
   (`GreeterSurface.qml`), then presses **Login** (or Enter).
4. `Greeter.qml` calls `Greetd.createSession(username)`; when greetd/PAM asks for a response,
   the buffered password is sent back via `Greetd.respond(...)`.
5. On success (`onReadyToLaunch`), the selected session's `Exec=` command is launched — wrapped
   with `startx /usr/bin/env` first if it's an X11 session — and the host compositor is told to
   quit, handing the VT to the real session.
6. On failure, the password is cleared and "Incorrect username or password" is shown; the user
   can try again immediately.

## Installation

This module only covers the **QML greeter itself and its compositor wrapper**. Wiring it up as
your system's login manager touches system-wide files, so these steps are meant to be run
**manually, with root**, not automated:

1. Install `greetd` and `quickshell` from your distro's repositories.

2. Create the greeter system user (skip if your distro's `greetd` package already does this):
   ```bash
   sudo groupadd -r greeter
   sudo useradd -r -g greeter -d /var/lib/greeter -s /bin/bash -c "System Greeter" greeter
   sudo mkdir -p /var/lib/greeter
   sudo chown greeter:greeter /var/lib/greeter
   ```

3. Deploy this repo (or just the `greeter/` folder) somewhere the greeter user can read, and
   pick **one** of the four host-compositor wrappers depending on what you have installed:
   ```bash
   sudo mkdir -p /etc/greetd/quickshell-d77
   sudo cp -r ~/Projectos/quickshell-d77/greeter /etc/greetd/quickshell-d77/greeter

   # Hyprland host:
   sudo cp ~/Projectos/quickshell-d77/greeter/assets/greet-hyprland.sh /etc/greetd/quickshell-d77/
   sudo chmod +x /etc/greetd/quickshell-d77/greet-hyprland.sh

   # — or — niri host:
   sudo cp ~/Projectos/quickshell-d77/greeter/assets/greet-niri.sh /etc/greetd/quickshell-d77/
   sudo chmod +x /etc/greetd/quickshell-d77/greet-niri.sh

   # — or — Sway host:
   sudo cp ~/Projectos/quickshell-d77/greeter/assets/greet-sway.sh /etc/greetd/quickshell-d77/
   sudo chmod +x /etc/greetd/quickshell-d77/greet-sway.sh

   # — or — mangowc host:
   sudo cp ~/Projectos/quickshell-d77/greeter/assets/greet-mango.sh /etc/greetd/quickshell-d77/
   sudo chmod +x /etc/greetd/quickshell-d77/greet-mango.sh
   ```
   `/usr/share/{xsessions,wayland-sessions}` are world-readable by default, so — unlike a
   wallpaper/theme-sync setup — no ACLs or group membership are needed just to list sessions.

4. Copy [`greetd-config.toml.example`](greetd-config.toml.example) to `/etc/greetd/config.toml`
   (back up the original first), adjusting `vt` and the `command` line (Hyprland vs. niri vs.
   Sway vs. mangowc) if needed.

5. Disable your current display manager and enable `greetd`:
   ```bash
   sudo systemctl disable gdm sddm lightdm 2>/dev/null
   sudo systemctl enable greetd
   ```

6. Reboot (or `sudo systemctl start greetd` on a free VT) to try it.

### Testing without touching greetd

You can render the greeter UI directly under your *current* Wayland session — any compositor
implementing `zwlr_layer_shell_v1` works, not just Hyprland/niri/Sway/mangowc — to sanity-check
the QML (it just won't be able to complete a real login without a greetd socket to talk to):

```bash
qs -p ~/Projectos/quickshell-d77/greeter
```

This was verified nested under Sway directly (loads cleanly, no QML warnings — a stray `swaymsg
exit`/"Wayland connection broke" error only shows up if you kill the nested compositor from the
outside mid-test, e.g. via `timeout`, not during a normal login/launch), and under standalone
`niri -c <config>`, `sway -c <config>`, and `mango -s <command>` instances using the exact
`exec`/`spawn-at-startup`/`-s` invocation each of `greet-niri.sh`/`greet-sway.sh`/
`greet-mango.sh` generates.

## Customization

Theme colors are passed the same way as the lockscreen — override them where `Greeter` is
instantiated:

```qml
Greeter {
    colBg:     "#1a1b26"
    colPurple: "#bb9af7"
    fsize:     13
}
```

Four host-compositor wrappers ship out of the box — `assets/greet-hyprland.sh`,
`assets/greet-niri.sh`, `assets/greet-sway.sh`, and `assets/greet-mango.sh` — pick whichever
matches what you have installed via `greetd-config.toml`'s `command` line. To support a
different compositor, copy one of them and adapt the startup-command line for that
compositor's own syntax (config-file `exec`/`spawn-at-startup` for niri/Sway/Hyprland, or a
plain CLI flag like mango's `-s`).

## Requirements

- **greetd**, with its PAM stack configured (`/etc/pam.d/greetd`, usually shipped by the
  greetd package).
- **Quickshell** with `Quickshell.Services.Greetd` support.
- **Hyprland, niri, Sway, or mangowc**, to host the greeter itself before login (a wrapper
  ships for each; see "Customization" above to add another compositor).
- `startx`/`xinit` installed if you want X11 sessions to actually work — that's what
  X11 `Exec=` commands get wrapped with, since greetd doesn't start Xorg on its own.

## Known limitations

- No per-user avatar picker or multi-user list — this is deliberately a simple
  username/password/session form, consistent with the rest of quickshell-d77 (see the
  [lockscreen module](../lockscreen)). Nothing above stops you from adding one later.
- "Remember last user/session" isn't implemented — every boot starts blank. That's a small,
  self-contained addition to `GreeterState.qml`/`Greeter.qml` if you want it.
