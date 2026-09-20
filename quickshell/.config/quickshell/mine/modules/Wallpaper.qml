pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.services
import qs.config

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        readonly property string target: Wallpapers.current
        property string shown: ""
        property bool swapping: false
        property real progress: 0
        property vector2d origin: Qt.vector2d(0.5, 0.5)

    
        function resolveOrigin() {
            const s = win.screen;
            if (!s || s.width <= 0 || s.height <= 0)
                return Qt.vector2d(0.5, 0.5);

            const g = Wallpapers.originGlobal;
            const nx = (g.x - s.x) / s.width;
            const ny = (g.y - s.y) / s.height;

            return Qt.vector2d(Math.max(-0.5, Math.min(1.5, nx)), Math.max(-0.5, Math.min(1.5, ny)));
        }
        screen: win.modelData
        color: "black"

        WlrLayershell.namespace: "quickshell:wallpaper"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore       
        
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {}

        onTargetChanged: if (!win.shown.length)
            win.shown = win.target

        Image {
            id: fromImage

            anchors.fill: parent
            source: win.shown.length ? "file://" + win.shown : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            sourceSize.width: win.screen.width
            sourceSize.height: win.screen.height

            onStatusChanged: {
                if (status === Image.Ready && win.swapping) {
                    win.swapping = false;
                    win.progress = 0;
                }
            }
        }

        Image {
            id: toImage

            anchors.fill: parent
            source: win.target.length ? "file://" + win.target : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            sourceSize.width: win.screen.width
            sourceSize.height: win.screen.height

            onStatusChanged: {
                if (status === Image.Ready && win.shown.length && win.target !== win.shown)
                    transition.restart();
            }
        }

        ShaderEffectSource {
            id: fromSource
            anchors.fill: parent
            sourceItem: fromImage
            hideSource: true
            live: true
        }

        ShaderEffectSource {
            id: toSource
            anchors.fill: parent
            sourceItem: toImage
            hideSource: true
            live: true
        }

        
        ShaderEffect {
            anchors.fill: parent
            blending: false

            property variant fromTex: fromSource
            property variant toTex: toSource
            property real progress: win.progress
            property real aspect: width / Math.max(height, 1)
            property vector2d origin: win.origin
            property color accent: Appearance.accent

            fragmentShader: Qt.resolvedUrl("../shaders/ripple.frag.qsb")
        }
        
        NumberAnimation {
            id: transition

            target: win
            property: "progress"
            from: 0
            to: 1
            duration: 1100
            easing.type: Easing.Linear

            onStarted: win.origin = win.resolveOrigin()
            onFinished: {
                win.swapping = true;
                win.shown = win.target;
            }
        }
    }
}