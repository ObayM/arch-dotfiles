pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property bool active: false
    property var screen: null

    signal openRequested(var targetScreen)
    signal closeRequested

    function toggle(targetScreen) {
        if (root.active && root.screen?.name === targetScreen?.name)
            root.closeRequested();
        else
            root.openRequested(targetScreen);
    }
}