import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

PanelWindow {
    id:root
    property bool opened: false
    property var clipboardItems: []
    width:300
    height: 400
    visible: opened
    anchors {
        right:true
    }
    function open() {
        opened = true
    }
    function close(){
        opened = false
    }
}