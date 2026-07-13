#!/bin/sh
# greet-niri.sh
#
# Wrapper invoked by greetd to host the quickshell-d77 greeter under a
# minimal, disposable niri instance instead of Hyprland. Same idea as
# greet-hyprland.sh: greetd runs this on the login VT before any user
# session exists; once the user logs in (or cancels), quickshell exits
# and niri is told to quit so greetd can hand off the VT to the real
# session command the user picked.
#
# Deploy this file to e.g. /etc/greetd/quickshell-d77/greet-niri.sh and
# point /etc/greetd/config.toml at it (see ../greetd-config.toml.example).
# Set GREETER_PATH to wherever this repo's greeter/ directory lives on
# this machine.

set -eu

GREETER_PATH="${GREETER_PATH:-/etc/greetd/quickshell-d77/greeter}"

if ! command -v qs >/dev/null 2>&1; then
    echo "Error: 'qs' (quickshell) was not found in PATH" >&2
    exit 1
fi
if ! command -v niri >/dev/null 2>&1; then
    echo "Error: 'niri' was not found in PATH" >&2
    exit 1
fi

export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EGL_PLATFORM=gbm

NIRI_CONFIG="$(mktemp --suffix=.kdl)"
cat > "$NIRI_CONFIG" <<EOF
hotkey-overlay {
    skip-at-startup
}

gestures {
    hot-corners {
        off
    }
}

layout {
    background-color "#1a1b26"
}

spawn-at-startup "sh" "-c" "qs -p $GREETER_PATH; niri msg action quit --skip-confirmation"
EOF

# Not --session: this niri instance only ever hosts the greeter, it
# must not import its environment globally or start D-Bus services —
# that belongs to whichever session the user picks next.
exec niri -c "$NIRI_CONFIG"
