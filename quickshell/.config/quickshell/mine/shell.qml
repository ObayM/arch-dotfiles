//@ pragma UseQApplication

import Quickshell
import qs.modules
import Quickshell.Io


ShellRoot {
    IpcHandler {
        target: "hackatime"
        function authenticate(code: string) {
            console.log("Received Hackatime code:", code)
        }
    }
    Bar {}
}
