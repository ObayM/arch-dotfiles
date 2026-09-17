//@ pragma UseQApplication


import Quickshell
import qs.modules
import Quickshell.Io


ShellRoot {
    id:root

    property string token: ""
    function saveToken(value){
        saveProcess.enviroment = ({
            TOKEN:value
        })
        saveProcess.running = true
    }
    function loadToken() {
        loadProcess.running = true
    }

    Process {
        id: saveProcess

        command: [
            "sh",
            "-c",
            "printf '%s' \"$TOKEN\" | secret-tool store --label='Quickshell Authentication Token' service quickshell-auth"
        ]
    }
    Process {
        id: loadProcess

        command: [
            "secret-tool",
            "lookup",
            "service",
            "quickshell-auth"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.token = this.text.trim()
            }
        }
    }
    Component.onCompleted: {
        loadToken()
    }

    IpcHandler {

        target: "hackatime"
        function authenticate(code: string) {
            console.log("Received Hackatime code:", code)
        }
    }
    Bar {}
}
