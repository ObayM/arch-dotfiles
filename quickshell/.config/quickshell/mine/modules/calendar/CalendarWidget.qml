pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.common

Item {
    id: root

    property int monthShift: 0
    property int firstDayOfWeek: Locale.Monday

    readonly property var locale: Qt.locale()
    readonly property real cellSpacing: 3
    readonly property real rowSpacing: 2
    readonly property real headerHeight: 32
    readonly property real weekDayHeight: 20
    readonly property real cellSize: (width - cellSpacing * 6) / 7

    implicitWidth: 280
    implicitHeight: headerHeight + weekDayHeight + cellSize * 6 + rowSpacing * 5 + Appearance.spacingS * 2

    readonly property date viewing: {
        const now = clock.date;
        return new Date(now.getFullYear(), now.getMonth() + root.monthShift, 1);
    }

    readonly property int focusedMonth: viewing.getMonth() + 1

    readonly property var weekDays: {
        const names = [];
        for (let i = 0; i < 7; i++)
            names.push(root.locale.dayName((root.firstDayOfWeek + i) % 7, Locale.ShortFormat).slice(0, 2));
        return names;
    }

    readonly property var weeks: {
        const now = clock.date;
        const first = root.viewing;
        const offset = (first.getDay() - root.firstDayOfWeek + 7) % 7;
        const rows = [];
        for (let w = 0; w < 6; w++) {
            const days = [];
            for (let d = 0; d < 7; d++) {
                const date = new Date(first.getFullYear(), first.getMonth(), 1 - offset + w * 7 + d);
                days.push({
                    day: date.getDate(),
                    month: date.getMonth() + 1,
                    today: date.getDate() === now.getDate() && date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear()
                });
            }
            rows.push(days);
        }
        return rows;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.monthShift += event.angleDelta.y > 0 ? -1 : 1
    }

    component NavButton: Rectangle {
        id: navButton

        property string icon
        signal triggered

        implicitWidth: root.headerHeight
        implicitHeight: root.headerHeight
        radius: height / 2

        color: tap.pressed ? Appearance.accentContainer : navHover.hovered ? Appearance.surfaceHigh : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animFast
            }
        }

        HoverHandler {
            id: navHover
        }

        TapHandler {
            id: tap
            onTapped: navButton.triggered()
        }

        MaterialSymbol {
            anchors.centerIn: parent
            icon: navButton.icon
            iconSize: 18
            color: Appearance.fg
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacingS

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            spacing: 0

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 6

                text: Qt.formatDateTime(root.viewing, "MMMM yyyy")
                elide: Text.ElideRight

                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeLarge
                font.weight: Font.DemiBold
                color: Appearance.fg
            }

            NavButton {
                icon: "chevron_left"
                onTriggered: root.monthShift--
            }

            NavButton {
                icon: "today"
                opacity: root.monthShift === 0 ? 0 : 1
                visible: opacity > 0
                onTriggered: root.monthShift = 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animFast
                    }
                }
            }

            NavButton {
                icon: "chevron_right"
                onTriggered: root.monthShift++
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.weekDayHeight
            spacing: root.cellSpacing

            Repeater {
                model: root.weekDays

                delegate: Text {
                    required property string modelData

                    Layout.preferredWidth: root.cellSize
                    Layout.fillHeight: true

                    text: modelData
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Appearance.accent
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.rowSpacing

            Repeater {
                model: root.weeks

                delegate: RowLayout {
                    id: weekRow

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: root.cellSpacing

                    Repeater {
                        model: weekRow.modelData

                        delegate: CalendarDayButton {
                            required property var modelData

                            Layout.preferredWidth: root.cellSize
                            Layout.preferredHeight: root.cellSize

                            model: modelData
                            focusedMonth: root.focusedMonth
                        }
                    }
                }
            }
        }
    }
}
