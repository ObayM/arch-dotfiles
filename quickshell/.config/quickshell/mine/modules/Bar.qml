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
        property bool showTracked;
        property bool exiting: false

        screen: modelData
        Timer {
            id:displayTimer
            interval: 5000
            running:false
            repeat:true
            onTriggered:{
                exiting = showTracked
                showTracked = !showTracked
            }
        }
        function startTodayTimeFetch(){
            var xhr = new XMLHttpRequest()
            var today = new Date().toISOString().split('T')[0]
            xhr.open("GET","https://hackatime.hackclub.com/api/v1/authenticated/hours?start_date=" + today + "&end_date=" + today)
            xhr.setRequestHeader("Authorization","Bearer "+ panel.ptoken)
            xhr.setRequestHeader("Accept","application/json")

            xhr.onreadystatechange = function () {
                if (xhr.readyState !== XMLHttpRequest.DONE)return
                var trackedTime = (+JSON.parse(xhr.responseText).total_seconds / 3600).toFixed(2)
                displayed_info = trackedTime +  'h'
                displayTimer.running = true
            }
            xhr.send()
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
                onEntered: panel.exiting = true
                onExited: panel.exiting = false
                onClicked: { 
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
                    x: panel.showTracked ? 0 : htmouseArea.containsMouse ? 0 : (parent.width - width) / 2 
                    Behavior on x {
                        NumberAnimation {
                            duration: panel.exiting ? 400 : 200 
                            easing.type: panel.exiting ? Easing.InCubic : Easing.OutCubic 
                        }
                    }
                    sourceSize.width: 126
                    sourceSize.height: 126
               }
                Text {
                    text: panel.displayed_info
                    color: Appearance.fg
                    opacity: panel.showTracked ?1 : htmouseArea.containsMouse ? 1 : 0 
                    scale: panel.showTracked ? 1: htmouseArea.containsMouse ? 1 : 0 

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    Behavior on opacity {
                        NumberAnimation {
                            duration: panel.exiting ? 200 : 400 
                            easing.type :panel.exiting ? Easing.OutCubic : Easing.InCubic
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: panel.exiting ? 200 : 400 
                            easing.type :panel.exiting ? Easing.OutCubic : Easing.InCubic
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
        onPtokenChanged: {
            if(ptoken !== ''){
                startTodayTimeFetch()

            }
        }
    }
}
