pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.modules.common
import qs.modules.services

PanelWindow {
    id: root

    required property var targetScreen

    screen: root.targetScreen
    visible: false
    color: "transparent"

    WlrLayershell.namespace: "quickshell:screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property real monitorScale: Hyprland.monitorFor(root.targetScreen)?.scale ?? 1
    readonly property string capturePath: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/quickshell-snip-${root.targetScreen.name}.png`

    property bool consumed: false
    property real dragStartX: 0
    property real dragStartY: 0
    property real dragX: 0
    property real dragY: 0
    property bool dragging: false

    readonly property real regionX: Math.min(root.dragStartX, root.dragX)
    readonly property real regionY: Math.min(root.dragStartY, root.dragY)
    readonly property real regionWidth: Math.abs(root.dragX - root.dragStartX)
    readonly property real regionHeight: Math.abs(root.dragY - root.dragStartY)
    readonly property bool hasRegion: root.regionWidth >= 6 && root.regionHeight >= 6

    function snip(requested) {
        if (!root.hasRegion) {
            ScreenshotState.close();
            return;
        }

        root.consumed = true;
        Quickshell.execDetached(ScreenshotState.cropCommand(root.capturePath, root.regionX * root.monitorScale, root.regionY * root.monitorScale, root.regionWidth * root.monitorScale, root.regionHeight * root.monitorScale, requested));
        ScreenshotState.close();
    }

    Component.onDestruction: {
        if (!root.consumed)
            Quickshell.execDetached(["rm", "-f", root.capturePath]);
    }

    Process {
        id: captureProc

        running: true
        command: ["grim", "-o", root.targetScreen.name, root.capturePath]

        onExited: exitCode => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", "-a", "Screenshot", "-u", "critical", "Screenshot failed", `grim could not capture ${root.targetScreen.name}`]);
                ScreenshotState.close();
                return;
            }
            root.visible = true;
        }
    }

    ScreencopyView {
        anchors.fill: parent
        live: false
        captureSource: root.targetScreen
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        focus: true
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        Keys.onEscapePressed: ScreenshotState.close()

        onPressed: mouse => {
            root.dragStartX = mouse.x;
            root.dragStartY = mouse.y;
            root.dragX = mouse.x;
            root.dragY = mouse.y;
            root.dragging = true;
        }

        onPositionChanged: mouse => {
            if (!root.dragging)
                return;
            root.dragX = mouse.x;
            root.dragY = mouse.y;
        }

        onReleased: mouse => {
            root.dragging = false;
            root.snip(mouse.button === Qt.RightButton ? ScreenshotState.Action.Edit : ScreenshotState.action);
        }

        Rectangle {
            id: dimmer

            x: root.regionX - dimmer.border.width
            y: root.regionY - dimmer.border.width
            width: root.regionWidth + dimmer.border.width * 2
            height: root.regionHeight + dimmer.border.width * 2
            color: "transparent"
            border.width: Math.max(root.width, root.height)
            border.color: Qt.rgba(0, 0, 0, 0.45)
        }

        Rectangle {
            visible: !root.dragging
            opacity: 0.25
            x: mouseArea.mouseX
            width: 1
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Appearance.accent
        }

        Rectangle {
            visible: !root.dragging
            opacity: 0.25
            y: mouseArea.mouseY
            height: 1
            anchors.left: parent.left
            anchors.right: parent.right
            color: Appearance.accent
        }

        Rectangle {
            visible: root.hasRegion
            x: root.regionX
            y: root.regionY
            width: root.regionWidth
            height: root.regionHeight
            color: Appearance.alpha(Appearance.accent, 0.08)
            border.width: 1
            border.color: Appearance.alpha(Appearance.accent, 0.9)
        }

        Repeater {
            model: [[0, 0], [1, 0], [0, 1], [1, 1]]

            delegate: Item {
                id: corner

                required property var modelData

                readonly property bool atRight: corner.modelData[0] === 1
                readonly property bool atBottom: corner.modelData[1] === 1
                readonly property int arm: 16
                readonly property int thickness: 3

                visible: root.hasRegion
                x: root.regionX + (corner.atRight ? root.regionWidth - corner.arm : 0)
                y: root.regionY + (corner.atBottom ? root.regionHeight - corner.arm : 0)
                width: corner.arm
                height: corner.arm

                Rectangle {
                    y: corner.atBottom ? corner.arm - corner.thickness : 0
                    width: corner.arm
                    height: corner.thickness
                    color: Appearance.accent
                }

                Rectangle {
                    x: corner.atRight ? corner.arm - corner.thickness : 0
                    width: corner.thickness
                    height: corner.arm
                    color: Appearance.accent
                }
            }
        }

        Rectangle {
            id: sizeChip

            visible: root.hasRegion
            width: sizeText.implicitWidth + 20
            height: 26
            radius: height / 2
            color: Appearance.accent
            x: Math.max(8, Math.min(root.width - sizeChip.width - 8, root.regionX))
            y: root.regionY + root.regionHeight + sizeChip.height + 16 < root.height ? root.regionY + root.regionHeight + 10 : Math.max(8, root.regionY - sizeChip.height - 10)

            Text {
                id: sizeText

                anchors.centerIn: parent
                text: `${Math.round(root.regionWidth)} × ${Math.round(root.regionHeight)}`
                color: Appearance.onAccent
                font.family: Appearance.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            id: hintChip

            visible: !root.hasRegion
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 72
            width: hintRow.implicitWidth + 32
            height: 46
            radius: height / 2
            color: Appearance.cardColor
            border.width: 1
            border.color: Appearance.cardBorder

            RowLayout {
                id: hintRow

                anchors.centerIn: parent
                spacing: 10

                MaterialSymbol {
                    icon: ScreenshotState.action === ScreenshotState.Action.Edit ? "edit" : "content_cut"
                    iconSize: 19
                    color: Appearance.accent
                }

                Text {
                    text: "Drag to capture   ·   Right-drag to annotate   ·   Esc to cancel"
                    color: Appearance.subtext
                    font.family: Appearance.fontFamily
                    font.pixelSize: 13
                }
            }
        }
    }
}
