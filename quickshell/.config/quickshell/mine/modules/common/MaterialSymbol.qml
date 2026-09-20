import QtQuick

Text {
    id: root

    property alias icon: root.text
    property real iconSize: 16

    text: icon
    font.family: "Material Symbols Rounded"
    font.pixelSize: iconSize
    renderType: Text.NativeRendering
    
}