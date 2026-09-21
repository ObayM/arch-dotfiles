#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PACKAGES=(
    hyprland quickshell kitty stow jq
    brightnessctl wireplumber networkmanager
    cliphist wl-clipboard libqalculate python
    matugen imagemagick
    ttf-material-symbols-variable ttf-firacode-nerd
    hyprpolkitagent xdg-desktop-portal-hyprland
    dolphin
)

STOW_PACKAGES=(hypr quickshell matugen)
MIN_HYPRLAND="0.55.0"

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"

die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
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
[[ "$installed_hyprland" != "0.0.0" ]] || die "Couldn't verify hyprland version, Make sure it is installed correctly"
if [[ "$(printf '%s\n%s\n' "$MIN_HYPRLAND" "$installed_hyprland" | sort -V | head -1)" != "$MIN_HYPRLAND" ]]; then
    die "Hyprland >= $MIN_HYPRLAND required for Lua config (found $installed_hyprland)"
fi

info "checking for files that would block stow"
conflicts=()
while IFS= read -r rel; do
    [[ -n "$rel" ]] && conflicts+=("$rel")
done < <(stow --dir "$REPO_ROOT" --target "$HOME" --no --restow "${STOW_PACKAGES[@]}" 2>&1 \
         | grep -oP 'existing target is neither a link nor a directory: \K.*' || true)

if (( ${#conflicts[@]} > 0 )); then
    backup="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    info "moving ${#conflicts[@]} existing file(s) to $backup"
    for rel in "${conflicts[@]}"; do
        mkdir -p "$backup/$(dirname -- "$rel")"
        mv -- "$HOME/$rel" "$backup/$rel"
    done
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
        warn "Hyprland isn't running; writing a placeholder monitor into $local_config"
        cat > "$local_config" <<'TEMPLATE'
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1.0 })
TEMPLATE
    fi
fi

shopt -s nullglob
repo_wallpapers=("$REPO_ROOT"/wallpapers/*.{jpg,jpeg,png,webp})
shopt -u nullglob

mkdir -p "$WALLPAPER_DIR"
if (( ${#repo_wallpapers[@]} > 0 )); then
    info "copying ${#repo_wallpapers[@]} wallpaper(s) into $WALLPAPER_DIR"
    cp -n -- "${repo_wallpapers[@]}" "$WALLPAPER_DIR/"
fi

if [[ ! -e "$STATE_DIR/wallpaper" ]]; then
    first_wallpaper="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f -regextype posix-extended \
        -iregex '.*\.(jpg|jpeg|png|webp)' | sort | head -1)"
    if [[ -n "$first_wallpaper" ]]; then
        info "applying $(basename -- "$first_wallpaper") to generate the matugen palette"
        bash "$REPO_ROOT/hypr/.config/hypr/scripts/apply-wallpaper.sh" "$first_wallpaper" \
            || warn "couldn't apply a wallpaper; the shell will fall back to its built-in colors"
    else
        warn "no wallpapers in $WALLPAPER_DIR; the shell will use its built-in colors until you set one"
    fi
fi

if [[ ! -f "$HOME/.wakatime.cfg" ]] || ! grep -q '^api_key' "$HOME/.wakatime.cfg" 2>/dev/null; then
    info "no Hackatime API key found in ~/.wakatime.cfg; the bar's Hackatime widget needs one to show your stats"
    info "set up Hackatime for your editor at https://hackatime.hackclub.com to get one"
fi

info "Everything is done :)"
