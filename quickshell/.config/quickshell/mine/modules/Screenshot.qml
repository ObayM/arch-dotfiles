pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.services

import "./screenshot"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: Loader {
            id: selectorLoader

            required property var modelData

            active: ScreenshotState.open

            sourceComponent: RegionSelection {
                targetScreen: selectorLoader.modelData
            }
        }
    }

    IpcHandler {
        target: "screenshot"

        function region(): void {
            ScreenshotState.region(ScreenshotState.Action.Copy);
        }

        function edit(): void {
            ScreenshotState.region(ScreenshotState.Action.Edit);
        }

        function screen(): void {
            ScreenshotState.fullScreen(Hyprland.focusedMonitor?.name ?? "");
        }

        function close(): void {
            ScreenshotState.close();
        }
    }
}
