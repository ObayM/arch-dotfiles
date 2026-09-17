pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import Quickshell.Io
Variants {
    id: bar
    required property string token;
    model: Quickshell.screens
    PanelWindow {
        id:panel
        property string ptoken: bar.token;
        property string displayed_info: 'Hackatime'
        required property var modelData
        screen: modelData

        function startTodayTimeFetch(){
            console.log('yes')
            todayTimeProcess.running = true
        }
        Process {
            id: todayTimeProcess

            command: [
                "curl",
                "-s",
                "-H", "Authorization: Bearer " + panel.token,
                "https://hackatime.hackclub.com/api/v1/authenticated/hours?start_date=" +
                Qt.formatDate(new Date(), "yyyy-MM-dd") +
                "&end_date=" +
                Qt.formatDate(new Date(), "yyyy-MM-dd")
            ]

            stdout: StdioCollector {
                onStreamFinished: {
                    var data = JSON.parse(text)
                    panel.displayed_info = data.total_seconds
                    console.log("Today's seconds:", data.total_seconds)
                }
            }
        }
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
                function openHackatimeDashboard(){
                    // Hackatime Dashboard for later
                }
                anchors.fill: parent
                hoverEnabled: true
                onEntered: ht_button.exiting = true
                onExited: ht_button.exiting = false
                onClicked: { 
                    console.log(ptoken)
                    if(panel.ptoken !== ''){
                        openHackatimeDashboard()
                    }else{
                        startAuthFlow()

                    }
                }
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
                    text: panel.displayed_info
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
        Component.onCompleted: {
            console.log(ptoken)
            if (token !== '') {
                startTodayTimeFetch()
            }
        }
    }
}
