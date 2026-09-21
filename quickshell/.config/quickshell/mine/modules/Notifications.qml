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

import Quickshell.Hyprland
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null    
    WlrLayershell.namespace: "quickshell:notifications"
    color: "transparent"
    visible: NotificationsService.list.values.length > 0

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
            delegate: Item {
                    id: cardWrapper

                    required property Notification modelData

                    Layout.fillWidth: true
                    implicitHeight: card.implicitHeight
                    
                    Rectangle {
                        id: card
                        
                        readonly property int timeoutMs: cardWrapper.modelData.expireTimeout > 0 ? cardWrapper.modelData.expireTimeout * 1000 : 5000

                        width: parent.width

                        implicitHeight: contentCol.implicitHeight + 24
                        radius: Appearance.radius
                        color: Qt.rgba(Appearance.bg.r, Appearance.bg.g, Appearance.bg.b, 0.92)
                        border.width: 1
                        border.color: Appearance.hairline
                        opacity: 1 - Math.min(1, Math.abs(card.x) / (card.width * 0.9))

                        DragHandler {
                            id: dragHandler
                            target: card
                            yAxis.enabled: false

                            onActiveChanged: {
                                if (dragHandler.active)
                                    return;

                                if (Math.abs(card.x) > card.width * 0.35) {
                                    flyOut.to = card.x > 0 ? card.width * 1.4 : -card.width * 1.4;
                                    flyOut.start();

                                } else {
                                    snapBack.start();
                                }
                            }
                        }


                        NumberAnimation {
                            id: snapBack
                            target: card
                            property: "x"
                            to: 0
                            duration: Appearance.animMed
                            easing.type: Appearance.easeOutCubic
                        }

                        NumberAnimation {
                            id: flyOut
                            target: card
                            property: "x"
                            duration: Appearance.animFast
                            onStopped: cardWrapper.modelData.dismiss()
                        }

                        HoverHandler {
                            id: hover
                        }

                        Timer {
                            interval: card.timeoutMs
                            running: !hover.hovered && !dragHandler.active 
                            onTriggered: cardWrapper.modelData.expire()
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
                                source: Quickshell.iconPath(cardWrapper.modelData.appIcon, "dialog-information")
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cardWrapper.modelData.summary
                                color: Appearance.fg
                                font.weight: Font.DemiBold
                                font.family: Appearance.fontFamily
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: cardWrapper.modelData.body.length > 0
                            text: cardWrapper.modelData.body
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
   
}
