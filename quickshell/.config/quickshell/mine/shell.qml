//@ pragma UseQApplication

import Quickshell
import qs.modules
import Quickshell.Io
import QtQuick

ShellRoot {

    id: root

    property string token: ""

    function loadToken() {
        loadApiKeyProcess.running = true
    }

    Process {
        id: loadApiKeyProcess

        command: [
            "python3",
            "-c",
            "import configparser, os; c = configparser.ConfigParser(); c.read(os.path.expanduser('~/.wakatime.cfg')); print(c.get('settings', 'api_key', fallback=''))"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.token = this.text.trim()
            }
        }
        onExited: function(exitCode){
            if(exitCode !== 0){
                root.token = ''
                console.log('no Hackatime API key found in ~/.wakatime.cfg')
            }
        }
    }

    Timer {
        interval: 0
        running: true
        repeat: false
        onTriggered: {
            root.loadToken()
        }
    }

    Bar {
        token: root.token
    }
    Clipboard{
        id:clipboard
    }
    IpcHandler {
        target: 'clipboard'
        function toggle(): void {
            if(clipboard.opened){
                clipboard.close()
            }else{
                clipboard.open()
            }
        }
    }
    Launcher {}
}
