  import QtQuick
  import qs.config

  Rectangle {
      id: root

      required property var model
      required property int focusedMonth

      readonly property bool today: model.today
      readonly property bool outside: model.month !== focusedMonth

      radius: height / 2

      color: today ? Appearance.accent : hover.hovered ? Appearance.surfaceHigh : "transparent"

      Behavior on color {
          ColorAnimation {
              duration: Appearance.animFast
          }
      }

      HoverHandler {
          id: hover
      }

      Text {
          anchors.centerIn: parent

          text: root.model.day

          font.family: Appearance.fontFamily
          font.pixelSize: Appearance.fontSizeNormal
          font.weight: root.today ? Font.DemiBold : Font.Normal

          color: root.today ? Appearance.bg : root.outside ? Qt.rgba(Appearance.fg.r, Appearance.fg.g, Appearance.fg.b, 0.32) : Appearance.fg
      }
  }
