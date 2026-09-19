pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color bg: Colors.bg
    readonly property color surface: Colors.surface
    readonly property color fg: Colors.fg
    readonly property color accent: Colors.accent

    readonly property string fontFamily: "FiraCode Nerd Font"

    readonly property int barHeight: 38
    readonly property int margin: 10
    readonly property int radius: 18
    readonly property int pillRadius: 999

    readonly property real surfaceOpacity: 0.68
    readonly property color hairline: Qt.rgba(fg.r, fg.g, fg.b, 0.08)

    readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.45)
    readonly property int shadowBlur: 32
    readonly property int shadowOffsetY: 8

    readonly property int animFast: 150
    readonly property int animMed: 220
    readonly property int animSlow: 320
    readonly property int easeOutCubic: Easing.OutCubic
}
