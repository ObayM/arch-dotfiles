pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.services
import qs.config

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    color: 'transparent'
    visible: CommandCenterState.visible

    WlrLayershell.namespace: "quickshell:commandcenter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0

    anchors {
        top: true
    }

    margins {
        top: Appearance.margin
    }

    implicitHeight: 300
    implicitWidth: 360

    HoverHandler {
        onHoveredChanged: CommandCenterState.panelHovered = hovered
    }

    Rectangle {
        anchors.fill: parent

        radius: Appearance.radius * 1.67 // nothing special about the number here, it's just perfect :)

        color: Qt.rgba(Appearance.bg.r, Appearance.bg.g, Appearance.bg.b, 0.94)
        border.width: 1
        border.color: Appearance.hairline

        Text {
            anchors.centerIn: parent
            text: "command center"
            color: Appearance.fg
            font.family: Appearance.fontFamily
            font.pixelSize: 14
        }
    }
}