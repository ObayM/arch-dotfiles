#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(hyprland quickshell kitty stow jq brightnessctl wireplumber hyprpolkitagent)
STOW_PACKAGES=(hypr quickshell)
MIN_HYPRLAND="0.55.0"

die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[34m::\033[0m %s\n' "$*"; }

[[ $EUID -ne 0 ]] || die "do not run as root; it stows into \$HOME"
command -v pacman >/dev/null || die "This is only for Arch!"

aur_helper=""
for helper in paru yay; do
    if command -v "$helper" >/dev/null; then
        aur_helper="$helper"
        break
    fi
done
[[ -n "$aur_helper" ]] || die "There is no any AUR helper; please install paru or yay"

info "installing packages"
"$aur_helper" -S --needed "${PACKAGES[@]}"

hyprland_version() {
    local raw
    raw="$(Hyprland --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)" || true
    printf '%s' "${raw:-0.0.0}"
}

installed_hyprland="$(hyprland_version)"
[[ "$installed_hyprland" != "0.0.0" ]] || die "Couldn't verify hyperland version, Make sure it is installed correctly"
if [[ "$(printf '%s\n%s\n' "$MIN_HYPRLAND" "$installed_hyprland" | sort -V | head -1)" != "$MIN_HYPRLAND" ]]; then
    die "Hyprland >= $MIN_HYPRLAND required for Lua config (found $installed_hyprland)"
fi

info "stowing into $HOME"
stow --dir "$REPO_ROOT" --target "$HOME" --restow "${STOW_PACKAGES[@]}"

local_config="$HOME/.config/hypr/local.lua"
if [[ ! -e "$local_config" ]]; then
    info "generating $local_config from current outputs"
    if command -v jq >/dev/null && hyprctl monitors -j >/dev/null 2>&1; then
        hyprctl monitors -j | jq -r '.[] |
            "hl.monitor({ output = \"\(.name)\", mode = \"\(.width)x\(.height)@\(.refreshRate | round)\", position = \"\(.x)x\(.y)\", scale = \(.scale) })"' \
            > "$local_config"
    else
        cat > "$local_config" <<'TEMPLATE'
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1.0 })
TEMPLATE
    fi
fi

info "Everything is done :)"
