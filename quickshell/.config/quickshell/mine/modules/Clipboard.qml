import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import qs.config

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
                    return {
                        id: parts[0],
                        text: parts[1],
                        whole: line
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

    Process {
        id: copyProcess

        command: ["wl-copy" , "     "]
        running: false
    }
    Process {
        id: typeClipboardSelectionProcess

        command: ["wtype", "-M", "ctrl" ,"-k" ,"v" , "     "]
        running: false
        
    }
    Process {
        id:decoderProcess
        running:false
        stdout: StdioCollector {
            onStreamFinished:{
                copyProcess.command = ['wl-copy', text]
                typeClipboardSelectionProcess.command = ["wtype", "-M", "ctrl" ,"v", "-m", 'ctrl']
                copyProcess.running = true
                typeClipboardSelectionProcess.running = true
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        color:  Qt.rgba(Appearance.bg.r, Appearance.bg.g, Appearance.bg.b, 1.0)
        ListView {
            anchors.fill: parent
            anchors.margins: 15
            model: root.clipboardItems
            spacing:15
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height:70
                radius:3
                color:Qt.rgba(Appearance.bg.r, Appearance.bg.g, Appearance.bg.b, 0.70)
                border.width:1
                border.color: Appearance.onAccentContainer
                
                Text {
                    anchors.fill: parent
                    anchors.margins: 5
                    color: Appearance.fg
                    verticalAlignment: Text.verticalAlignment
                    horizontalAlignment: Text.horizontalAlignment
                    text: modelData.text
                    wrapMode: Text.Wrap
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: function (){
                        decoderProcess.command = ["cliphist", "decode", String(modelData.id)]
                        decoderProcess.running = true

                    }
                }
            }
        }
    }
}