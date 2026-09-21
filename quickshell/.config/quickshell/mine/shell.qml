//@ pragma UseQApplication

import Quickshell
import qs.modules
import Quickshell.Io
import QtQuick
import "./modules/calendar"

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

    IpcHandler {
        target: 'clipboard'

        function toggle(): void {
            if (launcher.open && launcher.clipMode)
                launcher.open = false;
            else
                launcher.show(launcher.clipPrefix);
        }
    }
    
    Launcher {
        id: launcher
    }

    Notifications {}
    Osd {}
    Screenshot {}

    CalendarWidget {}
    Wallpaper {}

    WallpaperPicker {
        id: wallpaperPicker
    }

    IpcHandler {
        target: 'wallpaper'

        function toggle(): void {
            if (wallpaperPicker.open)
                wallpaperPicker.close();

            else
                wallpaperPicker.show();
        }

        function random(): void {
            Wallpapers.random(Wallpapers.dir)
        }
    }
}
