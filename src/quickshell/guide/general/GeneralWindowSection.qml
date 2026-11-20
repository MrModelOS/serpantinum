import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"
import "../../reusables"
import "../../reusables/guide"

SettingsBlob {
    id: section
    required property var tab
    readonly property var rootObj: tab.rootObj

    readonly property bool isHyprland: typeof Compositor !== "undefined" && Compositor.name === "hyprland"
    readonly property string scriptsDir: {
        if (typeof Caching !== "undefined" && Caching.serpantinumDir) return Caching.serpantinumDir;
        return Quickshell.env("HOME") + "/.local/share/serpantinum/src";
    }

    property var defaultWindowLayout: ({ "mode": "mixed" })
    property string layoutMode: "mixed"
    property bool layoutReconciled: false

    readonly property var layoutOptions: ["tiling", "mixed", "floating"]

    visible: isHyprland

    function syncSettings() {
        let settings = (typeof Config !== "undefined" && Config.getSetting)
            ? Config.getSetting("windowLayout", section.defaultWindowLayout)
            : section.defaultWindowLayout;
        let mode = settings && settings.mode ? settings.mode : "mixed";
        if (mode !== "tiling" && mode !== "mixed" && mode !== "floating") mode = "mixed";
        section.layoutMode = mode;
    }

    function setLayoutMode(mode) {
        if (mode !== "tiling" && mode !== "mixed" && mode !== "floating") return;
        section.layoutMode = mode;
        section.layoutReconciled = true;
        if (typeof Config !== "undefined" && Config.setSetting) {
            Config.setSetting("windowLayout", { "mode": mode });
        }
        layoutProcess.command = ["bash", section.scriptsDir + "/scripts/layout.sh", mode];
        layoutProcess.running = true;
    }

    function modeTitle(mode) {
        if (mode === "tiling") return I18n.t("guide.general.layout.tiling", "Tiling");
        if (mode === "floating") return I18n.t("guide.general.layout.floating", "Floating");
        return I18n.t("guide.general.layout.mixed", "Mixed");
    }

    function modeDescription(mode) {
        if (mode === "tiling") return I18n.t("guide.general.layout.tiling_desc", "Every window tiles automatically; floating is disabled.");
        if (mode === "floating") return I18n.t("guide.general.layout.floating_desc", "Every window floats freely and opens centered.");
        return I18n.t("guide.general.layout.mixed_desc", "Windows float and snap to screen edges and each other, while shortcuts keep working.");
    }

    onVisibleChanged: {
        if (visible) {
            syncSettings();
            variablesView.reload();
        }
    }

    Component.onCompleted: {
        syncSettings();
        variablesView.reload();
    }

    Connections {
        target: typeof Config !== "undefined" ? Config : null
        function onSettingsLoaded() {
            section.syncSettings();
        }
    }

    Process {
        id: layoutProcess
        running: false
    }

    FileView {
        id: variablesView
        path: (typeof Config !== "undefined" ? Config.homeDir : Quickshell.env("HOME")) + "/.config/hypr/config/variables.lua"
        watchChanges: false

        onLoaded: {
            if (!section.isHyprland || section.layoutReconciled) return;
            section.layoutReconciled = true;
            let raw = typeof text === "function" ? text() : text;
            let match = String(raw || "").match(/layoutMode\s*=\s*["']([^"']+)["']/);
            if (match && match[1] !== section.layoutMode) {
                section.setLayoutMode(section.layoutMode);
            }
        }
    }

    SettingsRow {
        rootObj: section.tab.rootObj
        icon: "󰕰"
        title: I18n.t("guide.general.layout.title", "Window layout")
        description: section.modeDescription(section.layoutMode)

        Dropdown {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            implicitWidth: rootObj.s(180)
            implicitHeight: rootObj.s(32)
            options: [
                section.modeTitle("tiling"),
                section.modeTitle("mixed"),
                section.modeTitle("floating")
            ]
            currentIndex: Math.max(0, section.layoutOptions.indexOf(section.layoutMode))
            accentColor: ThemeBackend.mauve
            baseColor: ThemeBackend.surface0
            hoverColor: ThemeBackend.surface1
            dropdownColor: ThemeBackend.surface0
            borderColor: Qt.alpha(ThemeBackend.surface2, 0.6)
            textColor: ThemeBackend.text
            activeTextColor: ThemeBackend.crust
            fontPixelSize: rootObj.s(11)
            onValueChanged: function(index, value) {
                let mode = section.layoutOptions[index];
                if (mode === section.layoutMode) return;
                section.setLayoutMode(mode);
            }
        }
    }

    SettingsRow {
        rootObj: section.tab.rootObj
        icon: "󰁔"
        title: I18n.t("guide.general.layout.workspace_drag.title", "Move windows between workspaces")
        description: I18n.t("guide.general.layout.workspace_drag.desc", "In mixed and floating modes, drag a window to the left or right screen edge and release it to send it to the previous or next workspace.")
        visible: section.layoutMode !== "tiling"
        searchable: false
    }
}
