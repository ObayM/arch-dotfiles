pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/hypr"
    readonly property string applyScript: Quickshell.env("HOME") + "/.config/hypr/scripts/apply-wallpaper.sh"
    readonly property string dir: Quickshell.env("HOME") + "/Pictures/wallpapers"

    property string current: ""

    function set(path: string): void {
        if (!path.length || path === root.current)
            return;

        applyProcess.command = ["bash", root.applyScript, path];
        applyProcess.running = true;
    }

    function random(dir: string): void {
        applyProcess.command = ["bash", root.applyScript, "--random", dir];
        applyProcess.running = true;
    }

    function apply(value: string): void {
        const path = String(value).trim();
        if(path.length)
            root.current = path;
    }
    
    FileView {
        id: pathFile

        path: root.stateDir + "/wallpaper.path"
        watchChanges: true

        onFileChanged: {
            reload();
            rereadTimer.restart();
        }

        onLoadedChanged: root.apply(pathFile.text())
    }

    Timer {
        id: rereadTimer
        interval: 60
        onTriggered: root.apply(pathFile.text())
    }
    

    Process {
        id: applyProcess

        onExited: code => {
            if (code !== 0)
                console.warn("Wallpapers: apply script failed with code", code);
        }
    }
}
