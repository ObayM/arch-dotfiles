pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color bg: Colors.bg
    readonly property color surface: Colors.surface
    readonly property color surfaceLow: Colors.surfaceLow
    readonly property color surfaceHigh: Colors.surfaceHigh
    readonly property color fg: Colors.fg
    readonly property color accent: Colors.accent
    readonly property color accentContainer: Colors.accentContainer
    readonly property color onAccentContainer: Colors.onAccentContainer
    readonly property color outlineVariant: Colors.outlineVariant

    readonly property color islandColor: Qt.rgba(surface.r, surface.g, surface.b, surfaceOpacity)

    readonly property string fontFamily: "FiraCode Nerd Font"

    readonly property int barHeight: 38
    readonly property int islandHeight: 30
    readonly property int margin: 4
    readonly property int radius: 8
    readonly property int pillRadius: 10

    readonly property real surfaceOpacity: 0.82
    readonly property color hairline: Qt.rgba(fg.r, fg.g, fg.b, 0.08)

    readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.35)
    readonly property int shadowBlur: 24
    readonly property int shadowOffsetY: 5

    readonly property int animFast: 150
    readonly property int animMed: 220
    readonly property int animSlow: 320
    readonly property int easeOutCubic: Easing.OutCubic
}
