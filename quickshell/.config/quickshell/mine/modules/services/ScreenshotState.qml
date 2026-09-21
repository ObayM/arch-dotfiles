pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    enum Action {
        Copy,
        Edit
    }

    property bool open: false
    property int action: ScreenshotState.Action.Copy

    readonly property string saveDir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    function shellEscape(str) {
        return String(str).replace(/'/g, "'\\''");
    }

    function region(requested) {
        root.action = requested ?? ScreenshotState.Action.Copy;
        root.open = true;
    }

    function close() {
        root.open = false;
    }

    function cropCommand(source, x, y, width, height, requested) {
        const src = `'${root.shellEscape(source)}'`;
        const dir = `'${root.shellEscape(root.saveDir)}'`;
        const crop = `magick ${src} -crop ${Math.round(width)}x${Math.round(height)}+${Math.round(x)}+${Math.round(y)} +repage`;
        const cleanup = `rm -f ${src}`;
        const failed = `notify-send -a Screenshot -u critical 'Screenshot failed' 'Could not process the selected region'`;

        if (requested === ScreenshotState.Action.Edit)
            return ["bash", "-c", `{ ${crop} png:- | swappy -f - ; } || ${failed}; ${cleanup}`];

        return ["bash", "-c", `{ mkdir -p ${dir} && d=${dir} && out="$d/Screenshot_$(date '+%Y-%m-%d_%H-%M-%S').png" && ${crop} "$out" && wl-copy < "$out" && notify-send -a Screenshot -i "$out" 'Screenshot copied' "$out" ; } || ${failed}; ${cleanup}`];
    }

    function fullScreen(monitorName) {
        const dir = `'${root.shellEscape(root.saveDir)}'`;
        const target = monitorName && monitorName.length ? `-o '${root.shellEscape(monitorName)}'` : "";
        const failed = `notify-send -a Screenshot -u critical 'Screenshot failed' 'grim could not capture the screen'`;

        Quickshell.execDetached(["bash", "-c", `{ mkdir -p ${dir} && d=${dir} && out="$d/Screenshot_$(date '+%Y-%m-%d_%H-%M-%S').png" && grim ${target} "$out" && wl-copy < "$out" && notify-send -a Screenshot -i "$out" 'Screenshot saved' "$out" ; } || ${failed}`]);
    }
}
