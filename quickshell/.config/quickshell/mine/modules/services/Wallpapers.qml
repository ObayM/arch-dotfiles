pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateLink: Quickshell.env("HOME") + "/.local/state/hypr/wallpaper"
    readonly property string applyScript: Quickshell.env("HOME") + "/.config/hypr/scripts/apply-wallpaper.sh"

    property string current: ""

    function refresh() {
        readLinkProcess.running = true;
    }

    function set(path) {
        
        if (!path.length || path === root.current)
            return;
        
        applyProcess.command = ["bash", root.applyScript, path];
        applyProcess.running = true;
    }

    Process {
        id: readLinkProcess

        command: ["readlink", "-f", root.stateLink]

        stdout: StdioCollector {
            onStreamFinished: root.current = this.text.trim()
        }
    }

     Process {
        id: applyProcess

        onExited: code => {
            if (code === 0)
                root.refresh();
            else
                console.warn("Wallpapers: apply script failed with code", code);
        }
    }

    Component.onCompleted: root.refresh()
}