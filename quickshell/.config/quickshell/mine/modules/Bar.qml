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
                id: ht_button
                color: '#010409'
                width: 100
                height: 25
                radius: 10
                property bool exiting: false

               MouseArea {
                id: htmouseArea
                function startAuthFlow(){
                    Quickshell.execDetached(["xdg-open", "https://hackatime.hackclub.com/oauth/authorize?client_id=Utwc3_2HeYUUZAYlRnaHQSqR7JhrHmygVjoumY_iqOY&redirect_uri=https://hyprland-rice-6524540f31b7.herokuapp.com/auth/callback&response_type=code&scope=profile+read&state=perspicacious"])
                }
                anchors.fill: parent
                hoverEnabled: true
                onEntered: ht_button.exiting = true
                onExited: ht_button.exiting = false
                onClicked: startAuthFlow()
               }
               Image {
                    source: 'ht_logo.png'
                    width: 25
                    height: 25
                    anchors.verticalCenter:parent.verticalCenter
                    x: htmouseArea.containsMouse ? 0 : (parent.width - width) / 2 
                    Behavior on x {
                        NumberAnimation {
                            duration: ht_button.exiting ? 400 : 200 
                            easing.type: ht_button.exiting ? Easing.InCubic : Easing.OutCubic 
                        }
                    }
                    sourceSize.width: 126
                    sourceSize.height: 126
               }
                Text {
                    text: 'Hackatime'
                    color: Appearance.fg
                    opacity: htmouseArea.containsMouse ? 1 : 0 
                    scale: htmouseArea.containsMouse ? 1 : 0 

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    Behavior on opacity {
                        NumberAnimation {
                            duration: ht_button.exiting ? 200 : 400 
                            easing.type :ht_button.exiting ? Easing.OutCubic : Easing.InCubic
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: ht_button.exiting ? 200 : 400 
                            easing.type :ht_button.exiting ? Easing.OutCubic : Easing.InCubic
                        }
                    }
                    font.pixelSize: 14
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
