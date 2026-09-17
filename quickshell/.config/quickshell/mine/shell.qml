//@ pragma UseQApplication


import Quickshell
import qs.modules
import Quickshell.Io
import QtQuick

ShellRoot {
    id:root

    property string token: ""
    property string tokenToSave: ""

    function saveToken(value){
        tokenToSave = value
        saveProcess.running = true
    }
    function loadToken() {
        loadProcess.running = true
    }

    Process {
        id: saveProcess

        environment: ({
            TOKEN: root.tokenToSave
        })

        command: [
            "sh",
            "-c",
            "printf '%s' \"$TOKEN\" | secret-tool store --label='Quickshell Authentication Token' service quickshell-auth"
        ]

        onExited: function(exitCode){
            if(exitCode === 0){
                root.token = root.tokenToSave
            }else{
                console.log('Failed to save auth token')
            }
            root.tokenToSave = ""
        }
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
        onExited: function(exitCode){
            if(exitCode !== 0){
                root.token = ''
                console.log('no auth token available')
            }
        }
    }
    
    Timer {
        interval:0
        running:true
        repeat:false 
        onTriggered: {
            root.loadToken() 
        }
    }

    IpcHandler {

        target: "hackatime"
        function authenticate(code: string) {
            console.log("Received Hackatime code:", code)
            var xhr = new XMLHttpRequest()

            xhr.open('POST','https://hyprland-rice-6524540f31b7.herokuapp.com/auth/exchange')
            xhr.setRequestHeader("Content-Type","application/x-www-form-urlencoded")
            xhr.onreadystatechange = function () {
                if (xhr.readyState !== XMLHttpRequest.DONE)return
                console.log(xhr.status)
                console.log(xhr.responseText)
                console.log((JSON.parse(xhr.responseText)).access_token)

                root.saveToken((JSON.parse(xhr.responseText)).access_token)
            }
            xhr.send("code=" + encodeURIComponent(code))
        }
    }
    Bar {}
}
