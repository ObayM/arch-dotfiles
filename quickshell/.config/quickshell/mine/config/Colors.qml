pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property color bg: "#1e1e2e"
    property color surface: "#313244"
    property color fg: "#cdd6f4"
    property color accent: "#89b4fa"

    function mix(a: color, b: color, t: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    property color surfaceLow: mix(root.bg, root.surface, 0.5)
    property color surfaceHigh: mix(root.surface, root.fg, 0.06)
    property color surfaceHighest: mix(root.surface, root.fg, 0.12)
    property color subtext: mix(root.fg, root.surface, 0.35)
    property color outline: mix(root.surface, root.fg, 0.45)
    property color accentContainer: mix(root.bg, root.accent, 0.35)
    property color onAccentContainer: mix(root.fg, root.accent, 0.25)
    property color onAccent: mix(root.bg, root.accent, 0.12)
    property color outlineVariant: mix(root.surface, root.fg, 0.14)

    function apply(content: string): void {
        if (!content.length)
            return;
        try {
            const c = JSON.parse(content);
            if (c.bg)
                root.bg = c.bg;
            if (c.surface)
                root.surface = c.surface;
            if (c.fg)
                root.fg = c.fg;
            if (c.accent)
                root.accent = c.accent;
            root.surfaceLow = c.surfaceLow ?? root.mix(root.bg, root.surface, 0.5);
            root.surfaceHigh = c.surfaceHigh ?? root.mix(root.surface, root.fg, 0.06);
            root.surfaceHighest = c.surfaceHighest ?? root.mix(root.surface, root.fg, 0.12);
            root.subtext = c.subtext ?? root.mix(root.fg, root.surface, 0.35);
            root.outline = c.outline ?? root.mix(root.surface, root.fg, 0.45);

            root.accentContainer = c.accentContainer ?? root.mix(root.bg, root.accent, 0.35);

            root.onAccentContainer = c.onAccentContainer ?? root.mix(root.fg, root.accent, 0.25);
            root.onAccent = c.onAccent ?? root.mix(root.bg, root.accent, 0.12);
            root.outlineVariant = c.outlineVariant ?? root.mix(root.surface, root.fg, 0.14);
        } catch (e) {
            console.warn("Colors: failed to parse matugen output:", e);
        }
    }

    FileView {
        id: file

        path: Quickshell.env("HOME") + "/.local/state/matugen/colors.json"
        watchChanges: true

        onFileChanged: {
            reload();
            rereadTimer.restart();
        }

        onLoadedChanged: root.apply(file.text())
    }

    Timer {
        id: rereadTimer
        interval: 60
        onTriggered: root.apply(file.text())
    }
}
