import QtQuick
import QtQuick.Layouts

import "calendar_layout.js" as CalendarLayout

Item {
    id: calendar

    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout:
        CalendarLayout.getCalendarLayout(
            viewingDate,
            monthShift === 0
        )

    implicitWidth: calendarColumn.implicitWidth
    implicitHeight: calendarColumn.implicitHeight + 20

    focus: true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_PageDown &&
            event.modifiers === Qt.NoModifier) {

            monthShift++
            event.accepted = true

        } else if (event.key === Qt.Key_PageUp &&
                   event.modifiers === Qt.NoModifier) {

            monthShift--
            event.accepted = true
        }
    }

    MouseArea {
        anchors.fill: parent

        onWheel: (event) => {
            if (event.angleDelta.y > 0)
                monthShift--
            else if (event.angleDelta.y < 0)
                monthShift++
        }
    }

    ColumnLayout {
        id: calendarColumn

        anchors.centerIn: parent

        spacing: 5

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38

                radius: 10
                color: "transparent"

                Text {
                    anchors.fill: parent

                    leftPadding: 10

                    text: monthShift !== 0
                          ? "• " + viewingDate.toLocaleDateString(
                                Qt.locale(),
                                "MMMM yyyy"
                            )
                          : viewingDate.toLocaleDateString(
                                Qt.locale(),
                                "MMMM yyyy"
                            )

                    verticalAlignment: Text.AlignVCenter

                    font.pixelSize: 16
                    font.weight: Font.DemiBold

                    color: "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        monthShift = 0
                    }
                }
            }

            Rectangle {
                implicitWidth: 38
                implicitHeight: 38

                radius: width / 2
                color: "transparent"

                Text {
                    anchors.fill: parent

                    text: "‹"

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    font.pixelSize: 28
                    color: "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        monthShift--
                    }
                }
            }

            Rectangle {
                implicitWidth: 38
                implicitHeight: 38

                radius: width / 2
                color: "transparent"

                Text {
                    anchors.fill: parent

                    text: "›"

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    font.pixelSize: 28
                    color: "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        monthShift++
                    }
                }
            }
        }

        // Weekday names
        RowLayout {
            id: weekDaysRow

            Layout.alignment: Qt.AlignHCenter

            spacing: 5

            Repeater {
                model: CalendarLayout.weekDays

                delegate: CalendarDayButton {
                    day: modelData.day
                    isToday: modelData.today
                    bold: true
                }
            }
        }

        // Calendar
        Repeater {
            model: 6

            delegate: RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                spacing: 5

                Repeater {
                    model: Array(7).fill(modelData)

                    delegate: CalendarDayButton {
                        day: calendarLayout[modelData][index].day
                        isToday: calendarLayout[modelData][index].today
                    }
                }
            }
        }
    }
}