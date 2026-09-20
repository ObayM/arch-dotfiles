pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config

import qs.modules.common 

PanelWindow {
    id: launcher

    readonly property int rowHeight: 44
    readonly property int maxVisibleRows: 8

    property bool open: false
    property string query: ""
    property int selected: 0

    property var apps: {
        const seen = new Set();
        const out = [];
        for (const e of Array.from(DesktopEntries.applications.values)) {
            if (seen.has(e.id))
                continue;
            seen.add(e.id);
            out.push(e);
        }
        out.sort((a, b) => a.name.localeCompare(b.name));
        return out;
    }

    function matchScore(name, q) {
        name = name.toLowerCase();
        q = q.toLowerCase();
        const idx = name.indexOf(q);
        if (idx === 0)
            return 100;
        if (idx > 0)
            return 50 - idx;

        let ni = 0;
        for (let qi = 0; qi < q.length; qi++) {
            ni = name.indexOf(q[qi], ni);
            if (ni === -1)
                return -1;
            ni++;
        }
        return 10;
    }

    property var results: {
        if (!launcher.query.length)
            return launcher.apps;
        return launcher.apps.map(e => ({
                    entry: e,
                    s: launcher.matchScore(e.name, launcher.query)
                })).filter(r => r.s >= 0).sort((a, b) => b.s - a.s).map(r => r.entry);
    }

    function reset() {
        query = "";
        selected = 0;
        searchField.text = "";
    }

    function launch(entry) {
        if (!entry)
            return;
        entry.execute();
        launcher.open = false;
    }

    property var targetScreen: Quickshell.screens[0]
    screen: launcher.targetScreen

    visible: launcher.open
    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: launcher.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function show() {
        launcher.targetScreen = Array.from(Quickshell.screens).find(s => s.name === (Hyprland.focusedMonitor?.name ?? "")) ?? Quickshell.screens[0];
        reset();
        launcher.open = true;
        Qt.callLater(() => searchField.forceActiveFocus());
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (launcher.open)
                launcher.open = false;
            else
                launcher.show();
        }
        function open(): void {
            launcher.show();
        }
        function close(): void {
            launcher.open = false;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launcher.open = false
    }

    Rectangle {
        id: card

        width: 560
        height: Math.max(rowHeight + 24, Math.min(rowHeight + 24 + resultsList.count * launcher.rowHeight, rowHeight + 24 + launcher.maxVisibleRows * launcher.rowHeight))
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2

        radius: Appearance.radius
        color: Qt.rgba(Appearance.bg.r, Appearance.bg.g, Appearance.bg.b, 0.92)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        opacity: launcher.open ? 1 : 0
        scale: launcher.open ? 1 : 0.97
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animMed
                easing.type: Appearance.easeOutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Appearance.animMed
                easing.type: Appearance.easeOutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Appearance.animFast
                easing.type: Appearance.easeOutCubic
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Appearance.shadowColor
            shadowBlur: Appearance.shadowBlur / 32
            shadowVerticalOffset: Appearance.shadowOffsetY * 1.6
            blurEnabled: false
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Appearance.radius
            anchors.rightMargin: Appearance.radius
            height: 1
            color: Qt.rgba(1, 1, 1, 0.1)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            RowLayout {
                id: searchRow
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: launcher.rowHeight
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 10

                MaterialSymbol {
                    icon: "search"
                    color: Appearance.accent
                    opacity: 0.9
                    iconSize: 19
                }
                

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        text: "Search apps…"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: Appearance.fg
                        opacity: 0.35
                        font.pixelSize: 17
                        font.weight: Font.Medium
                        font.family: Appearance.fontFamily
                        visible: !searchField.text.length
                    }

                    TextInput {
                        id: searchField
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: Appearance.fg
                        font.pixelSize: 17
                        font.weight: Font.Medium
                        font.family: Appearance.fontFamily
                        clip: true
                        selectByMouse: true

                        onTextChanged: {
                            launcher.query = text;
                            launcher.selected = 0;
                        }

                        Keys.onEscapePressed: launcher.open = false
                        Keys.onUpPressed: launcher.selected = Math.max(0, launcher.selected - 1)

                        Keys.onDownPressed: launcher.selected = Math.min(launcher.results.length - 1, launcher.selected + 1)
                        Keys.onReturnPressed: launcher.launch(launcher.results[launcher.selected])
                        Keys.onEnterPressed: launcher.launch(launcher.results[launcher.selected])
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: 1
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                color: Appearance.hairline
                visible: resultsList.count > 0
            }

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: launcher.results
                currentIndex: launcher.selected

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index

                    width: resultsList.width
                    height: launcher.rowHeight

                    readonly property bool isSelected: row.index === launcher.selected

                    Rectangle {
                        id: selectionChip
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        anchors.topMargin: 2
                        anchors.bottomMargin: 2
                        radius: Appearance.pillRadius
                        color: row.isSelected ? Appearance.accentContainer : Appearance.fg
                        opacity: row.isSelected ? 1 : (hover.hovered ? 0.06 : 0)

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animFast
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Appearance.animFast
                            }
                        }

                        Rectangle {
                            visible: row.isSelected
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 1
                            anchors.leftMargin: selectionChip.height / 2
                            anchors.rightMargin: selectionChip.height / 2
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.14)
                        }
                    }

                    HoverHandler {
                        id: hover
                        onHoveredChanged: if (hovered)
                            launcher.selected = row.index
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 12

                        IconImage {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            source: Quickshell.iconPath(row.modelData.icon, "image-missing")
                        }

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            color: row.isSelected ? Appearance.onAccentContainer : Appearance.fg
                            font.weight: row.isSelected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            font.family: Appearance.fontFamily
                            font.pixelSize: 13

                            Behavior on color {
                                ColorAnimation {
                                    duration: Appearance.animFast
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: launcher.launch(row.modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: resultsList.count === 0
                    text: "No results"
                    color: Appearance.fg
                    opacity: 0.4
                    font.family: Appearance.fontFamily
                    font.pixelSize: 13
                }
            }
        }
    }
}
