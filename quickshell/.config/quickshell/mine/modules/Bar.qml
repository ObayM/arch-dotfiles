pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import qs.config

Variants {
    id: root
    required property string token
    model: Quickshell.screens

    component Island: Item {
        id: island

        property Item inner: null
        property real hPadding: 14
        readonly property alias hovered: hoverHandler.hovered

        implicitWidth: (island.inner ? island.inner.implicitWidth : 0) + hPadding * 2
        implicitHeight: Appearance.islandHeight
        width: implicitWidth
        height: implicitHeight

        HoverHandler {
            id: hoverHandler
        }

        Rectangle {
            anchors.fill: parent
            radius: Appearance.pillRadius
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

        Rectangle {
            anchors.fill: parent
            radius: Appearance.pillRadius
            color: Appearance.fg
            opacity: island.hovered ? 0.04 : 0

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
        Layout.topMargin: 7
        Layout.bottomMargin: 7
        radius: 0.5
        color: Appearance.hairline
    }

    PanelWindow {
        id: bar

        required property var modelData
        property bool showTracked: false
        property string ptoken: root.token
        property string displayed_info: 'Hackatime'
        property string netConnType: 'none'
        property int netSignal: 0

        screen: modelData

        WlrLayershell.namespace: "quickshell:bar"

        Timer {
            id: displayTimer
            interval: 5000
            running: false
            repeat: true
            onTriggered: bar.showTracked = !bar.showTracked
        }

        Timer {
            id: refreshTimer
            interval: 5 * 60 * 1000
            running: bar.ptoken !== ''
            repeat: true
            onTriggered: bar.fetchTodayTime()
        }

        Timer {
            id: netRefreshTimer
            interval: 30 * 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: bar.refreshNetwork()
        }

        function refreshNetwork() {
            netTypeProcess.running = true
        }

        Process {
            id: netMonitorProcess
            running: true
            command: ["nmcli", "monitor"]
            stdout: SplitParser {
                onRead: bar.refreshNetwork()
            }
        }

        Process {
            id: netTypeProcess
            command: ["sh", "-c", "nmcli -t -f TYPE,STATE device status | grep ':connected$' | head -1"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const line = this.text.trim()
                    if (line.startsWith("wifi:")) {
                        bar.netConnType = "wifi"
                        netSignalProcess.running = true
                    } else if (line.startsWith("ethernet:")) {
                        bar.netConnType = "ethernet"
                        bar.netSignal = 0
                    } else {
                        bar.netConnType = "none"
                        bar.netSignal = 0
                    }
                }
            }
        }

        Process {
            id: netSignalProcess
            command: ["sh", "-c", "nmcli -t -f active,signal dev wifi | grep '^yes:' | head -1"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const value = parseInt(this.text.trim().split(":")[1])
                    bar.netSignal = isNaN(value) ? 0 : value
                }
            }
        }

        function fetchTodayTime() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "https://hackatime.hackclub.com/api/hackatime/v1/users/current/statusbar/today")
            xhr.setRequestHeader("Authorization", "Bearer " + bar.ptoken)
            xhr.setRequestHeader("Accept", "application/json")

            xhr.onreadystatechange = function () {
                if (xhr.readyState !== XMLHttpRequest.DONE) return
                if (xhr.status !== 200) {
                    console.log("Hackatime fetch failed:", xhr.status)
                    return
                }
                displayed_info = JSON.parse(xhr.responseText).data.grand_total.text
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

        Item {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Island {
                id: leftIsland
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                inner: leftRow

                RowLayout {
                    id: leftRow
                    anchors.centerIn: parent
                    spacing: 14

                    Item {
                        id: wsContainer

                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: wsRow.implicitWidth
                        implicitHeight: 20

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
            }

            Island {
                id: centerIsland

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
                        Layout.preferredWidth: centerIsland.hovered ? expanded.implicitWidth + 8 : 0
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
                            opacity: centerIsland.hovered ? 1 : 0

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

            Island {
                id: rightIsland
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                inner: rightRow

                RowLayout {
                    id: rightRow
                    anchors.centerIn: parent
                    spacing: 14

                    Text {
                        id: networkIcon
                        Layout.alignment: Qt.AlignVCenter
                        text: bar.netConnType === "ethernet" ? "" : ""
                        color: Appearance.fg
                        opacity: bar.netConnType === "none" ? 0.3 : (bar.netConnType === "wifi" ? Math.max(0.35, bar.netSignal / 100) : 0.85)
                        font.family: Appearance.fontFamily
                        font.pixelSize: 13

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.refreshNetwork()
                        }
                    }

                    Item {
                        id: volumeWidget
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: volumeRow.implicitWidth
                        implicitHeight: volumeRow.implicitHeight
                        visible: sink !== null

                        readonly property var sink: Pipewire.defaultAudioSink
                        readonly property bool muted: volumeWidget.sink?.audio.muted ?? false
                        readonly property int vol: Math.round((volumeWidget.sink?.audio.volume ?? 0) * 100)

                        PwObjectTracker {
                            objects: volumeWidget.sink ? [volumeWidget.sink] : []
                        }

                        RowLayout {
                            id: volumeRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: volumeWidget.muted ? "" : volumeWidget.vol > 50 ? "" : volumeWidget.vol > 0 ? "" : ""
                                color: Appearance.fg
                                opacity: volumeWidget.muted ? 0.4 : 0.85
                                font.family: Appearance.fontFamily
                                font.pixelSize: 14
                            }

                            Text {
                                text: volumeWidget.muted ? "mute" : volumeWidget.vol + "%"
                                color: Appearance.fg
                                opacity: 0.85
                                font.family: Appearance.fontFamily
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (volumeWidget.sink)
                                    volumeWidget.sink.audio.muted = !volumeWidget.sink.audio.muted
                            }
                        }

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                if (!volumeWidget.sink)
                                    return;
                                const step = 0.05;
                                const delta = event.angleDelta.y > 0 ? step : -step;
                                volumeWidget.sink.audio.volume = Math.max(0, Math.min(1.5, volumeWidget.sink.audio.volume + delta));
                            }
                        }
                    }

                    Item {
                        id: batteryWidget
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: batteryRow.implicitWidth
                        implicitHeight: batteryRow.implicitHeight
                        visible: UPower.displayDevice.isLaptopBattery

                        readonly property alias hovered: batteryHover.hovered
                        readonly property int pct: Math.round((UPower.displayDevice.percentage ?? 0) * 100)
                        readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
                        
                        readonly property string timeText: {
                            const secs = batteryWidget.charging ? UPower.displayDevice.timeToFull : UPower.displayDevice.timeToEmpty;
                            if (!secs || secs <= 0)
                                return "";
                            const h = Math.floor(secs / 3600);
                            const m = Math.round((secs % 3600) / 60);
                            return h > 0 ? (h + "h " + m + "m") : (m + "m");
                        }

                        HoverHandler {
                            id: batteryHover
                        }

                        RowLayout {
                            id: batteryRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: batteryWidget.charging ? "" : batteryWidget.pct >= 90 ? "" : batteryWidget.pct >= 60 ? "" : batteryWidget.pct >= 35 ? "" : batteryWidget.pct >= 15 ? "" : ""
                                color: Appearance.fg
                                opacity: batteryWidget.charging ? 1 : 0.85
                                font.family: Appearance.fontFamily
                                font.pixelSize: 14
                            }

                            Text {
                                text: batteryWidget.pct + "%"
                                color: Appearance.fg
                                opacity: 0.85
                                font.family: Appearance.fontFamily
                                font.pixelSize: 12
                            }

                            Item {
                                clip: true
                                Layout.preferredWidth: batteryWidget.hovered && batteryTime.text.length > 0 ? batteryTime.implicitWidth + 6 : 0
                                Layout.preferredHeight: batteryTime.implicitHeight

                                Behavior on Layout.preferredWidth {
                                    NumberAnimation {
                                        duration: Appearance.animMed
                                        easing.type: Appearance.easeOutCubic
                                    }
                                }

                                Text {
                                    id: batteryTime
                                    text: batteryWidget.timeText
                                    color: Appearance.fg
                                    opacity: batteryWidget.hovered ? 0.6 : 0
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: 12

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Appearance.animFast
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Divider {}

                    Item {
                        id: htWidget
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: htRow.implicitWidth
                        implicitHeight: 18

                        readonly property alias hovered: htHover.hovered
                        readonly property bool revealed: bar.showTracked || htWidget.hovered

                        HoverHandler {
                            id: htHover
                        }

                        RowLayout {
                            id: htRow
                            anchors.centerIn: parent
                            spacing: 6

                            Image {
                                source: 'ht_logo.png'
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                sourceSize.width: 64
                                sourceSize.height: 64
                                opacity: 0.9
                            }

                            Item {
                                clip: true
                                Layout.preferredWidth: htWidget.revealed ? htLabel.implicitWidth : 0
                                Layout.preferredHeight: htLabel.implicitHeight

                                Behavior on Layout.preferredWidth {
                                    NumberAnimation {
                                        duration: Appearance.animMed
                                        easing.type: Appearance.easeOutCubic
                                    }
                                }

                                Text {
                                    id: htLabel
                                    text: bar.displayed_info
                                    color: Appearance.fg
                                    opacity: htWidget.revealed ? 0.85 : 0
                                    font.pixelSize: 12
                                    font.family: Appearance.fontFamily

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Appearance.animFast
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["xdg-open", "https://hackatime.hackclub.com"])
                        }
                    }

                    Divider {
                        visible: SystemTray.items.values.length > 0
                    }

                    RowLayout {
                        id: trayRow
                        Layout.alignment: Qt.AlignVCenter
                        visible: SystemTray.items.values.length > 0
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
                fetchTodayTime()
            } else {
                displayed_info = 'Hackatime'
            }
        }
    }
}
