pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.modules.services
import qs.config


PanelWindow {
    id: root

    screen: Quickshell.screens[0]

    WlrLayershell.namespace: "quickshell:notifications"
    color: "transparent"

    anchors {
        top: true
        right: true
    }

    margins {
        top: Appearance.margin
        right: Appearance.margin
    }

    implicitWidth: 340
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
        model: NotificationsService.list.values
        delegate: Rectangle {
                    id: card

                    required property Notification modelData

                    readonly property int timeoutMs: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout * 1000 : 5000

                    Layout.fillWidth: true
                    implicitHeight: contentCol.implicitHeight + 24
                    radius: Appearance.radius
                    color: Qt.rgba(Appearance.bg.r, Appearance.bg.g, Appearance.bg.b, 0.92)
                    border.width: 1
                    border.color: Appearance.hairline

                    HoverHandler {
                        id: hover
                    }

                    Timer {
                        interval: card.timeoutMs
                        running: !hover.hovered
                        onTriggered: card.modelData.expire()
                    }

                    ColumnLayout {
                        id: contentCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            IconImage {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                source: Quickshell.iconPath(card.modelData.appIcon, "dialog-information")
                            }

                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.summary
                                color: Appearance.fg
                                font.weight: Font.DemiBold
                                font.family: Appearance.fontFamily
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: card.modelData.body.length > 0
                            text: card.modelData.body
                            color: Appearance.fg
                            opacity: 0.75
                            font.family: Appearance.fontFamily
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                        }
                    }
                }
        }
    
    }
   
}
