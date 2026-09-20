pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import Quickshell.Io

import qs.modules.services
import qs.config

PanelWindow {
    id: root
    screen: Quickshell.screens[0]
    color: 'transparent'

    WlrLayershell.namespace: 'quickshell:osd'
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0

    anchors {
        bottom: true
    }

    margins {
        bottom: Appearance.margin * 4
    }

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    property bool open: false
    property string kind: "volume"


    readonly property real value: root.kind === "volume" ? (Pipewire.defaultAudioSink?.audio.volume ?? 0) : Brightness.value
    readonly property bool muted: root.kind === "volume" && (Pipewire.defaultAudioSink?.audio.muted ?? false)
    readonly property string icon: root.kind === "volume" ? (root.muted ? "" : root.value > 0.5 ? "" : root.value > 0 ? "" : "") : "󰃟"
    readonly property string label: root.kind === "volume" ? "Volume" : "Brightness"

    function reveal(newKind) {
        root.kind = newKind;
        root.open = true;
        hideTimer.restart();

    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.open = false
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null

        function onVolumeChanged(){
            root.reveal("volume")
        }

        function onMutedChanged(){
            root.reveal("volume")
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged(){
            root.reveal('brightness')
        }
    }


    IpcHandler {
        target: "brightness"

        function refresh(): void {
            Brightness.refresh();
        }
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    Rectangle {
        id: card

        implicitHeight: 64
        implicitWidth: 280

        radius: Appearance.pillRadius
        color: Qt.rgba(Appearance.bg.r, Appearance.bg.g, Appearance.bg.b, 0.92)

        border.width: 1
        border.color: Appearance.hairline

        opacity: root.open ? 1 :0
        scale: root.open ? 1: 0.9

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

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Appearance.shadowColor
            shadowBlur: Appearance.shadowBlur / 32
            shadowVerticalOffset: Appearance.shadowOffsetY
            blurEnabled: false
        }

         RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter
                radius: Appearance.pillRadius
                color: Appearance.surfaceHigh

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: Appearance.fg
                    font.pixelSize: 16
                    font.family: Appearance.fontFamily
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: root.label
                        color: Appearance.fg
                        opacity: 0.85
                        font.pixelSize: 12
                        font.family: Appearance.fontFamily
                    }

                    Text {
                        text: root.muted ? "muted" : Math.round(root.value * 100) + "%"
                        color: Appearance.fg
                        opacity: 0.6
                        font.pixelSize: 12
                        font.family: Appearance.fontFamily
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: Appearance.pillRadius
                    color: Appearance.surfaceHigh

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.max(0, Math.min(1, root.muted ? 0 : root.value))
                        radius: Appearance.pillRadius
                        color: Appearance.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: Appearance.animFast
                            }
                        }
                    }
                }
            }
         }

    }
}