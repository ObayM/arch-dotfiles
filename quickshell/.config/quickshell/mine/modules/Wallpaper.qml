pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.services

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        screen: win.modelData
        color: "black"

        WlrLayershell.namespace: "quickshell:wallpaper"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {}

        Image {
            anchors.fill: parent
            source: Wallpapers.current.length ? "file://" + Wallpapers.current : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            sourceSize.width: win.screen.width
            sourceSize.height: win.screen.height
        }
    }
}