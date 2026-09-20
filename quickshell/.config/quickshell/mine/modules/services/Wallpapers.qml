pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/hypr"
    readonly property string applyScript: Quickshell.env("HOME") + "/.config/hypr/scripts/apply-wallpaper.sh"
    readonly property string dir: Quickshell.env("HOME") + "/Pictures/wallpapers"

    property point originGlobal: Qt.point(0, 0)

    property var transition: Appearance.wallpaperTransitions[0]

    property string current: ""

    function pickTransition(): void {
        const list = Appearance.wallpaperTransitions;
        root.transition = list[Math.floor(Math.random() * list.length)];
    }

    function setAt(path: string, globalPoint: point): void {
        root.originGlobal = globalPoint;
        root.set(path);
    }

    function queryCursor(): void {
        cursorProcess.running = true;
    }

    Process {
        id: cursorProcess

        command: ["hyprctl", "cursorpos", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const p = JSON.parse(this.text);
                    root.originGlobal = Qt.point(p.x, p.y);
                } catch (e) {
                    root.originGlobal = Qt.point(0, 0);
                }
            }
        }
    }

    function set(path: string): void {
        root.queryCursor();
        if (!path.length || path === root.current)
            return;

        applyProcess.command = ["bash", root.applyScript, path];
        applyProcess.running = true;
    }

    function random(dir: string): void {
        root.queryCursor();
        applyProcess.command = ["bash", root.applyScript, "--random", dir];
        applyProcess.running = true;
    }

    function apply(value: string): void {
        const path = String(value).trim();
        if (!path.length || path === root.current)
            return;

        root.pickTransition();
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
