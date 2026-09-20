set -euo pipefail

cd "$(dirname "$0")"
for f in *.frag; do
    /usr/lib/qt6/bin/qsb --qt6 -o "$f.qsb" "$f"
done