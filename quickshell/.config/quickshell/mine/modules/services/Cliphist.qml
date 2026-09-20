pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string binary: "cliphist"
    property var entries: []

    function shellEscape(str) {
        return String(str).replace(/'/g, "'\\''");
    }

    function clean(entry) {
        return String(entry).replace(/^\d+\t/, "");
    }

    function refresh() {
        listProcess.buffer = [];
        listProcess.running = true;
    }

    function copy(entry) {
        Quickshell.execDetached(["bash", "-c", `printf '%s' '${root.shellEscape(entry)}' | ${root.binary} decode | wl-copy`]);
    }

    function paste(entry) {
        Quickshell.execDetached(["bash", "-c", `printf '%s' '${root.shellEscape(entry)}' | ${root.binary} decode | wl-copy && sleep 0.05 && wtype -M ctrl -k v -m ctrl`]);
    }

    Process {
        id: listProcess

        property var buffer: []

        command: [root.binary, "list"]

        stdout: SplitParser {
            onRead: line => listProcess.buffer.push(line)
        }

        onExited: code => {
            if (code === 0)
                root.entries = listProcess.buffer;
            else
                console.warn("Cliphist: list failed with code", code);
        }
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            refreshTimer.restart();
        }
    }

    Timer {
        id: refreshTimer
        interval: 120
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}