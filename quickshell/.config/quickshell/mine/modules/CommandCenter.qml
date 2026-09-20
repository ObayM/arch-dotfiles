pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.services
import qs.config

import QtQuick.Shapes

PanelWindow {
    id: root

    screen: CommandCenterState.screen ?? Quickshell.screens[0]
    color: 'transparent'
    visible: mapped

    WlrLayershell.namespace: "quickshell:commandcenter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    property bool mapped: false
    property bool shown: false

    Connections {
        target: CommandCenterState
        function onVisibleChanged() {
            if (CommandCenterState.visible) {
                hideTimer.stop();
                root.mapped = true;
                showTimer.restart();
            } else {
                root.shown = false;
                hideTimer.restart();
            }
        }
    }

    Timer {
        id: showTimer
        interval: 16
        onTriggered: root.shown = true
    }

    Timer {
        id: hideTimer
        interval: Appearance.animMed
        onTriggered: root.mapped = false
    }

    anchors {
        top: true
    }

    margins {
        top: 0
    }

    readonly property real islandBottom: Appearance.margin + (Appearance.barHeight + Appearance.islandHeight) / 2

    implicitHeight: islandBottom + 300
    implicitWidth: 360

    mask: Region {
        item: card
    }

    HoverHandler {
        onHoveredChanged: CommandCenterState.panelHovered = hovered
    }

    Item {
        id: content

        anchors.fill: parent
        transformOrigin: Item.Top

        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.97

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animFast
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.animMed
                easing.type: Appearance.easeOutCubic
            }
        }

        Rectangle {
            id: card
            y: root.islandBottom

            width: parent.width
            height: 300

            radius: Appearance.radius * 1.67

            color: Appearance.islandColor
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

        InvertedCorner {
            size: 14
            fill: card.color
            y: root.islandBottom - size
            x: card.width / 2 - CommandCenterState.pillWidth / 2 - size
        }

        InvertedCorner {
            size: 14
            mirror: true
            fill: card.color
            y: root.islandBottom - size
            x: card.width / 2 + CommandCenterState.pillWidth / 2
        }
    }

    component InvertedCorner: Shape {
        id: corner

        property real size: 14
        property color fill: "white"
        property bool mirror: false

        width: size
        height: size
        preferredRendererType: Shape.CurveRenderer

        transform: Scale {
            xScale: corner.mirror ? -1 : 1
            origin.x: corner.size / 2
        }
        
        ShapePath {
            fillColor: corner.fill
            strokeWidth: 0

            startX: corner.size
            startY: 0

            PathLine { x: corner.size; y: corner.size }
            PathLine { x: 0; y: corner.size }
            PathArc {
                x: corner.size
                y: 0
                radiusX: corner.size
                radiusY: corner.size
                direction: PathArc.Counterclockwise
            }
        }
    }

}