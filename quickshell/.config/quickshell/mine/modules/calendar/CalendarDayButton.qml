import QtQuick
import QtQuick.Layouts

Rectangle {
    id: button

    property string day: ""
    property int isToday: 0
    property bool bold: false

    implicitWidth: 38
    implicitHeight: 38

    radius: 10

    color: isToday === 1
           ? "#3f51b5"
           : "transparent"

    border.width: isToday === 1 ? 0 : 0

    Text {
        anchors.fill: parent

        text: button.day

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        font.weight: button.bold ? Font.DemiBold : Font.Normal
        font.pixelSize: 14

        color: button.isToday === 1
               ? "white"
               : button.isToday === 0
                 ? "#ffffff"
                 : "#777777"
    }

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            if (button.isToday !== 1)
                button.color = "#252525"
        }

        onExited: {
            if (button.isToday !== 1)
                button.color = "transparent"
        }
    }
}