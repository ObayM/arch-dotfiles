pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.modules.common
import qs.modules.services
import qs.config


PanelWindow {
    id: picker

    readonly property int columns: 3
    readonly property real cellAspect: 16 / 9

    property bool open: false
    property var targetScreen: Quickshell.screens[0]

    screen: picker.targetScreen
    visible: picker.open
    color: "transparent"

    WlrLayershell.namespace: "quickshell:wallpaperpicker"
    WlrLayershell.layer: WlrLayer.Top

    WlrLayershell.keyboardFocus: picker.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function show(forcedScreen) {
        picker.targetScreen = forcedScreen ?? (Array.from(Quickshell.screens).find(s => s.name === (Hyprland.focusedMonitor?.name ?? "")) ?? Quickshell.screens[0]);
    
        picker.open = true;

        Qt.callLater(
            () => card.forceActiveFocus()
        );
    }

        function close () {
            picker.open = false;
        }

        function apply(path, item) {
            if (!path || !path.length)
                return;

            if (item) {
                const p = item.mapToItem(null, item.width / 2, item.height / 2);
                
                Wallpapers.setAt(String(path), Qt.point(picker.targetScreen.x + p.x, picker.targetScreen.y + p.y));
            } else {
                Wallpapers.set(String(path));
            }

            picker.close();
        }

        FolderListModel {
            id: folder

            folder: "file://" + Wallpapers.dir
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
            showDirs: false
            sortField: FolderListModel.Name
        } 
        
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: picker.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animFast
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: picker.close()
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(1180, parent.width * 0.82)
        height: Math.min(760, parent.height * 0.78)

        radius: Appearance.radius * 1.67
        color: Appearance.islandColor
        border.width: 1
        border.color: Appearance.hairline

        focus: true
        opacity: picker.open ? 1 : 0
        scale: picker.open ? 1 : 0.97
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animFast
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.animMed
                easing.type: Appearance.easeOutCubic
            }
        }

        Keys.onEscapePressed: picker.close()
        Keys.onLeftPressed: grid.move(-1)
        Keys.onRightPressed: grid.move(1)
        Keys.onUpPressed: grid.move(-picker.columns)
        Keys.onDownPressed: grid.move(picker.columns)
        Keys.onReturnPressed: grid.activate()
        Keys.onEnterPressed: grid.activate()

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    icon: "wallpaper"
                    iconSize: 18
                    color: Appearance.accent
                }

                Text {
                    text: "Wallpapers"
                    color: Appearance.fg
                    font.family: Appearance.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: folder.count + (folder.count === 1 ? " image" : " images")
                    color: Appearance.fg
                    opacity: 0.45
                    font.family: Appearance.fontFamily
                    font.pixelSize: 12
                }
            }

            GridView {
                id: grid

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                cellWidth: Math.floor(width / picker.columns)
                cellHeight: Math.floor(cellWidth / picker.cellAspect)

                model: folder
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds

                function move(delta) {
                    grid.currentIndex = Math.max(0, Math.min(grid.count - 1, grid.currentIndex + delta));
                    grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
                }

                function activate() {
                    picker.apply(folder.get(grid.currentIndex, "filePath"), grid.currentItem);
                }

                delegate: Item {
                    id: cell

                    required property int index
                    required property string filePath
                    required property string fileName

                    readonly property bool selected: cell.index === grid.currentIndex
                    readonly property bool applied: cell.filePath === Wallpapers.current

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Item {
                        id: tile

                        anchors.fill: parent
                        anchors.margins: 6
                        scale: cell.selected ? 1 : 0.975

                        Behavior on scale {
                            NumberAnimation {
                                duration: Appearance.animFast
                                easing.type: Appearance.easeOutCubic
                            }
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: Appearance.radius
                            color: Appearance.surfaceLow

                            Image {
                                anchors.fill: parent
                                source: "file://" + cell.filePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 480
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 36
                                opacity: cell.selected ? 1 : 0

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: "transparent"
                                    }
                                    GradientStop {
                                        position: 1
                                        color: Qt.rgba(0, 0, 0, 0.72)
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Appearance.animFast
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 8
                                    text: cell.fileName
                                    color: "white"
                                    elide: Text.ElideMiddle
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.radius
                            color: "transparent"
                            border.width: cell.applied || cell.selected ? 2 : 1
                            border.color: cell.applied ? Appearance.accent : (cell.selected ? Appearance.onAccentContainer : Appearance.hairline)

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: Appearance.animFast
                                }
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            width: 22
                            height: 22
                            radius: 11
                            visible: cell.applied
                            color: Appearance.accent

                            MaterialSymbol {
                                anchors.centerIn: parent
                                icon: "check"
                                iconSize: 14
                                color: Appearance.bg
                            }
                        }
                    }

                    HoverHandler {
                        onHoveredChanged: if (hovered)
                            grid.currentIndex = cell.index
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: picker.apply(cell.filePath, tile)
                    }
                }
            }
        }
    }
}
