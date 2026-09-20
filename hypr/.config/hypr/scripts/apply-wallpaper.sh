#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
SCHEME="scheme-tonal-spot"

MODE="dark"
PREFER="saturation"
NOSWITCH=0
IMG=""

notify() {
    command -v notify-send >/dev/null && \
        notify-send -a "Wallpaper" -u "$1" "$2" "$3" || true
}

warn() {
    echo "apply-wallpaper: $*" >&2
    notify normal "Wallpaper" "$*"
}

die() {
    echo "apply-wallpaper: $*" >&2
    notify critical "Wallpaper failed" "$*"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--mode)    MODE="$2";   shift 2 ;;
        -t|--type)    SCHEME="$2"; shift 2 ;;
        -p|--prefer)  PREFER="$2"; shift 2 ;;
        -n|--noswitch) NOSWITCH=1; shift ;;
        -r|--random)
            IMG="$(find "$2" -type f -regextype posix-extended \
                   -iregex '.*\.(jpg|jpeg|png|webp|bmp)' | shuf -n 1)"
            [[ -n "$IMG" ]] || die "no images found in $2"
            shift 2 ;;
        -h|--help)    usage; exit 0 ;;
        -*)           usage >&2; die "unknown option: $1" ;;
        *)            IMG="$1"; shift ;;
    esac
done

if (( NOSWITCH )); then
    [[ -e "$STATE_DIR/wallpaper" ]] || die "no current wallpaper to reuse"

    IMG="$(readlink -f "$STATE_DIR/wallpaper")"
fi

[[ -n "$IMG" ]] || { usage >&2; exit 1; }
src="$(realpath -e -- "$IMG" 2>/dev/null)" || die "no such file: $IMG"

[[ -f "$src" ]] || die "not a file: $src"
[[ "$(file -Lb --mime-type -- "$src")" == image/* ]] || die "not an image: $src"

dir="${src%/*}"; base="${src##*/}"; name="${base%.*}"; ext="${base##*.}"

stripped="${name%-dark}"; stripped="${stripped%-light}"
[[ -f "$dir/$stripped-$MODE.$ext" ]] && src="$dir/$stripped-$MODE.$ext"

if command -v identify >/dev/null && command -v hyprctl >/dev/null && command -v jq >/dev/null; then
    want_w="$(hyprctl monitors -j | jq '[.[].width] | max')"

    read -r img_w img_h < <(identify -format '%w %h' "${src}[0]" 2>/dev/null || echo "0 0")

    (( img_w > 0 && img_w < want_w )) && \
        warn "Image is ${img_w}×${img_h}, narrower than your ${want_w}px monitor it will be upscaled"
fi


matugen --prefer "$PREFER" --mode "$MODE" --type "$SCHEME" image "$src" \
    || die "matugen failed for $src"

mkdir -p "$STATE_DIR"
ln -sfn "$src" "$STATE_DIR/wallpaper"
printf '%s\n' "$src" > "$STATE_DIR/wallpaper.path.tmp"
mv -f "$STATE_DIR/wallpaper.path.tmp" "$STATE_DIR/wallpaper.path"

if command -v hyprctl >/dev/null && pgrep -x hyprpaper >/dev/null; then
    hyprctl hyprpaper reload ",$src" >/dev/null 2>&1 || true
fi