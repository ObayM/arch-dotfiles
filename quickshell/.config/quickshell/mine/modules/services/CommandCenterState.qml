pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property bool barHovered: false
    property bool panelHovered: false
    property bool pinned: false

    readonly property bool wanted: barHovered || panelHovered || pinned

    property bool visible: false

    onWantedChanged: {
        if(wanted) {
            closeTimer.stop();
            openTimer.restart();
        } else {
            openTimer.stop();
            closeTimer.restart();
        }

    }

    Timer {
        id: openTimer
        interval: 130
        onTriggered: root.visible = true
    }

    Timer {
        id: closeTimer
        interval: 300

        onTriggered: {
            root.visible = false;
            root.pinned = false;
        }
    }
}