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
        } catch (e) {
            console.warn("Colors: failed to parse matugen output:", e);
        }
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/matugen/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadedChanged: root.apply(text())
    }
}
