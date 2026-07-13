#!/bin/sh
# greet-mango.sh
#
# Wrapper invoked by greetd to host the quickshell-d77 greeter under a
# minimal, disposable mangowc instance instead of Hyprland/niri/Sway.
# Same idea as the other greet-*.sh wrappers: greetd runs this on the
# login VT before any user session exists; once the user logs in (or
# cancels), quickshell exits and mango is told to quit so greetd can
# hand off the VT to the real session command the user picked.
#
# Unlike the other compositors, mango takes the startup command directly
# via `-s` — no throwaway config file needed.
#
# Deploy this file to e.g. /etc/greetd/quickshell-d77/greet-mango.sh and
# point /etc/greetd/config.toml at it (see ../greetd-config.toml.example).
# Set GREETER_PATH to wherever this repo's greeter/ directory lives on
# this machine.

set -eu

GREETER_PATH="${GREETER_PATH:-/etc/greetd/quickshell-d77/greeter}"

if ! command -v qs >/dev/null 2>&1; then
    echo "Error: 'qs' (quickshell) was not found in PATH" >&2
    exit 1
fi
if ! command -v mango >/dev/null 2>&1; then
    echo "Error: 'mango' was not found in PATH" >&2
    exit 1
fi

export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EGL_PLATFORM=gbm

exec mango -s "sh -c 'qs -p $GREETER_PATH; mmsg dispatch quit'"
