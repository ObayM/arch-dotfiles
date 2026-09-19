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

    Process {
        id:listProcess

        command: ['cliphist', 'list', "-fields" , "id,preview"]
        stdout: StdioCollector {
            onStreamFinished:{ 
                var output = text.trim()
                if(output === ""){
                    root.clipboardItems = []
                    return
                }
                var lines = output.trim().split('\n')
                root.clipboardItems = lines.map(function(line) {
                    var parts = line.split("\t")
                    console.log(parts[1])
                    return {
                        id: parts[0],
                        text: parts[1]
                    }
                })
            }
        }
    }

    anchors {
        right:true
    }
    function open() {
        opened = true
        listProcess.running = true
    }
    function close(){
        opened = false
    }

    Rectangle {
        anchors.fill: parent
        ListView {
            anchors.fill: parent
            anchors.margins: 20
            model: root.clipboardItems
            spacing:8
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height:50
                radius:8
                Text {
                    anchors.fill: parent
                    text: modelData.text
                    color: 'black'
                }
            }
        }
    }
}