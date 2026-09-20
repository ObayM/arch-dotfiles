import Quickshell
import QtQuick
import qs.modules.services
import qs.config

PanelWindow {
    id: root

    property bool opened: false

    width: 300
    height: 400
    visible: root.opened

    anchors {
        right: true
    }

    function open() {
        Cliphist.refresh();
        root.opened = true;
    }

    function close() {
        root.opened = false;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Appearance.bg.r, Appearance.bg.g, Appearance.bg.b, 1.0)

        ListView {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15
            clip: true
            model: Cliphist.entries

            delegate: Rectangle {
                id: entry

                required property var modelData

                width: ListView.view.width
                height: 70
                radius: 3
                color: Qt.rgba(Appearance.bg.r, Appearance.bg.g, Appearance.bg.b, 0.70)
                border.width: 1
                border.color: Appearance.onAccentContainer

                Text {
                    anchors.fill: parent
                    anchors.margins: 5
                    text: Cliphist.clean(entry.modelData)
                    color: Appearance.fg
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Cliphist.paste(entry.modelData);
                        root.close();
                    }
                }
            }
        }
    }
}
