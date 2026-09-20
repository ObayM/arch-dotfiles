pragma Singleton
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property alias list: server.trackedNotifications

    NotificationServer {
        id: server
        actionsSupported: true
        onNotification: notif => notif.tracked = true
    }
}