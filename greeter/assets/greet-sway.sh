#!/bin/sh
# greet-sway.sh
#
# Wrapper invoked by greetd to host the quickshell-d77 greeter under a
# minimal, disposable Sway instance instead of Hyprland/niri. Same idea
# as the other greet-*.sh wrappers: greetd runs this on the login VT
# before any user session exists; once the user logs in (or cancels),
# quickshell exits and Sway is told to quit so greetd can hand off the
# VT to the real session command the user picked.
#
# Deploy this file to e.g. /etc/greetd/quickshell-d77/greet-sway.sh and
# point /etc/greetd/config.toml at it (see ../greetd-config.toml.example).
# Set GREETER_PATH to wherever this repo's greeter/ directory lives on
# this machine.

set -eu

GREETER_PATH="${GREETER_PATH:-/etc/greetd/quickshell-d77/greeter}"

if ! command -v qs >/dev/null 2>&1; then
    echo "Error: 'qs' (quickshell) was not found in PATH" >&2
    exit 1
fi
if ! command -v sway >/dev/null 2>&1; then
    echo "Error: 'sway' was not found in PATH" >&2
    exit 1
fi

export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EGL_PLATFORM=gbm

SWAY_CONFIG="$(mktemp --suffix=.conf)"
cat > "$SWAY_CONFIG" <<EOF
exec "sh -c 'qs -p $GREETER_PATH; swaymsg exit'"
EOF

exec sway -c "$SWAY_CONFIG"
