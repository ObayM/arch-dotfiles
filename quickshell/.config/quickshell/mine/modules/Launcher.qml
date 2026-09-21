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
import qs.modules.services

PanelWindow {
    id: launcher

    readonly property int rowHeight: 44
    readonly property int maxVisibleRows: 8

    property bool open: false
    property string query: ""
    property int selected: 0

    readonly property string clipPrefix: ";"
    readonly property string mathPrefix: "="
    readonly property bool clipMode: launcher.query.startsWith(launcher.clipPrefix)

    property string calcResult: ""
    readonly property bool hasCalc: launcher.calcResult.length > 0
    function isMathQuery(q) {
        if (q.startsWith(launcher.clipPrefix))
            return false;
        return q.startsWith(launcher.mathPrefix) || /^[\d(.]/.test(q);
    }

    function mathExpression(q) {
        return q.startsWith(launcher.mathPrefix) ? q.slice(launcher.mathPrefix.length) : q;
    }

    onQueryChanged: {
        if (launcher.isMathQuery(launcher.query)) {
            mathDebounce.restart();
        } else {
            mathDebounce.stop();
            launcher.calcResult = "";
        }
    }

    Timer {
        id: mathDebounce
        interval: 80
        onTriggered: mathProc.calculate(launcher.mathExpression(launcher.query))
    }

    Process {
        id: mathProc

        function calculate(expression) {
            mathProc.running = false;
            mathProc.command = ["qalc", "-t", expression];
            mathProc.running = true;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim();
                const expr = launcher.mathExpression(launcher.query).trim();
                launcher.calcResult = out.length > 0 && out !== expr ? out : "";
            }
        }
    }

    property var results: {
        if (launcher.clipMode) {
            const q = launcher.query.slice(launcher.clipPrefix.length).trim();
            if (!q.length)
                return Cliphist.entries;

            return Cliphist.entries.map(e => ({
                        entry: e,
                        s: launcher.matchScore(Cliphist.clean(e), q)
                    })).filter(r => r.s >= 0).sort((a, b) => b.s - a.s).map(r => r.entry);
        }

        if (!launcher.query.length)
            return launcher.apps;

        return launcher.apps.map(e => ({
                    entry: e,
                    s: launcher.matchScore(e.name, launcher.query)
                })).filter(r => r.s >= 0).sort((a, b) => b.s - a.s).map(r => r.entry);
    }


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

    function activate(item) {
        if (launcher.hasCalc) {
            searchField.text = launcher.calcResult;
            return;
        }
        if (!item)
            return;

        if (launcher.clipMode)
            Cliphist.paste(item);

        else
            item.execute();

        launcher.open = false
    }

    function reset() {
        query = "";
        selected = 0;
        searchField.text = "";
    }

    function show(prefill, forcedScreen) {
        launcher.targetScreen = forcedScreen ?? (Array.from(Quickshell.screens).find(s => s.name === (Hyprland.focusedMonitor?.name ?? "")) ?? Quickshell.screens[0]);

        reset();


        if (prefill !== undefined)
            searchField.text = prefill;
        launcher.open = true;
        Qt.callLater(() => searchField.forceActiveFocus());
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

    Connections {
        target: ClipboardState

         function onOpenRequested(targetScreen) {
            launcher.show(launcher.clipPrefix, targetScreen);
        }

        function onCloseRequested() {
            launcher.open = false;
        }
    }

     Binding {
        target: ClipboardState
        property: "active"
        value: launcher.open && launcher.clipMode
    }

    Binding {
        target: ClipboardState
        property: "screen"
        value: launcher.targetScreen
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launcher.open = false
    }

    Rectangle {
        id: card

        width: 560
        height: {
            const chrome = launcher.rowHeight + 24;
            if (resultsList.count === 0)
                return launcher.query.length ? chrome + 52 : chrome;
            return chrome + Math.min(resultsList.count, launcher.maxVisibleRows) * launcher.rowHeight;
        }
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2

        radius: Appearance.cardRadius
        color: Appearance.cardColor
        border.width: 1
        border.color: Appearance.cardBorder

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
            anchors.leftMargin: Appearance.cardRadius
            anchors.rightMargin: Appearance.cardRadius
            height: 1
            color: Appearance.cardSheen
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: launcher.rowHeight
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                radius: height / 2
                color: Appearance.fieldColor
                border.width: searchField.activeFocus ? 1 : 0
                border.color: Appearance.fieldBorderFocus

                Behavior on border.color {
                    ColorAnimation {
                        duration: Appearance.animFast
                    }
                }

                RowLayout {
                    id: searchRow
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: 10

                    MaterialSymbol {
                        icon: launcher.clipMode ? "content_paste" : "search"
                        color: launcher.query.length ? Appearance.accent : Appearance.outline
                        iconSize: 19

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animFast
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            text: launcher.clipMode ? "Search clipboard…" : "Search apps…"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            color: Appearance.outline
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
                            selectionColor: Appearance.accentContainer
                            selectedTextColor: Appearance.onAccentContainer
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
                            Keys.onReturnPressed: launcher.activate(launcher.results[launcher.selected])
                            Keys.onEnterPressed: launcher.activate(launcher.results[launcher.selected])
                        }
                    }
                    Rectangle {
                        id:resultBox
                        visible: launcher.hasCalc
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 28
                        Layout.preferredWidth: Math.min(200, resultText.implicitWidth + 24)
                        radius: Appearance.pillRadius
                        color: Appearance.accent

                        Text {
                            id: resultText
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: launcher.calcResult
                            color: Appearance.onAccent
                            font.family: Appearance.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: resultsList
                    anchors.fill: parent
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
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            anchors.topMargin: 2
                            anchors.bottomMargin: 2
                            radius: 12
                            color: row.isSelected ? Appearance.rowSelected : hover.hovered ? Appearance.rowHover : Appearance.rowIdle

                            Behavior on color {
                                ColorAnimation {
                                    duration: Appearance.animFast
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: row.isSelected ? parent.height * 0.5 : 0
                                radius: 2
                                color: Appearance.accent

                                Behavior on height {
                                    NumberAnimation {
                                        duration: Appearance.animFast
                                        easing.type: Appearance.easeOutCubic
                                    }
                                }
                            }
                        }

                        HoverHandler {
                            id: hover
                            onHoveredChanged: if (hovered)
                                launcher.selected = row.index
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 18
                            spacing: 12

                            IconImage {
                                visible: !launcher.clipMode
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                source: launcher.clipMode ? "" : Quickshell.iconPath(row.modelData.icon, "image-missing")
                            }

                            MaterialSymbol {
                                visible: launcher.clipMode
                                icon: "content_copy"
                                iconSize: 17
                                color: row.isSelected ? Appearance.accent : Appearance.subtext

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Appearance.animFast
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: launcher.clipMode ? Cliphist.clean(row.modelData).replace(/\s+/g, " ") : row.modelData.name
                                color: row.isSelected ? Appearance.accent : Appearance.fg
                                font.weight: row.isSelected ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                font.family: Appearance.fontFamily
                                font.pixelSize: 14

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
                            onClicked: launcher.activate(row.modelData)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: resultsList.count === 0
                    text: "No results"
                    color: Appearance.subtext
                    font.family: Appearance.fontFamily
                    font.pixelSize: 13
                }
            }
        }
    }
}
