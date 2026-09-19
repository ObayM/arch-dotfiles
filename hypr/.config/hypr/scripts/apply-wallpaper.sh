#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 ]] || { echo "usage: apply-wallpaper.sh <image>" >&2; exit 1; }

src="$(realpath "$1")"
[[ -f "$src" ]] || { echo "not a file: $src" >&2; exit 1; }

state_dir="$HOME/.local/state/hypr"
mkdir -p "$state_dir"
ln -sf "$src" "$state_dir/wallpaper"

matugen image "$src"

if pgrep -x hyprpaper >/dev/null; then
    hyprctl hyprpaper unload all
    hyprctl hyprpaper preload "$state_dir/wallpaper"
    hyprctl hyprpaper wallpaper ",$state_dir/wallpaper"
fi
