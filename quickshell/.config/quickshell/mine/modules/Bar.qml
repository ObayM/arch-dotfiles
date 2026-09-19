pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config

Variants {
    id: root
    required property string token
    model: Quickshell.screens

    component Group: Item {
        id: group

        property Item inner: null
        property real hPadding: 12
        readonly property alias hovered: hoverHandler.hovered

        implicitWidth: (group.inner ? group.inner.implicitWidth : 0) + hPadding * 2
        implicitHeight: Appearance.barHeight - 12
        width: implicitWidth
        height: implicitHeight

        HoverHandler {
            id: hoverHandler
        }

        Rectangle {
            anchors.fill: parent
            radius: Appearance.pillRadius
            color: Appearance.fg
            opacity: group.hovered ? 0.08 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animFast
                }
            }
        }
    }

    component Divider: Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        radius: 0.5
        color: Appearance.hairline
    }

    PanelWindow {
        id: bar

        required property var modelData
        property bool showTracked: false
        property bool exiting: false
        property string ptoken: root.token
        property string displayed_info: 'Hackatime'

        screen: modelData

        WlrLayershell.namespace: "quickshell:bar"

        Timer {
            id: displayTimer
            interval: 5000
            running: false
            repeat: true
            onTriggered: {
                exiting = showTracked
                showTracked = !showTracked
            }
        }

        function startTodayTimeFetch() {
            var xhr = new XMLHttpRequest()
            var today = new Date().toISOString().split('T')[0]
            xhr.open("GET", "https://hackatime.hackclub.com/api/v1/authenticated/hours?start_date=" + today + "&end_date=" + today)
            xhr.setRequestHeader("Authorization", "Bearer " + bar.ptoken)
            xhr.setRequestHeader("Accept", "application/json")

            xhr.onreadystatechange = function () {
                if (xhr.readyState !== XMLHttpRequest.DONE) return
                var trackedTime = (+JSON.parse(xhr.responseText).total_seconds / 3600).toFixed(2)
                displayed_info = trackedTime + 'h'
                displayTimer.running = true
            }
            xhr.send()
        }

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: Appearance.margin
            left: Appearance.margin
            right: Appearance.margin
        }

        implicitHeight: Appearance.barHeight

        exclusiveZone: Appearance.barHeight + Appearance.margin
        color: "transparent"

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Rectangle {
            id: surfaceBg
            anchors.fill: parent
            radius: Appearance.radius
            color: Qt.rgba(Appearance.surface.r, Appearance.surface.g, Appearance.surface.b, Appearance.surfaceOpacity)
            border.width: 1
            border.color: Appearance.hairline

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Appearance.shadowColor
                shadowBlur: Appearance.shadowBlur / 64
                shadowVerticalOffset: Appearance.shadowOffsetY
                shadowHorizontalOffset: 0
                blurEnabled: false
            }
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Group {
                    inner: wsContainer

                    Item {
                        id: wsContainer

                        anchors.centerIn: parent
                        implicitWidth: wsRow.implicitWidth
                        implicitHeight: 20
                        width: implicitWidth
                        height: implicitHeight

                        function syncIndicator(item: Item): void {
                            indicator.x = item.x - 8;
                            indicator.width = item.width + 16;
                        }

                        Rectangle {
                            id: indicator
                            anchors.verticalCenter: parent.verticalCenter
                            height: 20
                            radius: Appearance.pillRadius
                            color: Appearance.accent
                            x: 0
                            width: 0

                            Behavior on x {
                                NumberAnimation {
                                    duration: Appearance.animMed
                                    easing.type: Appearance.easeOutCubic
                                }
                            }
                            Behavior on width {
                                NumberAnimation {
                                    duration: Appearance.animMed
                                    easing.type: Appearance.easeOutCubic
                                }
                            }
                        }

                        Row {
                            id: wsRow
                            anchors.fill: parent
                            spacing: 14

                            Repeater {
                                model: Hyprland.workspaces.values

                                Item {
                                    id: ws

                                    required property var modelData
                                    readonly property bool active: Hyprland.focusedWorkspace?.id === ws.modelData.id
                                    readonly property bool occupied: (ws.modelData.toplevels?.values.length ?? 0) > 0

                                    width: label.implicitWidth
                                    height: wsRow.height

                                    onActiveChanged: if (ws.active) wsContainer.syncIndicator(ws)
                                    onXChanged: if (ws.active) wsContainer.syncIndicator(ws)
                                    Component.onCompleted: if (ws.active) wsContainer.syncIndicator(ws)

                                    Text {
                                        id: label
                                        anchors.centerIn: parent
                                        text: ws.modelData.id
                                        color: ws.active ? Appearance.bg : Appearance.fg
                                        opacity: ws.active ? 1 : (ws.occupied ? 0.7 : 0.3)
                                        font.family: Appearance.fontFamily
                                        font.pixelSize: 12
                                        font.bold: ws.active

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Appearance.animMed
                                            }
                                        }
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Appearance.animMed
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + ws.modelData.id + "})")
                                    }
                                }
                            }
                        }

                        WheelHandler {
                            property real acc: 0

                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                acc += event.angleDelta.y;
                                if (Math.abs(acc) < 120)
                                    return;
                                const scenePos = wsContainer.mapToItem(null, event.x, event.y);
                                const cx = Math.round(bar.modelData.x + scenePos.x);
                                const cy = Math.round(bar.modelData.y + scenePos.y);

                                Hyprland.dispatch(acc > 0 ? 'hl.dsp.focus({workspace = "r-1"})' : 'hl.dsp.focus({workspace = "r+1"})');
                                Hyprland.dispatch(`hl.dsp.cursor.move({x = ${cx}, y = ${cy}})`);
                                acc = 0;
                            }
                        }
                    }
                }

                Divider {
                    visible: appLabel.text.length > 0
                }

                Text {
                    id: appLabel
                    Layout.alignment: Qt.AlignVCenter
                    text: ToplevelManager.activeToplevel?.appId ?? ""
                    color: Appearance.fg
                    opacity: 0.6
                    font.family: Appearance.fontFamily
                    font.pixelSize: 12
                    font.capitalization: Font.Capitalize
                    elide: Text.ElideRight
                    Layout.maximumWidth: 200
                }
            }

            Group {
                id: clockGroup

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                inner: clockRow

                RowLayout {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        text: Qt.formatDateTime(clock.date, "hh:mm")
                        color: Appearance.fg
                        font.family: Appearance.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 0.4
                    }

                    Item {
                        clip: true
                        Layout.preferredWidth: clockGroup.hovered ? expanded.implicitWidth + 8 : 0
                        Layout.preferredHeight: expanded.implicitHeight

                        Behavior on Layout.preferredWidth {
                            NumberAnimation {
                                duration: Appearance.animMed
                                easing.type: Appearance.easeOutCubic
                            }
                        }

                        RowLayout {
                            id: expanded
                            anchors.right: parent.right
                            spacing: 8
                            opacity: clockGroup.hovered ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Appearance.animFast
                                }
                            }

                            Text {
                                text: "·"
                                color: Appearance.fg
                                opacity: 0.4
                                font.family: Appearance.fontFamily
                                font.pixelSize: 12
                            }

                            Text {
                                text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                                color: Appearance.fg
                                opacity: 0.6
                                font.family: Appearance.fontFamily
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Rectangle {
                    id: ht_button
                    color: '#010409'
                    width: 100
                    height: 25
                    radius: 10

                    MouseArea {
                        id: htmouseArea
                        function startAuthFlow() {
                            Quickshell.execDetached(["xdg-open", "https://hackatime.hackclub.com/oauth/authorize?client_id=Utwc3_2HeYUUZAYlRnaHQSqR7JhrHmygVjoumY_iqOY&redirect_uri=https://hyprland-rice-6524540f31b7.herokuapp.com/auth/callback&response_type=code&scope=profile+read&state=perspicacious"])
                        }
                        function openHackatimeDashboard() {
                        }
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: bar.exiting = true
                        onExited: bar.exiting = false
                        onClicked: {
                            if (bar.ptoken !== '') {
                                openHackatimeDashboard()
                            } else {
                                startAuthFlow()
                            }
                        }
                    }
                    Image {
                        source: 'ht_logo.png'
                        width: 25
                        height: 25
                        anchors.verticalCenter: parent.verticalCenter
                        x: bar.showTracked ? 0 : htmouseArea.containsMouse ? 0 : (parent.width - width) / 2
                        Behavior on x {
                            NumberAnimation {
                                duration: bar.exiting ? 400 : 200
                                easing.type: bar.exiting ? Easing.InCubic : Easing.OutCubic
                            }
                        }
                        sourceSize.width: 126
                        sourceSize.height: 126
                    }
                    Text {
                        text: bar.displayed_info
                        color: Appearance.fg
                        opacity: bar.showTracked ? 1 : htmouseArea.containsMouse ? 1 : 0
                        scale: bar.showTracked ? 1 : htmouseArea.containsMouse ? 1 : 0

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        Behavior on opacity {
                            NumberAnimation {
                                duration: bar.exiting ? 200 : 400
                                easing.type: bar.exiting ? Easing.OutCubic : Easing.InCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: bar.exiting ? 200 : 400
                                easing.type: bar.exiting ? Easing.OutCubic : Easing.InCubic
                            }
                        }
                        font.pixelSize: 14
                        font.family: Appearance.fontFamily
                    }
                }

                Group {
                    inner: trayRow
                    visible: SystemTray.items.values.length > 0

                    RowLayout {
                        id: trayRow
                        anchors.centerIn: parent
                        spacing: 12

                        Repeater {
                            model: SystemTray.items.values

                            MouseArea {
                                id: trayItem

                                required property var modelData

                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 15
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onClicked: event => {
                                    if (event.button === Qt.LeftButton)
                                        trayItem.modelData.activate();
                                    else
                                        trayItem.modelData.secondaryActivate();
                                }

                                IconImage {
                                    anchors.fill: parent
                                    source: trayItem.modelData.icon
                                    opacity: trayItem.containsMouse ? 1 : 0.7

                                    Behavior on opacity {
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
        }

        onPtokenChanged: {
            if (ptoken !== '') {
                startTodayTimeFetch()
            }
        }
    }
}
