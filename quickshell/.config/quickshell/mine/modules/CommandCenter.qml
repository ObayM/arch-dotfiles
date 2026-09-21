pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.modules.services
import qs.modules.calendar
import qs.config

Item {
    id: root

    required property bool active

    readonly property real pillTop: (Appearance.barHeight - Appearance.islandHeight) / 2
    readonly property real pillCy: Appearance.barHeight / 2
    readonly property real islandBottom: pillTop + Appearance.islandHeight

    readonly property real cardPadding: 12
    readonly property real cardW: 320
    readonly property real cardH: calendar.implicitHeight + cardPadding * 2
    readonly property real cardCy: islandBottom + cardH / 2
    readonly property real cardLeft: width / 2 - cardW / 2

    readonly property real pillW: Math.max(Appearance.pillRadius * 2, CommandCenterState.pillWidth)

    property real progress: active ? 1 : 0

    readonly property bool rendering: progress > 0

    readonly property real boxHw: pillW / 2 + (cardW - pillW) / 2 * progress
    readonly property real boxHh: Appearance.islandHeight / 2 + (cardH - Appearance.islandHeight) / 2 * progress
    readonly property real boxCy: pillCy + (cardCy - pillCy) * progress
    readonly property real boxR: Appearance.pillRadius + (Appearance.cardRadius - Appearance.pillRadius) * progress

    readonly property real blobK: {
        const t = Math.max(0, Math.min(1, (progress - 0.2) / 0.8));
        return Appearance.blobSmoothing * t * t * (3 - 2 * t);
    }

    readonly property vector4d fillVec: Qt.vector4d(Appearance.islandColor.r, Appearance.islandColor.g, Appearance.islandColor.b, Appearance.islandColor.a)
    readonly property vector4d lineVec: Qt.vector4d(Appearance.hairline.r, Appearance.hairline.g, Appearance.hairline.b, Appearance.hairline.a)

    Behavior on progress {
        NumberAnimation {
            duration: Appearance.animMed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.curveEmphasized
        }
    }

    RectangularShadow {
        x: root.width / 2 - root.boxHw
        y: root.boxCy - root.boxHh
        width: root.boxHw * 2
        height: root.boxHh * 2
        radius: root.boxR
        blur: Appearance.panelShadowBlur
        spread: Appearance.panelShadowSpread
        offset: Qt.vector2d(0, Appearance.panelShadowY)
        color: Appearance.shadowColor
        opacity: root.progress
        visible: root.rendering
        cached: false
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.rendering
        blending: true
        fragmentShader: Qt.resolvedUrl("../shaders/blob.frag.qsb")

        property vector2d res: Qt.vector2d(width, height)
        property vector4d pill: Qt.vector4d(root.width / 2, root.pillCy, root.pillW / 2, Appearance.islandHeight / 2)
        property vector4d card: Qt.vector4d(root.width / 2, root.boxCy, root.boxHw, root.boxHh)
        property vector4d fillColour: root.fillVec
        property vector4d lineColour: root.lineVec
        property real pillR: Appearance.pillRadius
        property real cardR: root.boxR
        property real k: root.blobK
    }

    Item {
        x: root.cardLeft
        y: root.islandBottom
        width: root.cardW
        height: root.cardH

        visible: root.rendering
        opacity: root.active ? 1 : 0

        HoverHandler {
            enabled: root.rendering
            onHoveredChanged: CommandCenterState.panelHovered = hovered
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animFast
            }
        }

        CalendarWidget {
            id: calendar

            x: root.cardPadding
            y: root.cardPadding
            width: root.cardW - root.cardPadding * 2

            onMonthShiftChanged: if (monthShift !== 0) CommandCenterState.pinned = true
        }
    }
}
