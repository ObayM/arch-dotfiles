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
    readonly property color islandHover: Qt.rgba(surfaceHigh.r, surfaceHigh.g, surfaceHigh.b, Math.min(1, surfaceOpacity + 0.05))

    readonly property string fontFamily: "FiraCode Nerd Font"

    readonly property int barHeight: 38
    readonly property int islandHeight: 30
    readonly property int margin: 4
    readonly property int radius: 8
    readonly property int pillRadius: 15

    readonly property int cardRadius: 22
    readonly property int notchRadius: 14

    readonly property int shadowMargin: 20
    readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.40)

    readonly property real pillShadowBlur: 10
    readonly property real pillShadowSpread: 0
    readonly property real pillShadowY: 2
    
    readonly property real panelShadowBlur: 24
    readonly property real panelShadowSpread: 2
    readonly property real panelShadowY: 6

    readonly property real blobSmoothing: 20


    readonly property real surfaceOpacity: 0.88
    readonly property color hairline: Qt.rgba(fg.r, fg.g, fg.b, 0.10)

    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 12
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeDisplay: 30

    readonly property int spacingS: 6
    readonly property int spacingM: 10
    readonly property int spacingL: 16
    readonly property int cardPadding: 16

    readonly property int shadowBlur: 24
    readonly property int shadowOffsetY: 5

    readonly property int animFast: 150
    readonly property int animMed: 220
    readonly property int animSlow: 320
    readonly property int easeOutCubic: Easing.OutCubic

    readonly property list<real> curveEmphasized: [0.05, 0, 2/15, 0.06, 1/6, 0.4, 5/24, 0.82, 0.25, 1, 1, 1]
    readonly property list<real> curveExpressive: [0.34, 0.80, 0.34, 1.00, 1, 1]
    readonly property list<real> curveSpatial:    [0.38, 1.21, 0.22, 1.00, 1, 1]

    readonly property var wallpaperTransitions: [
        {
            name: "ripple",
            duration: 1100
        },
        {
            name: "dissolve",
            duration: 900
        },
        {
            name: "glitch",
            duration: 650
        }
    ]
}
