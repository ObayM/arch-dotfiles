
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal brightnessChanged()

    property real value: 1

    function refresh() {
        readProcess.running = true;
    }

    Process {
        id: readProcess
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pct = parseInt(this.text.trim());

                if (!isNaN(pct)) {
                    root.value = pct / 100;
                    root.brightnessChanged();
                }
            }
        }
    }
}