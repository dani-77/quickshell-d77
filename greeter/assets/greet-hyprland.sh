#!/bin/sh
# greet-hyprland.sh
#
# Wrapper invoked by greetd to host the quickshell-d77 greeter under a
# minimal, disposable Hyprland instance. greetd runs this script on the
# login VT before any user session exists; once the user logs in (or
# cancels), quickshell exits and Hyprland is told to quit so greetd can
# hand off the VT to the real session command the user picked.
#
# Deploy this file to e.g. /etc/greetd/quickshell-d77/greet-hyprland.sh
# and point /etc/greetd/config.toml at it (see ../greetd-config.toml.example).
# Set GREETER_PATH to wherever this repo's greeter/ directory lives on
# this machine.

set -eu

GREETER_PATH="${GREETER_PATH:-/etc/greetd/quickshell-d77/greeter}"

if ! command -v qs >/dev/null 2>&1; then
    echo "Error: 'qs' (quickshell) was not found in PATH" >&2
    exit 1
fi
if ! command -v Hyprland >/dev/null 2>&1; then
    echo "Error: 'Hyprland' was not found in PATH" >&2
    exit 1
fi

export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EGL_PLATFORM=gbm

HYPR_CONFIG="$(mktemp --suffix=.conf)"
cat > "$HYPR_CONFIG" <<EOF
misc {
    disable_hyprland_logo    = true
    disable_splash_rendering = true
}

exec-once = sh -c "qs -p $GREETER_PATH; hyprctl dispatch exit"
EOF

exec Hyprland -c "$HYPR_CONFIG"
