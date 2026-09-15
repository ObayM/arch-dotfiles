pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Appearance.barHeight
        color: Appearance.bg

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            RowLayout {
                spacing: 5

                Repeater {
                    model: Hyprland.workspaces.values

                    Rectangle {
                        required property var modelData
                        readonly property bool active: Hyprland.focusedWorkspace?.id === modelData.id

                        implicitWidth: active ? 30 : 14
                        implicitHeight: 14
                        radius: height / 2
                        color: active ? Appearance.accent : Appearance.surface

                        Behavior on implicitWidth {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + modelData.id)
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
            Rectangle {
                color: '#010409'
                width: 60
                height: 20
                radius: 10
               MouseArea {
                function greet(){
                    console.log('hi sofa')
                }
                anchors.fill: parent
                onClicked: greet()
               }
               Image {
                    source: 'gh_logo.svg'
                    width: 15
                    height: 15
                    anchors.left:parent.left
                    anchors.verticalCenter:parent.verticalCenter
                    sourceSize.width: 32
                    sourceSize.height: 32
               }
                Text {
                    text: 'Github'
                    color: Appearance.fg
                    anchors.right: parent.right
                    anchors.rightMargin: 9
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 11
                    font.family: Appearance.fontFamily
                }
               
            }

            Text {
                text: Qt.formatDateTime(clock.date, "ddd d MMM   hh:mm")
                color: Appearance.fg
                font.family: Appearance.fontFamily
                font.pixelSize: 13
            }
        }
    }
}
